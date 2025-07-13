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

/**
 * @title EndorsableState
 * @author Bruce Donovan
 * @notice An extension of Endorsable that allows endorsing specific state within the contract.
 * @dev This contract inherits contract-level endorsements from Endorsable and adds state-specific endorsement functionality.
 */
contract EndorsableState is Endorsable {
    /**
     * @notice Stores the endorsement status for specific state within the contract.
     * @dev Key is the state identifier (hash of caller + identifier string), value is endorser -> state mapping.
     */
    mapping(bytes32 => mapping(address => State)) private stateEndorsements;

    // State-level endorsement events
    event StateEndorsed(bytes32 indexed stateId, address indexed endorser, string comment);
    event StateEndorsementRevoked(bytes32 indexed stateId, address indexed endorser, string comment);
    event StateEndorsementRequested(bytes32 indexed stateId, address indexed addr, string comment);
    event StateEndorsementRemoved(bytes32 indexed stateId, address indexed addr, string comment);

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
    function endorseState(address stateOwner, string memory identifier, string memory comment) public {
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
    function revokeStateEndorsement(address stateOwner, string memory identifier, string memory comment) public {
        bytes32 stateId = getStateId(stateOwner, identifier);
        require(stateEndorsements[stateId][msg.sender] == State.ENDORSED, "Not endorsed");

        stateEndorsements[stateId][msg.sender] = State.REVOKED;
        emit StateEndorsementRevoked(stateId, msg.sender, comment);
    }

    /**
     * @notice Request endorsement for a specific state from another address
     * @param identifier The string identifier for the state
     * @param addr The address to request endorsement from
     * @param comment Optional comment explaining the request
     */
    function requestStateEndorsement(string memory identifier, address addr, string memory comment) public {
        bytes32 stateId = getStateId(msg.sender, identifier);
        require(addr != msg.sender, "Cannot request endorsement from self");
        require(stateEndorsements[stateId][addr] == State.UNASSIGNED, "Already has endorsement status");

        stateEndorsements[stateId][addr] = State.REQUESTED;
        emit StateEndorsementRequested(stateId, addr, comment);
    }

    /**
     * @notice Remove endorsement status for a specific state
     * @param identifier The string identifier for the state
     * @param addr The address to remove endorsement status from
     * @param comment Optional comment explaining the removal
     */
    function removeStateEndorsement(string calldata identifier, address addr, string calldata comment) external {
        bytes32 stateId = getStateId(msg.sender, identifier);
        
        stateEndorsements[stateId][addr] = State.UNASSIGNED;
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
     * @return The endorsement status (0=NONE, 1=WAITING, 2=ENDORSED, 3=REVOKED)
     */
    function getStateEndorsementStatus(address owner, string memory identifier, address addr) public view returns (uint8) {
        bytes32 stateId = getStateId(owner, identifier);
        return uint8(stateEndorsements[stateId][addr]);
    }

    /**
     * @notice Generate the unique state ID from owner address and identifier
     * @param owner The address that owns the state
     * @param identifier The string identifier for the state
     * @return The unique state ID
     */
    function getStateId(address owner, string memory identifier) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, identifier));
    }

    // ================================
    // UTILITY FUNCTIONS
    // ================================

    /**
     * @notice Get the number of endorsements for a specific state
     * @param owner The address that owns the state
     * @param identifier The string identifier for the state
     * @param addresses The list of addresses to check for endorsements
     * @return count The number of addresses that have endorsed this state
     */
    function getStateEndorsementCount(address owner, string memory identifier, address[] calldata addresses) public view returns (uint256 count) {
        bytes32 stateId = getStateId(owner, identifier);
        for (uint256 i = 0; i < addresses.length; i++) {
            if (stateEndorsements[stateId][addresses[i]] == State.ENDORSED) {
                count++;
            }
        }
    }

    /**
     * @notice Batch check endorsement statuses for multiple addresses on a specific state
     * @param owner The address that owns the state
     * @param identifier The string identifier for the state
     * @param addresses The list of addresses to check
     * @return statuses Array of endorsement statuses corresponding to the input addresses
     */
    function batchGetStateEndorsementStatus(address owner, string calldata identifier, address[] calldata addresses) 
        external 
        view 
        returns (uint8[] memory statuses) 
    {
        bytes32 stateId = getStateId(owner, identifier);
        statuses = new uint8[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            statuses[i] = uint8(stateEndorsements[stateId][addresses[i]]);
        }
    }
}
