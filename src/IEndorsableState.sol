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
    function endorseState(address stateOwner, string memory identifier, string memory comment) external;
    function revokeStateEndorsement(address stateOwner, string memory identifier, string memory comment) external;
    function requestStateEndorsement(string memory identifier, address addr, string memory comment) external;
    function removeStateEndorsement(string calldata identifier, address addr, string calldata comment) external;

    // View functions
    function getStateEndorsementStatus(address owner, string calldata identifier, address addr)
        external
        view
        returns (uint8);
    function getStateId(address owner, string memory identifier) external pure returns (bytes32);
}
