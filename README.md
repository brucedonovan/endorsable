# Endorsable 

## Overview

The `Endorsable` solidty contract is designed to be inherited by other contracts, providing a structured mechanism for managing endorsements. It ensures that endorsements are explicitly requested, granted, revoked, or removed, making it ideal for use cases where verification, trust, and reputation tracking are essential.

### **Key Benefits**

- **Standardized Endorsement Workflow**: Any subscribing contract can be endorsed by any other contracts or EOAs (only if requested).
- **Trust & Reputation Management**: Useful in permissioned environments like DAOs, audits, and credentialing.
- **Security & Transparency**: The contract is designed to be as simple/clear as possible. It is also built with OpenZeppelin’s `Ownable` contract for uncomplicated access control.

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

## Features

- **Endorsement Requests**: The contract owner can request an endorsement for another smart contract.
- **Endorsement Granting**: A requested contract/account can grant endorsement.
- **Revoking Endorsement**: Contracts can revoke their endorsement.
- **Removing Endorsements**: The owner can remove an endorsement.
- **Permission Control**: Uses OpenZeppelin’s `Ownable` for access control.

## Basic Usage

To use `Endorsable`, install the package via foundry:
```sh
 forge install https://github.com/brucedonovan/endorsable.git
```

or alternatively use npm/yarn to download the package:
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
    constructor() Endorsable() {}

    function myFunction() external {
        // Custom logic here
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

## Smart Contract

### **Endorsable.sol**

```solidity
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Endorsable is Ownable {
    enum endorseState { UNASSIGNED, REQUESTED, ENDORSED, REVOKED, REMOVED, BLACKLISTED }
    mapping(address => endorseState) private endorsements;

    event Endorsed(address indexed endorser);
    event EndorsementRevoked(address indexed endorser);
    event EndorsementRequested(address indexed addr);
    event EndorsementRemoved(address indexed addr);

    constructor() Ownable(msg.sender) {}

    function endorse() external {
        require(endorsements[msg.sender] == endorseState.REQUESTED, "Contract has not been explicitly requested to endorse this item.");
        require(msg.sender.code.length > 0, "Only contracts can be endorsed.");
        endorsements[msg.sender] = endorseState.ENDORSED;
        emit Endorsed(msg.sender);
    }

    function revokeEndorsement() external {
        require(endorsements[msg.sender] == endorseState.ENDORSED, "Element not endorsed, or previously revoked or removed");
        endorsements[msg.sender] = endorseState.REVOKED;
        emit EndorsementRevoked(msg.sender);
    }

    function requestEndorsement(address addr) external onlyOwner {
        require(addr.code.length > 0, "Only contracts can be endorsed.");
        require(endorsements[addr] != endorseState.ENDORSED, "This contract has already been endorsed.");
        require(endorsements[addr] != endorseState.REQUESTED, "The signature has already been requested.");
        endorsements[addr] = endorseState.REQUESTED;
        emit EndorsementRequested(addr);
    }

    function removeEndorsement(address addr) external onlyOwner {
        require(endorsements[addr] == endorseState.ENDORSED, "Element not endorsed, or previously revoked or removed");
        endorsements[addr] = endorseState.REMOVED;
        emit EndorsementRemoved(addr);
    }

    function getEndorsementStatus(address addr) public view returns (endorseState) {
        return endorsements[addr];
    }

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