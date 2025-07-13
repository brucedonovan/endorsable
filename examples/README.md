# Endorsable Contract Examples - Complete Implementation Guide

This directory contains comprehensive examples demonstrating the usage of both `Endorsable.sol` and `EndorsableState.sol` contracts, complete with tests and detailed documentation.

## 📁 File Structure

```
examples/
├── README.md                    # This comprehensive guide
├── ReputableBusiness.sol        # Endorsable contract example
├── ProjectPortfolio.sol         # EndorsableState contract example
└── test/
    ├── ReputableBusiness.t.sol  # Comprehensive tests for ReputableBusiness
    └── ProjectPortfolio.t.sol   # Comprehensive tests for ProjectPortfolio
```

## Overview

- **`ReputableBusiness.sol`**: Demonstrates basic `Endorsable` functionality for contract-level endorsements
- **`ProjectPortfolio.sol`**: Demonstrates `EndorsableState` functionality for state-specific endorsements

## 🏢 ReputableBusiness Example (Endorsable)

**Purpose**: Demonstrates contract-level endorsements for business reputation management.

The `ReputableBusiness` contract shows how a business can be endorsed by partners, customers, or auditors at the contract level.

### Key Features

1. **Business Metrics**: Tracks years in business, successful transactions, and audit status
2. **Reputation Scoring**: Calculates a reputation score (0-100) based on endorsements and business metrics
3. **Trustworthiness Check**: Determines if a business is trustworthy based on endorsements and criteria
4. **Owner-controlled endorsement requests**

### Usage Scenarios

- Business partnerships and vendor verification
- Service provider reputation systems
- Professional certification tracking
- Audit and compliance endorsements

### Usage Flow

```solidity
// 1. Deploy the contract with initial endorsement requests
address[] memory initialRequests = [auditor1, partner1, customer1];
ReputableBusiness business = new ReputableBusiness(
    "Acme Corp",
    "Software Development",
    5, // years in business
    initialRequests
);

// 2. Business owner requests additional endorsements
business.requestEndorsement(partner2, "Requesting endorsement from new partner");

// 3. Requested addresses can endorse the business
// (Called by auditor1, partner1, etc.)
business.endorse("Great business practices and reliable delivery");

// 4. Check reputation and trustworthiness
address[] memory endorsers = [auditor1, partner1, customer1, partner2];
uint256 score = business.getReputationScore(endorsers);
bool trustworthy = business.isTrustworthy(endorsers);
```

### Contract-Level Endorsement States

- `UNASSIGNED (0)`: No endorsement status
- `REQUESTED (1)`: Endorsement has been requested
- `ENDORSED (2)`: Address has endorsed the contract
- `REVOKED (3)`: Endorsement was revoked
- `REMOVED (4)`: Endorsement was removed by owner

## 🎯 ProjectPortfolio Example (EndorsableState)

**Purpose**: Demonstrates state-specific endorsements for individual project evaluation.

The `ProjectPortfolio` contract demonstrates state-specific endorsements where individual projects within a portfolio can be endorsed separately.

### Key Features

1. **Project Management**: Create, update, and complete projects
2. **Per-Project Endorsements**: Each project can be endorsed independently
3. **Batch Operations**: Request endorsements from multiple addresses at once
4. **Project Reputation**: Calculate reputation scores for individual projects
5. **Quality Assessment**: Determine if projects meet quality standards
6. **Portfolio-wide and project-specific metrics**

### Usage Scenarios

- Freelancer/contractor portfolio management
- Software development project tracking
- Research project peer review
- Creative work portfolio endorsements

### Usage Flow

```solidity
// 1. Deploy portfolio contract
address[] memory contractEndorsers = [industry_expert];
ProjectPortfolio portfolio = new ProjectPortfolio(
    "Tech Startup Portfolio",
    contractEndorsers
);

// 2. Create projects
portfolio.createProject(
    "web-app-v1",
    "E-commerce Web Application",
    "Full-stack web app with payment integration",
    2 ether,
    true // public
);

// 3. Request project-specific endorsements
address[] memory projectEndorsers = [client1, reviewer1, expert1];
portfolio.requestProjectEndorsements(
    "web-app-v1",
    projectEndorsers,
    "Please review and endorse this project"
);

// 4. Endorsers can endorse specific projects
// (Called by client1, reviewer1, etc.)
portfolio.endorseState(
    portfolioOwner,
    "web-app-v1",
    "Excellent code quality and user experience"
);

// 5. Check project reputation
uint256 projectScore = portfolio.getProjectReputationScore(
    portfolioOwner,
    "web-app-v1",
    projectEndorsers
);
bool isHighQuality = portfolio.isHighQualityProject(
    portfolioOwner,
    "web-app-v1",
    projectEndorsers
);

// 6. Get endorsement summary
(uint256 endorsed, uint256 requested, uint256 revoked) = 
    portfolio.getProjectEndorsementSummary(portfolioOwner, "web-app-v1", projectEndorsers);
```

### State-Specific Endorsement Flow

1. **Project Creation**: Owner creates projects with unique identifiers
2. **Endorsement Requests**: Owner requests endorsements for specific projects
3. **State Endorsement**: Endorsers endorse individual projects using `endorseState()`
4. **State Management**: Each project maintains separate endorsement states
5. **Batch Queries**: Check multiple endorsements efficiently

### State-Specific Functions

