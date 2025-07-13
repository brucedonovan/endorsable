// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IEndorsable.sol";

/**
 * @title IEndorsableState
 * @notice Interface for EndorsableState contract that supports state-specific endorsements
 * @dev Extends IEndorsable to include state-level endorsement functionality
 */
interface IEndorsableState is IEndorsable {
    // State-level endorsement events
    event StateEndorsed(bytes32 indexed stateId, address indexed endorser, string comment);
    event StateEndorsementRevoked(bytes32 indexed stateId, address indexed endorser, string comment);
    event StateEndorsementRequested(bytes32 indexed stateId, address indexed addr, string comment);
    event StateEndorsementRemoved(bytes32 indexed stateId, address indexed addr, string comment);

    // State-specific endorsement functions
    function endorseState(string calldata identifier, string calldata comment) external;
    function revokeStateEndorsement(string calldata identifier, string calldata comment) external;
    function requestStateEndorsement(string calldata identifier, address addr, string calldata comment) external;
    function removeStateEndorsement(string calldata identifier, address addr, string calldata comment) external;

    // View functions
    function getStateEndorsementStatus(address owner, string calldata identifier, address addr) external view returns (uint8);
    function getStateId(address owner, string memory identifier) external pure returns (bytes32);
}
