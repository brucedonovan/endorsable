# Endorsable

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.13-blue.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-000000.svg)](https://getfoundry.sh/)

A small inheritable Solidity mixin for tracking on-chain endorsements.

`Endorsable` is a request-then-endorse handshake: the owner (or, for state-level items, the state owner) asks a specific address for an endorsement; that address can grant or later revoke it. Comments travel in events only — they are not stored on-chain.

This is a utility, not a reputation protocol. It does not enumerate endorsers, weight them, expire them, or attach structured metadata that other contracts can read.

## Overview

Two complementary contracts:

| Contract | Purpose | Who controls requests / removals |
|----------|---------|----------------------------------|
| **`Endorsable.sol`** | One endorsement status per address, for the whole contract | Contract owner (`Ownable`) |
| **`EndorsableState.sol`** | Independent statuses per `(owner, identifier)` plus the contract-level mapping | The **state owner** (`msg.sender`), not the contract owner |

`Endorsable` implements `IEndorsable`. `EndorsableState` implements `IEndorsableState` and inherits `Endorsable`. The shared `State` enum lives on `IEndorsable`.

## Endorsement lifecycle

Both layers use the same five states:

```
UNASSIGNED (0) → REQUESTED (1) → ENDORSED (2)
                      ↓              ↓
                 REMOVED (4)    REVOKED (3)
```

- **`UNASSIGNED`**: No interaction yet.
- **`REQUESTED`**: A request is outstanding.
- **`ENDORSED`**: The requested address granted the endorsement.
- **`REVOKED`**: The endorser withdrew it.
- **`REMOVED`**: The owner (contract owner, or state owner) cancelled a request or an active endorsement.

Rules that apply at both layers:

- Endorse only from `REQUESTED`.
- Revoke only from `ENDORSED`.
- Remove only from `REQUESTED` or `ENDORSED` (not from `REVOKED` / `UNASSIGNED`).
- A new request is allowed from `UNASSIGNED`, `REVOKED`, or `REMOVED`. It is rejected if the status is already `REQUESTED` or `ENDORSED`.

## When this is a fit

Useful when a contract wants a few **known** addresses (auditors, partners, clients) to opt in to an on-chain endorsement, and a parent contract or an indexer will decide what those statuses mean.

Not a substitute for Ethereum Attestation Service, soulbound tokens, or a scoring system. There is no on-chain list of endorsers: any “count” or “score” has to be given a candidate address list from off-chain.

## Installation

Foundry:

```bash
forge install https://github.com/brucedonovan/endorsable.git
```

There is no npm package.

## Quick start

### Contract-level

```solidity
pragma solidity ^0.8.13;

import "endorsable/src/Endorsable.sol";

contract MyContract is Endorsable {
    constructor(address[] memory _initialRequests) Endorsable(_initialRequests) {}
}
```

Only the owner can `requestEndorsement` / `removeEndorsement`. The requested address calls `endorse` / `revokeEndorsement`.

### State-level

```solidity
pragma solidity ^0.8.13;

import "endorsable/src/EndorsableState.sol";

contract MyProjectPortfolio is EndorsableState {
    constructor(address[] memory _initialRequests) EndorsableState(_initialRequests) {}

    function createProject(string calldata projectId, address[] calldata endorsers) external {
        for (uint256 i = 0; i < endorsers.length; i++) {
            // Keys the state to msg.sender, not to the contract owner
            requestStateEndorsement(projectId, endorsers[i], "Please review this project");
        }
    }
}
```

State functions are **not** `onlyOwner`. Each address owns the identifiers it requests under: `stateId = keccak256(abi.encodePacked(msg.sender, identifier))`. Calling `removeStateEndorsement` as someone else removes a status on *their* identifier, not yours.

## API

### `Endorsable`

```solidity
function requestEndorsement(address addr, string calldata comment) external; // onlyOwner
function endorse(string calldata comment) external;
function revokeEndorsement(string calldata comment) external;
function removeEndorsement(address addr, string calldata comment) external; // onlyOwner
function getEndorsementStatus(address addr) public view returns (State);
```

`addr` must be non-zero. Constructor initial requests are capped at 100 and also reject `address(0)`.

### `EndorsableState` (in addition to the above)

```solidity
function requestStateEndorsement(string calldata identifier, address addr, string calldata comment) public;
function endorseState(address stateOwner, string calldata identifier, string calldata comment) public;
function revokeStateEndorsement(address stateOwner, string calldata identifier, string calldata comment) public;
function removeStateEndorsement(string calldata identifier, address addr, string calldata comment) external;
function getStateEndorsementStatus(address owner, string calldata identifier, address addr) public view returns (State);
function getStateId(address owner, string calldata identifier) public pure returns (bytes32);
```

`identifier` must be non-empty. `addr` / `stateOwner` must be non-zero. A state owner cannot request an endorsement from themselves.

Comments are included in events only (`Endorsed`, `EndorsementRequested`, `StateEndorsed`, …). They are not written to storage.

## Security notes

- Access control is OpenZeppelin `Ownable` (not two-step). Ownership transfer is a single `transferOwnership` call. Consider `Ownable2Step` in the parent contract if that matters.
- The contract owner can `removeEndorsement` any requested or active contract-level endorsement.
- There is no endorser enumeration, expiry, or on-chain comment/data hash. Do not treat `getEndorsementStatus == ENDORSED` as a complete audit or KYC signal.
- There are no external calls in these contracts, so there is no reentrancy surface in the mixin itself. Parent contracts that add callbacks should still reason about reentrancy on their own code.

## Examples

`examples/` has two illustrative contracts (`ReputableBusiness`, `ProjectPortfolio`) and tests. Reputation scores in those examples are **demonstrations** — they take a caller-supplied address list and apply arbitrary weights. See [examples/README.md](./examples/README.md).

## Development

```bash
git clone https://github.com/brucedonovan/endorsable.git
cd endorsable
forge install
forge test
forge test -vvv
forge build
```

Example tests:

```bash
cd examples && forge test
```

## Changelog

### Unreleased

- `Endorsable` implements `IEndorsable`; `EndorsableState` implements `IEndorsableState`. `State` is defined once on the interface; both `getEndorsementStatus` and `getStateEndorsementStatus` return `State`.
- State-level removal now writes `REMOVED` (not `UNASSIGNED`), and only from `REQUESTED` or `ENDORSED`.
- State-level re-request is allowed from `REVOKED` and `REMOVED`, matching contract-level behaviour.
- Tests updated for zero-address and empty-identifier validation.
- README rewritten to match the implementation (access control, return types, no batch API, Foundry-only install).

### v0.1.0 — July 2025

- `EndorsableState.sol` for identifier-scoped endorsements alongside contract-level ones.
- Examples: `ReputableBusiness.sol` and `ProjectPortfolio.sol`.
- Comment strings on all mutating calls, emitted in events.

### v0.0.2-beta

- Comment parameter on endorsement actions.
- Basic request / endorse / revoke / remove lifecycle on `Ownable`.

## License

MIT. See [LICENSE](./LICENSE).
