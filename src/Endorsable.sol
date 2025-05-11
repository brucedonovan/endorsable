// SPDX-License-Identifier: MIT
/*
The MIT License (MIT)
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

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Endorsable
 * @author Bruce Donovan
 * @notice An inheritable contract that allows the parent contract to be endorsed by another addresses (contracts or EOAs).
 * @dev This contract is intended to be inherited by other contracts that require endorsement functionality.
 */
contract Endorsable is Ownable {
    /**
     * @notice Stores the endorsement status for each address.
     */
    mapping(address => State) private endorsements;

    /**
     * @notice Enum representing the possible endorsement states for an address in this contract: (0 = UNASSIGNED, 1 = REQUESTED, 2 = ENDORSED, 3 = REVOKED, 4 = REMOVED).
     */
    enum State {
        UNASSIGNED,
        REQUESTED,
        ENDORSED,
        REVOKED,
        REMOVED
    }

    event Endorsed(address indexed endorser, string comment);
    event EndorsementRevoked(address indexed endorser, string comment);
    event EndorsementRequested(address indexed addr, string comment);
    event EndorsementRemoved(address indexed addr, string comment);

    /**
     * @dev constructor to ensure proper ownership is set - and set pre-requested addresses, if required. This contract is generally intended to be used via inheritance. Considering using `Ownable2step.sol` extension for a more secure ownership model.
     */
    constructor(address[] memory _initialRequests) Ownable(msg.sender) {
        for (uint256 i = 0; i < _initialRequests.length; i++) {
            endorsements[_initialRequests[i]] = State.REQUESTED;
        }
    }

    /**
     * @notice Contract is endorsed by the caller. This only possible if the contract owner has requested an endorsement.
     * @dev Sets the endorsement state for the caller to 'ENDORSED'. Reverts if the caller address does not have a 'REQUESTED' status.
     * @param comment Any additional information about the endorsement, included in the emitted event.
     */
    function endorse(string calldata comment) external {
        require(endorsements[msg.sender] == State.REQUESTED, "Endorsement not requested.");
        endorsements[msg.sender] = State.ENDORSED;
        emit Endorsed(msg.sender, comment);
    }

    /**
     * @notice Revokes the caller’s endorsement on the contract.
     * @dev Sets status to REVOKED if previously ENDORSED. Reverts if the caller is not in the ENDORSED state.
     * @param comment Any additional information about the revoke, included in the emitted event.
     */
    function revokeEndorsement(string calldata comment) external {
        require(endorsements[msg.sender] == State.ENDORSED, "Not endorsed, already revoked, or removed.");
        endorsements[msg.sender] = State.REVOKED;
        emit EndorsementRevoked(msg.sender, comment);
    }

    /**
     * @notice Requests an endorsement from a specific address.
     * @dev Sets the status to REQUESTED. This also resets any 'REMOVED' or 'REVOKED' status back to 'REQUESTED'. Reverts if the contract is already ENDORSED or REQUESTED. Only callable by the contract owner.
     * @param addr The address whose endorsement is requested.
     * @param comment Any additional information about the request, included in the emitted event.
     */
    function requestEndorsement(address addr, string calldata comment) external onlyOwner {
        require(endorsements[addr] != State.ENDORSED, "Already endorsed.");
        require(endorsements[addr] != State.REQUESTED, "Already requested.");
        endorsements[addr] = State.REQUESTED;
        emit EndorsementRequested(addr, comment);
    }

    /**
     * @notice Removes an existing or requested endorsement for an address/contract.
     * @dev Changes the status from ENDORSED/REQUESTED to REMOVED. Only callable by the contract owner.
     * @param addr The address whose endorsement is to be removed.
     * @param comment Any additional information about the removal, included in the emitted event.
     */
    function removeEndorsement(address addr, string calldata comment) external onlyOwner {
        require(
            endorsements[addr] == State.ENDORSED || endorsements[addr] == State.REQUESTED, "Not endorsed or requested."
        );
        endorsements[addr] = State.REMOVED;
        emit EndorsementRemoved(addr, comment);
    }

    /**
     * @notice Returns the endorsement status for the specified address.
     * @dev states: 0 = UNASSIGNED, 1 = REQUESTED, 2 = ENDORSED, 3 = REVOKED, 4 = REMOVED
     * @param addr The address whose endorsement status is being queried.
     * @return uint8 representing the address's endorsement state.
     */
    function getEndorsementStatus(address addr) public view returns (State) {
        return endorsements[addr];
    }
}
