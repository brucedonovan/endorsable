// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/EndorsableState.sol";

/**
 * @title ScoreEndorsementState
 * @dev Example contract showing how to use EndorsableState for state-specific endorsements
 * This contract manages player scores and allows endorsements using "score" as the state identifier
 */
contract ScoreEndorsementState is EndorsableState {
    struct Score {
        uint256 value;
        string playerName;
        uint256 timestamp;
        bool exists;
    }
    
    mapping(address => Score) public scores;
    address[] public scoreSubmitters;
    
    event ScoreSubmitted(address indexed submitter, string playerName, uint256 value);
    
    constructor(address[] memory _initialEndorsers) EndorsableState(_initialEndorsers) {
        // Constructor automatically sets up initial endorsers for the contract
    }
    
    /**
     * @notice Submit a new score
     * @param playerName The name of the player
     * @param value The score value
     */
    function submitScore(string memory playerName, uint256 value) public {
        scores[msg.sender] = Score({
            value: value,
            playerName: playerName,
            timestamp: block.timestamp,
            exists: true
        });
        
        // Add to list if first time submitting
        if (!hasSubmittedScore(msg.sender)) {
            scoreSubmitters.push(msg.sender);
        }
        
        emit ScoreSubmitted(msg.sender, playerName, value);
    }
    
    /**
     * @notice Check if an address has submitted a score
     * @param submitter The address to check
     * @return True if they have submitted a score
     */
    function hasSubmittedScore(address submitter) public view returns (bool) {
        return scores[submitter].exists;
    }
    
    /**
     * @notice Get score details for a specific submitter
     * @param submitter The address of the score submitter
     * @return score The score struct
     */
    function getScore(address submitter) public view returns (Score memory) {
        require(scores[submitter].exists, "Score does not exist");
        return scores[submitter];
    }
    
    /**
     * @notice Get all score submitters
     * @return Array of all addresses that have submitted scores
     */
    function getAllScoreSubmitters() public view returns (address[] memory) {
        return scoreSubmitters;
    }
    
    /**
     * @notice Request endorsement for your score from another address
     * @param endorser The address to request endorsement from
     * @param comment Additional information about the endorsement request
     */
    function requestScoreEndorsement(address endorser, string calldata comment) external {
        require(scores[msg.sender].exists, "You must submit a score first");
        requestStateEndorsement("score", endorser, comment);
    }
    
    /**
     * @notice Endorse someone else's score
     * @param scoreOwner The address whose score to endorse
     * @param comment Additional information about the endorsement
     */
    function endorseScore(address scoreOwner, string calldata comment) external {
        require(scores[scoreOwner].exists, "Score does not exist");
        endorseState(scoreOwner, "score", comment);
    }
    
    /**
     * @notice Revoke endorsement of someone else's score
     * @param scoreOwner The address whose score endorsement to revoke
     * @param comment Additional information about the revocation
     */
    function revokeScoreEndorsement(address scoreOwner, string calldata comment) external {
        revokeStateEndorsement(scoreOwner, "score", comment);
    }
    
    /**
     * @notice Get endorsement status for a specific score
     * @param scoreOwner The address whose score to check
     * @param endorser The endorser address to check
     * @return The endorsement state as uint8
     */
    function getScoreEndorsementStatus(address scoreOwner, address endorser) public view returns (uint8) {
        require(scores[scoreOwner].exists, "Score does not exist");
        return getStateEndorsementStatus(scoreOwner, "score", endorser);
    }
    
    /**
     * @notice Get the number of endorsements for a specific score
     * @param scoreOwner The address whose score to check
     * @param addresses The list of addresses to check for endorsements
     * @return count The number of addresses that have endorsed this score
     */
    function getScoreEndorsementCount(address scoreOwner, address[] calldata addresses) external view returns (uint256) {
        require(scores[scoreOwner].exists, "Score does not exist");
        return getStateEndorsementCount(scoreOwner, "score", addresses);
    }
}
