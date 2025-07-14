# Endorsable

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]
## ✨ Key Features

## Overview

`Endorsable` provides a comprehensive, inheritable smart contract framework for managing and tracking on-chain endorsements. The system offers two complementary contracts:

- **`Endorsable.sol`**: Contract-level endorsements for entire smart contracts
- **`EndorsableState.sol`**: State-specific endorsements for individual components within contracts

By extending these contracts, any smart contract can implement robust endorsement systems with clear lifecycle management, making them ideal for trust, verification, and reputation scenarios in decentralized applications.


### Contract-Level Features (`Endorsable.sol`)
- **🔐 Owner-Controlled Requests**: Contract owner manages endorsement requests
- **✅ Endorsement Granting**: Requested addresses can provide endorsements
- **🔄 Revocation Support**: Endorsers can revoke their endorsements
- **🗑️ Owner Removal**: Contract owner can remove any endorsement
- **💬 Comment System**: All actions support contextual comments (emitted in events)
- **🔒 Access Control**: Built on OpenZeppelin's `Ownable` for security

### State-Level Features (`EndorsableState.sol`)
- **🎯 Granular Endorsements**: Endorse specific states/components within contracts
- **🔄 Dual System**: Inherits contract-level endorsements + adds state-specific functionality
- **📦 Batch Operations**: Efficient batch requests and status checks
- **🏷️ Flexible Identifiers**: Use string identifiers for different states/projects
- **📊 Independent Tracking**: Each state maintains separate endorsement status
- **🔍 Comprehensive Queries**: Query endorsements at both contract and state levels