- `endorseState(owner, identifier, comment)`: Endorse a specific project
- `revokeStateEndorsement(owner, identifier, comment)`: Revoke project endorsement
- `requestStateEndorsement(identifier, addr, comment)`: Request project endorsement
- `getStateEndorsementStatus(owner, identifier, addr)`: Check project endorsement status
- `getStateEndorsementCount(owner, identifier, addresses)`: Count project endorsements
## 🧪 Testing

Both examples come with comprehensive test suites that demonstrate:

### ReputableBusiness Tests (11 tests)
- ✅ Initial setup and configuration
- ✅ Complete endorsement workflow
- ✅ Business metrics updates and transaction recording
- ✅ Reputation scoring and trustworthiness evaluation
- ✅ Access control and error handling
- ✅ Endorsement revocation and state management

### ProjectPortfolio Tests (13 tests)
- ✅ Project creation and management
- ✅ State-specific endorsement flows
- ✅ Batch operations and status checks
- ✅ Project completion and updates
- ✅ Reputation scoring for individual projects
- ✅ Quality assessment and endorsement summaries
- ✅ Multi-project portfolio management

### Testing Instructions

To test these examples:

1. Deploy the contracts with initial endorsement requests
2. Use different addresses to simulate endorsers
3. Call endorsement functions from endorser addresses
4. Query reputation scores and endorsement statuses
5. Test edge cases like revoking endorsements and removing requests

## 🚀 Running the Examples

```bash
# Clone the repository and install dependencies
forge install

# Run example tests from the examples directory
cd examples
forge test

# Or run from the root directory with specific paths
forge test --match-path "examples/test/*.sol"

# Run specific example tests
forge test --match-contract ReputableBusinessTest --match-path "examples/test/*.sol"
forge test --match-contract ProjectPortfolioTest --match-path "examples/test/*.sol"

# Run specific test functions
forge test --match-test testReputationScore --match-path "examples/test/*.sol"
forge test --match-test testProjectEndorsementFlow --match-path "examples/test/*.sol"

# Build the contracts
forge build
```

## 💡 Key Implementation Insights

### Contract-Level vs State-Level Endorsements

| Feature | Endorsable | EndorsableState |
|---------|------------|-----------------|
| **Scope** | Entire contract | Individual states/items |
| **Granularity** | Single endorsement per address | Multiple endorsements per address (different states) |
| **Use Case** | Business/Service endorsement | Project/Feature endorsement |
| **State ID** | Contract address | `keccak256(owner, identifier)` |
| **Inheritance** | Inherits from `Ownable` | Inherits from `Endorsable` |
| **Complexity** | Simple, straightforward | More complex, flexible |

### Best Practices Demonstrated

1. **Access Control**: Proper ownership management using OpenZeppelin's `Ownable`
2. **Event Emission**: Comprehensive event logging for off-chain tracking
3. **Error Handling**: Clear error messages and proper validation
4. **Gas Optimization**: Batch operations for multiple address checks
5. **State Management**: Proper handling of endorsement state transitions
6. **Data Validation**: Input validation and existence checks
7. **Validation**: Always validate that projects/states exist before operations
8. **Batch Operations**: Use batch functions for efficiency when checking multiple addresses

### Security Considerations

- ✅ Owner-only functions properly protected
- ✅ State validation before operations
- ✅ Prevention of self-endorsement
- ✅ Proper handling of state transitions
- ✅ Input validation and boundary checks

## 🔧 Integration Guide

### For Business Reputation Systems
```solidity
// Deploy with initial endorsement requests
address[] memory initialRequests = [auditor, partner, regulator];
ReputableBusiness business = new ReputableBusiness(
    "Acme Corp",
    "Software Development", 
    5,
    initialRequests
);

// Check business trustworthiness
bool trustworthy = business.isTrustworthy(endorserList);
uint256 score = business.getReputationScore(endorserList);
```

### For Project Portfolio Management
```solidity
// Deploy portfolio
ProjectPortfolio portfolio = new ProjectPortfolio("My Portfolio", []);

// Create and manage projects
portfolio.createProject("web-app", "E-commerce Site", "...", 2 ether, true);
portfolio.requestProjectEndorsements("web-app", endorsers, "Please review");

// Check project quality
bool highQuality = portfolio.isHighQualityProject(owner, "web-app", endorsers);
uint256 reputation = portfolio.getProjectReputationScore(owner, "web-app", endorsers);
```

## 📊 State Management

Both contracts properly handle the endorsement state lifecycle:

```
UNASSIGNED (0) → REQUESTED (1) → ENDORSED (2)
                      ↓              ↓
                 REMOVED (4)    REVOKED (3)
```

## Integration Tips

- Use events to build off-chain indexes of endorsements
- Implement reputation caching for frequently accessed scores
- Consider implementing endorsement expiry mechanisms
- Use batch operations to reduce gas costs for multiple checks
- Implement proper access controls for sensitive operations

## 🎯 Next Steps

1. **Customize**: Adapt the examples for your specific use case
2. **Extend**: Add additional features like endorsement expiry, weighted endorsements, or reputation decay
3. **Integrate**: Combine with other DeFi protocols for enhanced functionality
4. **Scale**: Implement off-chain indexing for large-scale deployments

## 📚 Additional Resources

- [Endorsable.sol Documentation](../src/Endorsable.sol)
- [EndorsableState.sol Documentation](../src/EndorsableState.sol)
- [Foundry Testing Guide](https://book.getfoundry.sh/forge/tests)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
