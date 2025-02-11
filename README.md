# Endorsable 

## Overview

`Endorsable` provides an inheritable, structured mechanism for managing and tracking endorsements of a contract on-chain.  
By extending `Endorsable`, any parent contract can allow external addresses (EOAs or other contracts) to grant endorsements on itself.
The contract enforces a clear endorsement lifecycle of requests, approvals, revocations, and removals, making it ideal for scenarios where trust, verification, and reputation are important.

#### What’s New in v0.0.2-beta #### 
 - **Comment field**: All functions now support a comment parameter. This allows endorsers, revokers, and the contract owner to include additional contextual information in each action (This comment is only emitted with the corresponding event and not stored in the contract).

### **Potential Use Cases**

1. **Smart Contract Security Audits & Certifications**

   - Security audit firms can use `Endorsable` to issue endorsements to verified smart contracts.
   - Endorsements can be revoked if vulnerabilities are later discovered.
   - Example: A DeFi protocol integrates `Endorsable` to show which contracts have been reviewed and endorsed by auditors.

2. **DAO Governance & Reputation Systems**

   - DAOs can require endorsements from reputable smart contracts before executing governance actions.
   - Example: A DAO may only allow governance contracts that have been endorsed by its core members.

3. **Whitelisted Contract Management**

   - Used for managing a list of approved smart contracts that meet certain criteria.
   - Enables controlled interactions between verified contracts.
   - Example: A blockchain-based insurance system may only allow claims to be processed by endorsed contracts.

### **Key Benefits**

- **Standardized Endorsement Workflow**: Any subscribing contract can be endorsed by any other contracts or EOAs (only if requested).
- **Trust & Reputation Management**: Useful in permissioned environments like DAOs, audits, and credentialing.
- **Security & Transparency**: The contract is designed to be as simplea & clear as possible. It is also built with OpenZeppelin’s `Ownable` contract for uncomplicated access control. (TODO: consider `ownership2step` extension )


## Features

- **Endorsement Requests**: The contract owner can request an endorsement for another smart contract.
- **Endorsement Granting**: A requested contract/account can grant endorsement.
- **Revoking Endorsement**: Contracts can revoke their endorsement.
- **Removing Endorsements**: The owner can remove an endorsement.
- **Simplified Permission Control**: Uses OpenZeppelin’s `Ownable` for simple access control (possibly loking at using `Ownable2step` extension)
- **Comment on any action (v0.0.2-beta)**: All functions now include a comment parameter, enabling endorsers, revokers, or the contract owner to add contextual information with each action. This comment is not stored on-chain; instead, it is emitted in the corresponding event. It can be any string—for instance, a link to a supporting document on IPFS or a brief explanation for endorsing, revoking, or removing an endorsement.

## Basic Usage

To use `Endorsable`, install the package via foundry, then update the `remappings.txt` file if required:
```sh
 forge install https://github.com/brucedonovan/endorsable.git
```

or, alternatively use npm/yarn to download the package:
```sh
    npm install @brucedonovan/endorsable
```
```sh
    yarn add @brucedonovan/endorsable
```

and then inherit it in any contract that you wish to be endorsable:

```solidity
pragma solidity ^0.8.13;

import "./Endorsable.sol";

contract MyContract is Endorsable {

    // ...
    function anyFunction() external {
        // ... 
    }
}
```

## Development Installation

### Prerequisites

- **Foundry**: Install Foundry for Solidity testing.
  ```sh
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```
- **Node.js & NPM** (if using Hardhat for testing)
  ```sh
  npm install -g hardhat
  ```

### Clone the Repository

```sh
git clone https://github.com/brucedonovan/Endorsable.git
cd Endorsable
```
 
### Install Dependencies

```sh
forge install
```

## Running Tests

To test the contract, run:

```sh
forge test
```

## Smart Contract Interface

### **IEndorsable.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IEndorsable {
    /**
     * @dev Enum representing the possible endorsement states for an address:
     * 0 = UNASSIGNED, 1 = REQUESTED, 2 = ENDORSED, 3 = REVOKED, 4 = REMOVED
     */
    enum endorseState {
        UNASSIGNED,
        REQUESTED,
        ENDORSED,
        REVOKED,
        REMOVED
    }

    /// @dev Emitted when an address endorses the contract.
    event Endorsed(address indexed endorser, string comment);

    /// @dev Emitted when an address revokes its endorsement.
    event EndorsementRevoked(address indexed endorser, string comment);

    /// @dev Emitted when the contract owner requests an endorsement by a given address.
    event EndorsementRequested(address indexed addr, string comment);

    /// @dev Emitted when the contract owner removes an existing or requested endorsement.
    event EndorsementRemoved(address indexed addr, string comment);

    /**
     * @notice Contract is endorsed by the caller. This only possible if the contract owner has requested an endorsement.
     * @dev Sets the endorsement state for the caller to 'ENDORSED'. Reverts if the caller address does not have a 'REQUESTED' status.
     * @param comment Any additional information about the endorsement, included in the emitted event.
     */
    function endorse(string calldata comment) external;

    /**
     * @notice Revokes the caller’s endorsement on the contract.
     * @dev Sets status to REVOKED if previously ENDORSED. Reverts if the caller is not in the ENDORSED state.
     * @param comment Any additional information about the revoke, included in the emitted event.
     */
    function revokeEndorsement(string calldata comment) external;

    /**
     * @notice Requests an endorsement from a specific address.
     * @dev Sets the status to REQUESTED. This also resets any 'REMOVED' or 'REVOKED' status back to 'REQUESTED'. Reverts if the contract is already ENDORSED or REQUESTED.
     * Only callable by the contract owner.
     * @param addr The address whose endorsement is requested.
     * @param comment Any additional information about the request, included in the emitted event.
     */
    function requestEndorsement(address addr, string calldata comment) external;

    /**
     * @notice Removes an existing or requested endorsement for an address.
     * @dev Changes the status from ENDORSED/REQUESTED to REMOVED. Only callable by the contract owner.
     * @param addr The address whose endorsement is to be removed.
     * @param comment Any additional information about the removal, included in the emitted event.
     */
    function removeEndorsement(address addr, string calldata comment) external;

    /**
     * @notice Returns the endorsement status for the specified address.
     * @dev states: 0 = UNASSIGNED, 1 = REQUESTED, 2 = ENDORSED, 3 = REVOKED, 4 = REMOVED
     * @param addr The address whose endorsement status is being queried.
     * @return uint8 representing the address's endorsement state.
     */
    function getEndorsementStatus(address addr) external view returns (uint8);
}


```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Authors

- **Bruce Donovan / 5Swim**

## Contributing

Feel free to fork, submit issues, or open a pull request if you’d like to contribute!

## Security Considerations

- Ensure only trusted contracts inherit from `Endorsable`.
- Be cautious of reentrancy attacks and always follow best Solidity security practices.
- If used for critical endorsements, consider adding multi-signature verification.

## Contact

For inquiries, please open an issue on GitHub or contact the author directly.

---