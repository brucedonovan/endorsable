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
    event Endorsed(address indexed endorser);

    /// @dev Emitted when an address revokes its endorsement.
    event EndorsementRevoked(address indexed endorser);

    /// @dev Emitted when the contract owner requests an endorsement by a given address.
    event EndorsementRequested(address indexed addr);

    /// @dev Emitted when the contract owner removes an existing or requested endorsement.
    event EndorsementRemoved(address indexed addr);

    /**
    * @notice Caller endorses the contract. Only possible if the contract owner has requested an endorsement.
    * @dev Sets the endorsement state for the caller to 'ENDORSED'. Reverts if the caller address does not have a 'REQUESTED' status.
    */
    function endorse() external;

    /**
     * @notice Revokes the caller’s endorsement on an endorsable contract.
     * @dev Sets status to REVOKED if previously ENDORSED. Reverts if the caller is not in the ENDORSED state.
     */
    function revokeEndorsement() external;

    /**
    * @notice Requests an endorsement from a specific contract/EOA.
    * @dev Sets the status to REQUESTED. This also resets any 'REMOVED' or 'REVOKED' status back to 'REQUESTED'. Reverts if the contract is already ENDORSED or REQUESTED.  * Only callable by the contract owner.
    * @param addr The address whose endorsement is requested.
    */
    function requestEndorsement(address addr) external;

    /**
     * @notice Removes an existing or requested endorsement for an address/contract.
     * @dev Changes the status from ENDORSED or REQUESTED to REMOVED. Only callable by the contract owner.
     * @param addr The address whose endorsement is to be removed.
     */
    function removeEndorsement(address addr) external;

    /**
     * @notice Returns the endorsement status for the specified address (0 = UNASSIGNED, 1 = REQUESTED, 2 = ENDORSED, 3 = REVOKED, 4 = REMOVED).
     * @param addr The address whose endorsement status is being queried.
     * @return uint8 representing the address's endorsement state. (0 = UNASSIGNED, 1 = REQUESTED, 2 = ENDORSED, 3 = REVOKED, 4 = REMOVED).
     */
    function getEndorsementStatus(address addr) external view returns (uint8);
}
