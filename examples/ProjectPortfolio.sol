// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/EndorsableState.sol";

/**
 * @title ProjectPortfolio
 * @notice Example contract demonstrating EndorsableState functionality
 * @dev This contract represents a portfolio where individual projects can be endorsed separately
 */
contract ProjectPortfolio is EndorsableState {
    struct Project {
        string name;
        string description;
        uint256 budget;
        uint256 completionDate;
        bool isCompleted;
        bool isPublic;
    }
    
    // Mapping from project identifier to project details
    mapping(string => Project) public projects;
    
    // Array to keep track of all project identifiers
    string[] public projectIds;
    
    address public portfolioOwner;
    string public portfolioName;
    
    event ProjectCreated(string indexed projectId, string name, uint256 budget);
    event ProjectCompleted(string indexed projectId, uint256 completionDate);
    event ProjectUpdated(string indexed projectId);
    
    constructor(
        string memory _portfolioName,
        address[] memory _initialContractEndorsementRequests
    ) EndorsableState(_initialContractEndorsementRequests) {
        portfolioName = _portfolioName;
        portfolioOwner = msg.sender;
    }
    
    /**
     * @notice Create a new project in the portfolio
     * @param projectId Unique identifier for the project
     * @param name Human-readable project name
     * @param description Project description
     * @param budget Project budget in wei
     * @param isPublic Whether the project is publicly viewable
     */
    function createProject(
        string calldata projectId,
        string calldata name,
        string calldata description,
        uint256 budget,
        bool isPublic
    ) external onlyOwner {
        require(bytes(projects[projectId].name).length == 0, "Project already exists");
        
        projects[projectId] = Project({
            name: name,
            description: description,
            budget: budget,
            completionDate: 0,
            isCompleted: false,
            isPublic: isPublic
        });
        
        projectIds.push(projectId);
        emit ProjectCreated(projectId, name, budget);
    }
    
    /**
     * @notice Mark a project as completed
     * @param projectId The project to mark as completed
     */
    function completeProject(string calldata projectId) external onlyOwner {
        require(bytes(projects[projectId].name).length > 0, "Project does not exist");
        require(!projects[projectId].isCompleted, "Project already completed");
        
        projects[projectId].isCompleted = true;
        projects[projectId].completionDate = block.timestamp;
        
        emit ProjectCompleted(projectId, block.timestamp);
    }
    
    /**
     * @notice Update project details
     * @param projectId The project to update
     * @param description New project description
     * @param budget New project budget
     * @param isPublic New visibility setting
     */
    function updateProject(
        string calldata projectId,
        string calldata description,
        uint256 budget,
        bool isPublic
    ) external onlyOwner {
        require(bytes(projects[projectId].name).length > 0, "Project does not exist");
        
        projects[projectId].description = description;
        projects[projectId].budget = budget;
        projects[projectId].isPublic = isPublic;
        
        emit ProjectUpdated(projectId);
    }
    
    /**
     * @notice Request endorsements for a specific project from multiple addresses
     * @param projectId The project to request endorsements for
     * @param endorsers Array of addresses to request endorsements from
     * @param comment Comment explaining the endorsement request
     */
    function requestProjectEndorsements(
        string calldata projectId,
        address[] calldata endorsers,
        string calldata comment
    ) external onlyOwner {
        require(bytes(projects[projectId].name).length > 0, "Project does not exist");
        
        for (uint256 i = 0; i < endorsers.length; i++) {
            // Only request if not already requested or endorsed
            uint8 status = getStateEndorsementStatus(msg.sender, projectId, endorsers[i]);
            if (status == 0) { // UNASSIGNED
                requestStateEndorsement(projectId, endorsers[i], comment);
            }
        }
    }
    
    /**
     * @notice Get project reputation score based on endorsements
     * @param owner The address that owns the project
     * @param projectId The project to calculate score for
     * @param potentialEndorsers Array of addresses to check for endorsements
     * @return score Project reputation score (0-100)
     */
    function getProjectReputationScore(
        address owner,
        string calldata projectId,
        address[] calldata potentialEndorsers
    ) external view returns (uint256 score) {
        require(bytes(projects[projectId].name).length > 0, "Project does not exist");
        
        Project memory project = projects[projectId];
        
        // Count endorsements manually since getStateEndorsementCount was removed
        uint256 endorsementCount = 0;
        for (uint256 i = 0; i < potentialEndorsers.length; i++) {
            if (getStateEndorsementStatus(owner, projectId, potentialEndorsers[i]) == 2) { // ENDORSED
                endorsementCount++;
            }
        }
        
        // Base score from endorsements (max 60 points)
        score = endorsementCount * 15;
        if (score > 60) score = 60;
        
        // Bonus points for project characteristics
        if (project.isCompleted) score += 20;
        if (project.budget > 1 ether) score += 10; // High-value project
        if (project.isPublic) score += 5; // Transparency bonus
        if (project.completionDate > 0 && 
            project.completionDate <= block.timestamp + 30 days) score += 5; // On-time completion
        
        // Cap at 100
        if (score > 100) score = 100;
    }
    
    /**
     * @notice Check if a project is considered high-quality
     * @param owner The address that owns the project
     * @param projectId The project to evaluate
     * @param potentialEndorsers Array of addresses to check for endorsements
     * @return Whether the project is considered high-quality
     */
    function isHighQualityProject(
        address owner,
        string calldata projectId,
        address[] calldata potentialEndorsers
    ) external view returns (bool) {
        require(bytes(projects[projectId].name).length > 0, "Project does not exist");
        
        Project memory project = projects[projectId];
        
        // Count endorsements manually since getStateEndorsementCount was removed
        uint256 endorsementCount = 0;
        for (uint256 i = 0; i < potentialEndorsers.length; i++) {
            if (getStateEndorsementStatus(owner, projectId, potentialEndorsers[i]) == 2) { // ENDORSED
                endorsementCount++;
            }
        }
        
        return endorsementCount >= 2 && 
               project.isCompleted && 
               project.budget >= 0.5 ether;
    }
    
    /**
     * @notice Get all project IDs
     * @return Array of all project identifiers
     */
    function getAllProjectIds() external view returns (string[] memory) {
        return projectIds;
    }
    
    /**
     * @notice Get the total number of projects
     * @return Number of projects in the portfolio
     */
    function getProjectCount() external view returns (uint256) {
        return projectIds.length;
    }
    
    /**
     * @notice Get endorsement summary for a project
     * @param owner The address that owns the project
     * @param projectId The project to get endorsement summary for
     * @param addresses Array of addresses to check
     * @return endorsedCount Number of endorsed addresses
     * @return requestedCount Number of addresses with pending requests
     * @return revokedCount Number of revoked endorsements
     */
    function getProjectEndorsementSummary(
        address owner,
        string calldata projectId,
        address[] calldata addresses
    ) external view returns (
        uint256 endorsedCount,
        uint256 requestedCount,
        uint256 revokedCount
    ) {
        require(bytes(projects[projectId].name).length > 0, "Project does not exist");
        
        // Check statuses manually since batchGetStateEndorsementStatus was removed
        for (uint256 i = 0; i < addresses.length; i++) {
            uint8 status = getStateEndorsementStatus(owner, projectId, addresses[i]);
            if (status == 2) endorsedCount++; // ENDORSED
            else if (status == 1) requestedCount++; // REQUESTED
            else if (status == 3) revokedCount++; // REVOKED
        }
    }
}
