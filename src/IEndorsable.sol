// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IEndorsable {
    /**
     * @dev Enum representing the possible endorsement states for an address:
     * 0 = UNASSIGNED, 1 = REQUESTED, 2 = ENDORSED, 3 = REVOKED, 4 = REMOVED
     */
    enum endorseState {
        UNASSIGNED,
        REQUESTED,
        ENDORSED,
        REVOKED,
        REMOVED
    }

    /// @dev Emitted when an address endorses the contract.
    event Endorsed(address indexed endorser, string comment);

    /// @dev Emitted when an address revokes its endorsement.
    event EndorsementRevoked(address indexed endorser, string comment);

    /// @dev Emitted when the contract owner requests an endorsement by a given address.
    event EndorsementRequested(address indexed addr, string comment);

    /// @dev Emitted when the contract owner removes an existing or requested endorsement.
    event EndorsementRemoved(address indexed addr, string comment);

    /**
     * @notice Contract is endorsed by the caller. This only possible if the contract owner has requested an endorsement.
     * @dev Sets the endorsement state for the caller to 'ENDORSED'. Reverts if the caller address does not have a 'REQUESTED' status.
     * @param comment Any additional information about the endorsement, included in the emitted event.
     */
    function endorse( string calldata comment ) external;

    /**
     * @notice Revokes the caller’s endorsement on the contract.
     * @dev Sets status to REVOKED if previously ENDORSED. Reverts if the caller is not in the ENDORSED state.
     * @param comment Any additional information about the revoke, included in the emitted event.
     */
    function revokeEndorsement(string calldata comment) external;

    /**
     * @notice Requests an endorsement from a specific address.
     * @dev Sets the status to REQUESTED. This also resets any 'REMOVED' or 'REVOKED' status back to 'REQUESTED'. Reverts if the contract is already ENDORSED or REQUESTED.  
     * Only callable by the contract owner.
     * @param addr The address whose endorsement is requested.
     * @param comment Any additional information about the request, included in the emitted event.
     */
    function requestEndorsement(address addr, string calldata comment) external;

    /**
     * @notice Removes an existing or requested endorsement for an address.
     * @dev Changes the status from ENDORSED/REQUESTED to REMOVED. Only callable by the contract owner.
     * @param addr The address whose endorsement is to be removed.
     * @param comment Any additional information about the removal, included in the emitted event.
     */
    function removeEndorsement(address addr, string calldata comment) external;

    /**
     * @notice Returns the endorsement status for the specified address.
     * @dev states: 0 = UNASSIGNED, 1 = REQUESTED, 2 = ENDORSED, 3 = REVOKED, 4 = REMOVED
     * @param addr The address whose endorsement status is being queried.
     * @return uint8 representing the address's endorsement state.
     */
    function getEndorsementStatus(address addr) external view returns (uint8);
}
