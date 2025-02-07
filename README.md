# Endorsable Smart Contract Suite

## Overview
The `Endorsable` smart contract suite provides a structured way to request, grant, revoke, and remove endorsements from addresses. It enforces explicit endorsement requests and owner-controlled endorsement management, ensuring secure and controlled endorsement flows.

## Features
- **Endorsement Requests**: The contract owner can request an endorsement from any address.
- **Endorsement Granting**: A requested address can grant endorsement.
- **Revoking Endorsement**: Users can revoke their endorsement.
- **Removing Endorsements**: The owner can remove an endorsement.
- **Endorse Another Contract**: The owner can trigger an endorsement on another `Endorsable` contract.
- **Permission Control**: Uses OpenZeppelin’s `Ownable` for access control.

## Installation
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
git clone https://github.com/YOUR_GITHUB/Endorsable.git
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

## Deployment
### Deploy Using Foundry
```sh
forge create --private-key YOUR_PRIVATE_KEY src/Endorsable.sol:Endorsable
```

### Deploy Using Hardhat
1. Create a deployment script inside `scripts/deploy.js`.
2. Deploy the contract:
   ```sh
   npx hardhat run scripts/deploy.js --network goerli
   ```

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Authors
- **5Swim Ltd / Bruce Donovan**

## Contributing
Feel free to fork, submit issues, or open a pull request if you’d like to contribute!

## Security Considerations
- Ensure the contract is only deployed on trusted networks.
- Be cautious of reentrancy attacks and always follow best Solidity security practices.

## Contact
For inquiries, please open an issue on GitHub or contact the author directly.

---

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
        require(endorsements[msg.sender] == endorseState.REQUESTED, "Account has not been explicitly requested to endorse this item.");
        endorsements[msg.sender] = endorseState.ENDORSED;
        emit Endorsed(msg.sender);
    }

    function revokeEndorsement() external {
        require(endorsements[msg.sender] == endorseState.ENDORSED, "Element not endorsed, or previously revoked or removed");
        endorsements[msg.sender] = endorseState.REVOKED;
        emit EndorsementRevoked(msg.sender);
    }

    function requestEndorsement(address addr) external onlyOwner {
        require(endorsements[addr] != endorseState.ENDORSED, "This item has already been endorsed.");
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

    function endorseAddress(address addr) external onlyOwner {
        Endorsable otherContract = Endorsable(addr);
        otherContract.endorse();
    }
}
```