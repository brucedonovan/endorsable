# EndorsableState Architecture

This document explains the modular architecture of the Endorsable contract system, split into basic contract-level endorsements and advanced state/entity endorsements.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────────────────┐
│   Endorsable    │    │      EndorsableState        │
│ (Basic Contract)│    │   (State/Entity Support)    │
│                 │◄───┤                             │
│ • Contract-level│    │ • Inherits Endorsable       │
│   endorsements  │    │ • Entity-level endorsements │
│ • Owner control │    │ • Creator permissions       │
│ • 5 states      │    │ • Utility functions         │
└─────────────────┘    └─────────────────────────────┘
         ▲                          ▲
         │                          │
         │                          │
┌─────────────────┐    ┌─────────────────────────────┐
│   IEndorsable   │    │      IEndorsableState       │
│    Interface    │    │        Interface            │
└─────────────────┘    └─────────────────────────────┘
```

## Contract Breakdown

### 1. **Endorsable.sol** - Basic Contract Endorsements

**Purpose**: Provides contract-level endorsement functionality where users can endorse the entire contract.

**Key Features**:
- ✅ **Contract-level endorsements** - Endorse the entire contract
- ✅ **Owner-controlled requests** - Only contract owner can request endorsements
- ✅ **5-state lifecycle** - UNASSIGNED → REQUESTED → ENDORSED → REVOKED/REMOVED
- ✅ **Inheritance-ready** - Designed to be inherited by other contracts

**Core Functions**:
```solidity
function endorse(string comment) external
function revokeEndorsement(string comment) external  
function requestEndorsement(address addr, string comment) external onlyOwner
function removeEndorsement(address addr, string comment) external onlyOwner
function getEndorsementStatus(address addr) public view returns (State)
```

### 2. **EndorsableState.sol** - Entity/State Endorsements

**Purpose**: Extends basic Endorsable to support endorsing specific entities/state within the contract (like individual scores, proposals, reviews, etc.).

**Key Features**:
- ✅ **Inherits from Endorsable** - All contract-level functionality included
- ✅ **Entity-specific endorsements** - Endorse individual items within the contract
- ✅ **Creator permissions** - Entity creators can request endorsements for their own entities
- ✅ **Independent tracking** - Contract and entity endorsements are tracked separately
- ✅ **Utility functions** - ID generation and creator management

**Additional Functions**:
```solidity
// Entity endorsement functions
function endorseEntity(bytes32 entityId, string comment) public
function revokeEntityEndorsement(bytes32 entityId, string comment) public
function requestEntityEndorsement(bytes32 entityId, address addr, string comment) public onlyOwner
function requestEntityEndorsementByCreator(bytes32 entityId, address addr, string comment) public
function removeEntityEndorsement(bytes32 entityId, address addr, string comment) public onlyOwner
function getEntityEndorsementStatus(bytes32 entityId, address addr) public view returns (uint8)

// Creator management
function registerEntityCreator(bytes32 entityId, address creator) public onlyOwner
function entityCreators(bytes32 entityId) public view returns (address)

// Utilities
function generateEntityId(string entityName) public pure returns (bytes32)
```

## State Management

Both contracts use the same 5-state endorsement lifecycle:

```
0. UNASSIGNED ──┐
                │
                ▼
1. REQUESTED ────────► 2. ENDORSED ────────► 3. REVOKED
    ▲                       │
    │                       ▼
    └─────────────────► 4. REMOVED
```

**State Meanings**:
- **UNASSIGNED** (0): No endorsement interaction has occurred
- **REQUESTED** (1): Endorsement has been requested from this address
- **ENDORSED** (2): Address has provided an endorsement
- **REVOKED** (3): Address has revoked their previous endorsement
- **REMOVED** (4): Owner has removed the endorsement request/endorsement

## Usage Patterns

### Pattern 1: Basic Contract Endorsement

```solidity
contract MyContract is Endorsable {
    constructor() Endorsable([]) {}
    
    // Your contract logic here
}

// Usage:
// 1. Owner requests endorsement: requestEndorsement(validator, "Please endorse")
// 2. Validator endorses: endorse("This contract is legitimate")
// 3. Check status: getEndorsementStatus(validator) returns 2 (ENDORSED)
```

### Pattern 2: Entity/State Endorsement

```solidity
contract GameLeaderboard is EndorsableState {
    constructor() EndorsableState([]) {}
    
    function submitScore(string memory playerName, uint256 score) public returns (bytes32) {
        bytes32 scoreId = generateEntityId(string(abi.encodePacked(playerName, "-", block.timestamp)));
        // Store score logic...
        _registerEntityCreator(scoreId, msg.sender); // Register submitter as creator
        return scoreId;
    }
}

// Usage:
// 1. Player submits score: submitScore("Alice", 95000)
// 2. Player requests endorsement: requestEntityEndorsementByCreator(scoreId, validator, "Verify score")
// 3. Validator endorses: endorseEntity(scoreId, "Score verified")
// 4. Check status: getEntityEndorsementStatus(scoreId, validator) returns 2 (ENDORSED)
```

### Pattern 3: Hybrid Approach

```solidity
contract HybridContract is EndorsableState {
    // Use contract-level endorsements for overall platform trust
    // Use entity-level endorsements for individual content items
    
    constructor() EndorsableState([trustedValidator1, trustedValidator2]) {}
    
    // Contract is pre-requested for endorsement from trusted validators
    // Individual posts/content can be endorsed separately
}
```

## Benefits of This Architecture

### 🔧 **Modularity**
- Use `Endorsable` for simple contract endorsements
- Upgrade to `EndorsableState` only when you need entity-specific endorsements
- Clear separation of concerns

### 📈 **Scalability**
- Contract-level endorsements for platform trust
- Entity-level endorsements for content validation
- Independent state tracking prevents conflicts

### 🛡️ **Security**
- Owner controls for administrative functions
- Creator permissions for user empowerment
- Clear access patterns and state transitions

### 🔄 **Flexibility**
- Support both centralized (owner-only) and decentralized (creator-driven) workflows
- Easy to extend with additional functionality
- Compatible with existing contracts through inheritance

## Example Applications

### Gaming Platforms
- **Contract endorsement**: Validators endorse the game contract as fair
- **Score endorsement**: Individual high scores can be verified by experts

### Content Platforms
- **Contract endorsement**: Platform endorsed as legitimate by moderators  
- **Post endorsement**: Individual posts endorsed by community members

### Proposal Systems
- **Contract endorsement**: DAO contract endorsed by governance experts
- **Proposal endorsement**: Individual proposals endorsed by domain experts

### Marketplaces
- **Contract endorsement**: Marketplace endorsed as secure by auditors
- **Product endorsement**: Individual products endorsed by verified buyers

## Migration Path

If you have existing contracts using the original combined Endorsable:

1. **Basic endorsements only**: Switch to `Endorsable.sol`
2. **Need entity endorsements**: Switch to `EndorsableState.sol`
3. **Gradual migration**: `EndorsableState` is fully backward compatible with `Endorsable`

The architecture provides a clean upgrade path while maintaining full backward compatibility.
