// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/Endorsable.sol";

/**
 * @title ReputableBusiness
 * @notice Example contract demonstrating Endorsable functionality
 * @dev This contract represents a business that can be endorsed by partners, customers, or auditors
 */
contract ReputableBusiness is Endorsable {
    string public businessName;
    string public businessType;
    address public businessOwner;
    
    // Business metrics that might influence endorsement decisions
    uint256 public yearsInBusiness;
    uint256 public successfulTransactions;
    bool public isAudited;
    
    constructor(
        string memory _businessName,
        string memory _businessType,
        uint256 _yearsInBusiness,
        address[] memory _initialEndorsementRequests
    ) Endorsable(_initialEndorsementRequests) {
        businessName = _businessName;
        businessType = _businessType;
        businessOwner = msg.sender;
        yearsInBusiness = _yearsInBusiness;
        successfulTransactions = 0;
        isAudited = false;
    }
    
    /**
     * @notice Update business metrics
     * @dev Only the business owner can update these metrics
     */
    function updateBusinessMetrics(
        uint256 _yearsInBusiness,
        uint256 _successfulTransactions,
        bool _isAudited
    ) external onlyOwner {
        yearsInBusiness = _yearsInBusiness;
        successfulTransactions = _successfulTransactions;
        isAudited = _isAudited;
    }
    
    /**
     * @notice Record a successful business transaction
     * @dev Increments the successful transaction counter
     */
    function recordSuccessfulTransaction() external onlyOwner {
        successfulTransactions++;
    }
    
    /**
     * @notice Get business reputation score based on endorsements
     * @dev Simple reputation calculation based on endorsements and business metrics
     * @param endorsers Array of addresses to check for endorsements
     * @return score Reputation score (0-100)
     */
    function getReputationScore(address[] calldata endorsers) external view returns (uint256 score) {
        uint256 endorsementCount = 0;
        
        // Count valid endorsements
        for (uint256 i = 0; i < endorsers.length; i++) {
            if (getEndorsementStatus(endorsers[i]) == State.ENDORSED) {
                endorsementCount++;
            }
        }
        
        // Base score from endorsements (max 70 points)
        score = endorsementCount * 10;
        if (score > 70) score = 70;
        
        // Bonus points for business metrics
        if (yearsInBusiness >= 5) score += 10;
        if (successfulTransactions >= 100) score += 10;
        if (isAudited) score += 10;
        
        // Cap at 100
        if (score > 100) score = 100;
    }
    
    /**
     * @notice Check if business is considered trustworthy
     * @dev Business is trustworthy if it has at least 3 endorsements and meets certain criteria
     * @param endorsers Array of addresses to check for endorsements
     * @return Whether the business is considered trustworthy
     */
    function isTrustworthy(address[] calldata endorsers) external view returns (bool) {
        uint256 endorsementCount = 0;
        
        for (uint256 i = 0; i < endorsers.length; i++) {
            if (getEndorsementStatus(endorsers[i]) == State.ENDORSED) {
                endorsementCount++;
            }
        }
        
        return endorsementCount >= 3 && yearsInBusiness >= 2 && isAudited;
    }
}