### Shared Features
- **🛡️ Security**: Comprehensive access controls and state validation
- **📝 Event Logging**: Complete audit trail through event emissions
- **⚡ Gas Efficient**: Optimized for minimal gas consumption
- **🧪 Battle-Tested**: Comprehensive test coverage with edge case handling
- **📚 Well-Documented**: Extensive documentation and examplesIT)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.13-blue.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-000000.svg)](https://getfoundry.sh/)


## ✨ What's New in v0.1.0

### 🚀 Major New Features
- **`EndorsableState.sol`**: Brand new contract enabling state-specific endorsements within a single contract
- **Dual Endorsement System**: Support for both contract-level and granular state-level endorsements
- **Enhanced Examples**: Comprehensive real-world examples with `ReputableBusiness` and `ProjectPortfolio`
- **Batch Operations**: Efficient batch endorsement requests and status checks
- **Improved Interface Design**: Cleaner, more intuitive API with enhanced documentation

### 🔧 Improvements from v0.0.2-beta
- **State Management**: Each endorsable state maintains independent endorsement tracking
- **Better Constructor Design**: Streamlined initialization with initial endorsement requests
- **Enhanced Testing**: Comprehensive test suites covering edge cases and integration scenarios
- **Documentation Overhaul**: Complete rewrite with detailed usage guides and best practices
- **Gas Optimization**: More efficient batch operations for multiple address operations

### 🐛 Bug Fixes
- Fixed state transition edge cases in endorsement lifecycle
- Improved error messaging for better debugging
- Enhanced access control validationle 

A 'micro-contract' experiment - the smallest utility contract that can offer real-world benefits.

## Overview

`Endorsable` provides an inheritable, structured mechanism for managing and tracking endorsements of a contract on-chain.  
By extending `Endorsable`, any parent contract can allow external addresses (EOAs or other contracts) to grant endorsements on itself.
The contract enforces a clear endorsement lifecycle of requests, approvals, revocations, and removals, making it ideal for scenarios where trust, verification, and reputation are important.


## 🏗️ Architecture

### Contract Overview

| Contract | Purpose | Inheritance | Use Case |
|----------|---------|-------------|----------|
| **`Endorsable.sol`** | Contract-level endorsements | `Ownable` | Business reputation, service certification |
| **`EndorsableState.sol`** | State-specific endorsements | `Endorsable` | Project portfolios, feature validation |

### Endorsement States

Both contracts use a standardized 5-state endorsement lifecycle:

```
UNASSIGNED (0) → REQUESTED (1) → ENDORSED (2)
                      ↓              ↓
                 REMOVED (4)    REVOKED (3)
```

- **`UNASSIGNED (0)`**: No endorsement interaction has occurred
- **`REQUESTED (1)`**: Contract owner has requested an endorsement
- **`ENDORSED (2)`**: Address has provided an endorsement
- **`REVOKED (3)`**: Endorser has revoked their endorsement
- **`REMOVED (4)`**: Contract owner has removed the endorsement

## 🎯 Use Cases

### Contract-Level Endorsements (`Endorsable.sol`)

1. **Smart Contract Security Audits & Certifications**
   - Security audit firms endorse verified smart contracts
   - Endorsements can be revoked if vulnerabilities are discovered
   - DeFi protocols display audit endorsements to users

2. **DAO Governance & Reputation Systems**
   - DAOs require endorsements before executing governance actions
   - Member reputation tracking and voting weight determination
   - Multi-signature endorsement requirements for critical decisions

3. **Service Provider Verification**
   - Professional service providers (lawyers, consultants, developers)
   - Business partnership and vendor verification systems
   - Regulatory compliance and certification tracking

### State-Level Endorsements (`EndorsableState.sol`)

1. **Project Portfolio Management**
   - Freelancers showcase endorsed individual projects
   - Software development milestone validation
   - Creative work and portfolio piece endorsements

2. **Feature-Specific Validation**
   - Individual smart contract features endorsed separately
   - API endpoint validation and certification
   - Module-level security assessments

3. **Academic & Research Applications**
   - Peer review systems for research projects
   - Individual publication endorsements
   - Course and curriculum component validation

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

## 📦 Installation & Quick Start

### Installation Options

**Option 1: Foundry (Recommended)**
```bash
forge install https://github.com/brucedonovan/endorsable.git
```

**Option 2: NPM/Yarn**
```bash
npm install @brucedonovan/endorsable
# or
yarn add @brucedonovan/endorsable
```

### Quick Start

#### Contract-Level Endorsements
```solidity
pragma solidity ^0.8.13;

import "@brucedonovan/endorsable/src/Endorsable.sol";

contract MyContract is Endorsable {
    constructor(address[] memory _initialRequests) 
        Endorsable(_initialRequests) 
    {
        // Your contract logic
    }
    
    // Your contract functions...
}
```

#### State-Level Endorsements
```solidity
pragma solidity ^0.8.13;

import "@brucedonovan/endorsable/src/EndorsableState.sol";

contract MyProjectPortfolio is EndorsableState {
    constructor(address[] memory _initialRequests) 
        EndorsableState(_initialRequests) 
    {
        // Your contract logic
    }
    
    function createProject(string memory projectId) external onlyOwner {
        // Create project logic...
        
        // Request endorsements for this specific project
        address[] memory endorsers = [reviewer1, client1, auditor1];
        for (uint i = 0; i < endorsers.length; i++) {
            requestStateEndorsement(projectId, endorsers[i], "Please review this project");
        }
    }
}
```

## 🔄 Changelog

### v0.1.0 (Current Version) - July 2025

#### 🚀 Major Features Added
- **New Contract**: `EndorsableState.sol` for state-specific endorsements
- **Dual Endorsement System**: Support for both contract-level and state-level endorsements
- **Enhanced Examples**: Added `ReputableBusiness.sol` and `ProjectPortfolio.sol` examples
- **Batch Operations**: Efficient batch endorsement requests and status queries
- **Improved Architecture**: Better separation of concerns between contract types

#### 🔧 Improvements
- **Constructor Enhancement**: Streamlined initialization with initial endorsement requests
- **Gas Optimization**: More efficient batch operations for multiple address checks
- **Enhanced Testing**: Comprehensive test suites with 11+ tests per contract
- **Documentation Overhaul**: Complete rewrite with detailed guides and best practices
- **Interface Design**: Cleaner, more intuitive API with enhanced type safety

#### 🐛 Bug Fixes
- Fixed state transition edge cases in endorsement lifecycle
- Improved error messaging for better debugging experience
- Enhanced access control validation for security

### v0.0.2-beta - Previous Version

#### Features
- **Comment System**: Added comment parameter to all functions for contextual information
- **Event Enhancement**: Comments included in all endorsement events
- **Basic Endorsement Lifecycle**: Request, endorse, revoke, remove functionality
- **Owner Access Control**: Built on OpenZeppelin's `Ownable` contract

## 🛠️ Development Setup

### Prerequisites

- **Foundry**: Modern Solidity development framework
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```

### Clone & Install

```bash
git clone https://github.com/brucedonovan/endorsable.git
cd endorsable
forge install
```

### Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific contract tests
forge test --match-contract EndorsableTest
forge test --match-contract EndorsableStateTest

# Run example tests
cd examples && forge test
```

### Building

```bash
forge build
```

## 📚 Examples & Documentation

The `examples/` directory contains comprehensive, production-ready examples demonstrating real-world usage of both contracts:

### 🏢 ReputableBusiness (`Endorsable`)
- **Purpose**: Business reputation management with contract-level endorsements
- **Features**: Reputation scoring, trustworthiness evaluation, partner endorsements
- **Use Cases**: Service providers, business partnerships, regulatory compliance

### 🎯 ProjectPortfolio (`EndorsableState`)  
- **Purpose**: Project portfolio with state-specific endorsements
- **Features**: Individual project endorsements, batch operations, quality assessment
- **Use Cases**: Freelancer portfolios, software projects, academic research

### Running Examples

```bash
# Run all example tests
cd examples && forge test

# Run specific examples
forge test --match-contract ReputableBusinessTest --match-path "examples/test/*.sol"
forge test --match-contract ProjectPortfolioTest --match-path "examples/test/*.sol"

# Test with detailed output
cd examples && forge test -vvv
```

📖 **See the [Examples README](./examples/README.md)** for comprehensive guides, integration patterns, and best practices.

## 🔌 Smart Contract Interfaces

### Core Endorsement States

```solidity
enum State {
    UNASSIGNED,  // 0: No interaction
    REQUESTED,   // 1: Endorsement requested
    ENDORSED,    // 2: Successfully endorsed
    REVOKED,     // 3: Endorsement revoked
    REMOVED      // 4: Endorsement removed by owner
}
```

### Key Functions

#### `Endorsable.sol` - Contract Level
```solidity
// Request endorsement from an address
function requestEndorsement(address addr, string calldata comment) external onlyOwner;

// Endorse the contract (only if requested)
function endorse(string calldata comment) external;

// Revoke your endorsement
function revokeEndorsement(string calldata comment) external;

// Remove endorsement (owner only)
function removeEndorsement(address addr, string calldata comment) external onlyOwner;

// Check endorsement status
function getEndorsementStatus(address addr) external view returns (uint8);
```

#### `EndorsableState.sol` - State Level
```solidity
// Request state-specific endorsement
function requestStateEndorsement(string calldata identifier, address addr, string calldata comment) external onlyOwner;

// Endorse a specific state
function endorseState(address owner, string calldata identifier, string calldata comment) external;

// Revoke state endorsement
function revokeStateEndorsement(address owner, string calldata identifier, string calldata comment) external;

// Remove state endorsement
function removeStateEndorsement(string calldata identifier, address addr, string calldata comment) external onlyOwner;

// Check state endorsement status
function getStateEndorsementStatus(address owner, string calldata identifier, address addr) external view returns (uint8);
```

## 🔐 Security Considerations

### Access Control
- **Owner-Only Functions**: Endorsement requests and removals restricted to contract owner
- **Endorser Validation**: Only requested addresses can provide endorsements
- **State Protection**: Comprehensive validation prevents invalid state transitions

### Best Practices
- **Input Validation**: Always validate state identifiers and addresses
- **Event Monitoring**: Use events for off-chain indexing and monitoring
- **Gas Optimization**: Utilize batch functions for multiple operations
- **Reentrancy Safety**: Built-in protection against reentrancy attacks

### Recommendations
- Implement endorsement expiry mechanisms for time-sensitive use cases
- Consider multi-signature requirements for critical endorsements
- Use IPFS links in comments for detailed endorsement documentation
- Implement reputation decay for long-term reputation systems

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request
