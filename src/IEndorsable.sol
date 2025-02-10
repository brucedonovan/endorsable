// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IEndorsable {
    /// @dev Enum representing the possible endorsement states for an address:
    /// 0 = UNASSIGNED, 1 = REQUESTED, 2 = ENDORSED, 3 = REVOKED, 4 = REMOVED
    enum endorseState {
        UNASSIGNED,
        REQUESTED,
        ENDORSED,
        REVOKED,
        REMOVED
    }

    /// @dev Emitted when an address endorses the contract.
    event Endorsed(address indexed endorser);

    /// @dev Emitted when an address revokes its own endorsement.
    event EndorsementRevoked(address indexed endorser);

    /// @dev Emitted when the contract owner requests an endorsement by a given address.
    event EndorsementRequested(address indexed addr);

    /// @dev Emitted when the contract owner removes an existing or requested endorsement.
    event EndorsementRemoved(address indexed addr);

    /**
     * @notice Endorses the caller (sets status to ENDORSED if previously REQUESTED).
     * @dev Reverts if the caller is not in the REQUESTED state.
     */
    function endorse() external;

    /**
     * @notice Revokes the caller’s endorsement (sets status to REVOKED if previously ENDORSED).
     * @dev Reverts if the caller is not in the ENDORSED state.
     */
    function revokeEndorsement() external;

    /**
     * @notice Requests an endorsement for `addr`. (In the main contract, this is restricted by `onlyOwner`.)
     * @dev Sets the status to REQUESTED unless it's already ENDORSED or REQUESTED.
     * @param addr The address for which the request is made.
     */
    function requestEndorsement(address addr) external;

    /**
     * @notice Removes an existing or requested endorsement for `addr` (In the main contract, this is restricted by `onlyOwner`.)
     * @dev Changes the status from ENDORSED or REQUESTED to REMOVED.
     * @param addr The address whose endorsement is to be removed.
     */
    function removeEndorsement(address addr) external;

    /**
     * @notice Returns the endorsement status (0–4) for the specified address.
     * @param addr The address whose endorsement status is being queried.
     * @return uint8 representing the address's endorsement state.
     */
    function getEndorsementStatus(address addr) external view returns (uint8);
}