// SPDX-License-Identifier: MIT
/*
Copyright (c) 2024 5Swim Ltd / Bruce Donovan.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
pragma solidity ^0.8.13;

import "./Endorsable.sol";
import "./IEndorsableState.sol";

/**
 * @title EndorsableState
 * @author Bruce Donovan
 * @notice An extension of Endorsable that allows endorsing specific state within the contract.
 * @dev This contract inherits contract-level endorsements from Endorsable and adds state-specific endorsement functionality.
 *      State identifiers are owned by `msg.sender` (the state owner), not by the contract owner.
 *      Any address can request, remove, and receive endorsements for states keyed to itself.
 */
contract EndorsableState is Endorsable, IEndorsableState {
    /**
     * @notice Stores the endorsement status for specific state within the contract.
     * @dev Key is the state identifier (hash of caller + identifier string), value is endorser -> state mapping.
     */
    mapping(bytes32 => mapping(address => State)) private stateEndorsements;

    /**
     * @dev constructor to ensure proper ownership is set and handle initial requests for both contract and state endorsements.
     */
    constructor(address[] memory _initialRequests) Endorsable(_initialRequests) {
        // Contract-level initial requests are handled by parent Endorsable constructor
    }

    // ================================
    // STATE-SPECIFIC ENDORSEMENT FUNCTIONS
    // ================================

    /**
     * @notice Endorse a specific state owned by another address
     * @param stateOwner The address that owns the state being endorsed
     * @param identifier The string identifier for the state
     * @param comment Optional comment explaining the endorsement
     */
    function endorseState(address stateOwner, string calldata identifier, string calldata comment) public {
        require(stateOwner != address(0), "Invalid state owner");
        bytes32 stateId = getStateId(stateOwner, identifier);
        require(stateEndorsements[stateId][msg.sender] == State.REQUESTED, "Not requested");

        stateEndorsements[stateId][msg.sender] = State.ENDORSED;
        emit StateEndorsed(stateId, msg.sender, comment);
    }

    /**
     * @notice Revoke endorsement of a specific state owned by another address
     * @param stateOwner The address that owns the state
     * @param identifier The string identifier for the state
     * @param comment Optional comment explaining the revocation
     */
    function revokeStateEndorsement(address stateOwner, string calldata identifier, string calldata comment) public {
        require(stateOwner != address(0), "Invalid state owner");
        bytes32 stateId = getStateId(stateOwner, identifier);
        require(stateEndorsements[stateId][msg.sender] == State.ENDORSED, "Not endorsed");

        stateEndorsements[stateId][msg.sender] = State.REVOKED;
        emit StateEndorsementRevoked(stateId, msg.sender, comment);
    }

    /**
     * @notice Request endorsement for a specific state from another address
     * @dev Callable by the state owner (`msg.sender`), not the contract owner. Re-requesting is allowed from
     *      REVOKED or REMOVED, matching contract-level `requestEndorsement`.
     * @param identifier The string identifier for the state
     * @param addr The address to request endorsement from
     * @param comment Optional comment explaining the request
     */
    function requestStateEndorsement(string calldata identifier, address addr, string calldata comment) public {
        require(bytes(identifier).length > 0, "Empty identifier");
        require(addr != address(0), "Invalid address");
        require(addr != msg.sender, "Cannot request endorsement from self");
        bytes32 stateId = getStateId(msg.sender, identifier);
        require(stateEndorsements[stateId][addr] != State.ENDORSED, "Already endorsed.");
        require(stateEndorsements[stateId][addr] != State.REQUESTED, "Already requested.");

        stateEndorsements[stateId][addr] = State.REQUESTED;
        emit StateEndorsementRequested(stateId, addr, comment);
    }

    /**
     * @notice Remove endorsement status for a specific state
     * @dev Only the state owner (`msg.sender`) can remove endorsements for their own state.
     *      Sets status to REMOVED (not UNASSIGNED) for parity with contract-level `removeEndorsement`.
     *      Allowed from ENDORSED or REQUESTED only.
     * @param identifier The string identifier for the state
     * @param addr The address to remove endorsement status from
     * @param comment Optional comment explaining the removal
     */
    function removeStateEndorsement(string calldata identifier, address addr, string calldata comment) external {
        require(bytes(identifier).length > 0, "Empty identifier");
        require(addr != address(0), "Invalid address");
        bytes32 stateId = getStateId(msg.sender, identifier);
        require(
            stateEndorsements[stateId][addr] == State.ENDORSED || stateEndorsements[stateId][addr] == State.REQUESTED,
            "Not endorsed or requested."
        );

        stateEndorsements[stateId][addr] = State.REMOVED;
        emit StateEndorsementRemoved(stateId, addr, comment);
    }

    // ================================
    // VIEW FUNCTIONS
    // ================================

    /**
     * @notice Get the endorsement status of a specific state by a specific address
     * @param owner The address that owns the state
     * @param identifier The string identifier for the state
     * @param addr The address to check endorsement status for
     * @return The endorsement status (UNASSIGNED, REQUESTED, ENDORSED, REVOKED, or REMOVED)
     */
    function getStateEndorsementStatus(address owner, string calldata identifier, address addr)
        public
        view
        returns (State)
    {
        bytes32 stateId = getStateId(owner, identifier);
        return stateEndorsements[stateId][addr];
    }

    /**
     * @notice Generate the unique state ID from owner address and identifier
     * @param owner The address that owns the state
     * @param identifier The string identifier for the state
     * @return The unique state ID
     */
    function getStateId(address owner, string calldata identifier) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, identifier));
    }
}
