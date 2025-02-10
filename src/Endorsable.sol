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

/// @title Endorsable
/// @author Bruce Donovan
/// @notice An inheritable contract that allows the contract to be endorsed by another contract/EOA.
/// @dev This contract is intended to be inherited by other contracts that require endorsement functionality.
contract Endorsable is Ownable {
    
    /// @notice Stores the endorsement status for each address.
    /// @dev We use uint8 for minor gas savings instead of a string-based approach.
    mapping(address => uint8) private endorsements;

    /// @notice Enum representing the possible endorsement states for an address in this contract: (0 = UNASSIGNED, 1 = REQUESTED, 2 = ENDORSED, 3 = REVOKED, 4 = REMOVED).
    /// @dev We use uint8 for minor gas savings instead of a string-based approach.
    enum endorseState {
        UNASSIGNED, //0
        REQUESTED, //1
        ENDORSED, //2
        REVOKED, //3
        REMOVED //4
            // BLACKLISTED //5

    }

    event Endorsed(address indexed endorser);
    event EndorsementRevoked(address indexed endorser);
    event EndorsementRequested(address indexed addr);
    event EndorsementRemoved(address indexed addr);
    event Blacklisted(address indexed addr);

    /// @dev Minimal constructor to ensure proper ownership is set. This contract is generally intended to be used via inheritance.
    constructor() Ownable(msg.sender) {}

    /// @notice Sets the endorsement state for the caller to 'ENDORSED' if their status was previously 'REQUESTED'.
    /// @dev The caller must currently have a 'REQUESTED' status in order to endorse.
    function endorse() external {
        require(endorsements[msg.sender] == uint8(endorseState.REQUESTED), "Endorsement not requested.");
        endorsements[msg.sender] = uint8(endorseState.ENDORSED);
        emit Endorsed(msg.sender);
    }

    /// @notice Allows the caller to revoke their own endorsement.
    /// @dev If the caller is not currently 'ENDORSED', this call reverts (so it remains in its previous state).
    function revokeEndorsement() external {
        require(endorsements[msg.sender] == uint8(endorseState.ENDORSED), "Not endorsed, already revoked, or removed.");
        endorsements[msg.sender] = uint8(endorseState.REVOKED);
        emit EndorsementRevoked(msg.sender);
    }

    /// @notice Requests an endorsement for a specific address.
    /// @dev This resets any 'REMOVED' or 'REVOKED' status back to 'REQUESTED'. Only callable by the contract owner.
    /// @param addr The address whose endorsement is requested.
    function requestEndorsement(address addr) external onlyOwner {
        require(endorsements[addr] != uint8(endorseState.ENDORSED), "Already endorsed.");
        require(endorsements[addr] != uint8(endorseState.REQUESTED), "Already requested.");
        // require(
        //     endorsements[addr] != uint8(endorseState.BLACKLISTED),
        //     "Cannot request from blacklisted address."
        // );
        endorsements[addr] = uint8(endorseState.REQUESTED);
        emit EndorsementRequested(addr);
    }

    /// @notice Removes an endorsement or request for the specified address.
    /// @dev This changes an 'ENDORSED' or 'REQUESTED' status to 'REMOVED'. Only callable by the contract owner.
    /// @param addr The address whose endorsement is to be removed.
    function removeEndorsement(address addr) external onlyOwner {
        require(
            endorsements[addr] == uint8(endorseState.ENDORSED) || endorsements[addr] == uint8(endorseState.REQUESTED),
            "Not endorsed or requested."
        );
        endorsements[addr] = uint8(endorseState.REMOVED);
        emit EndorsementRemoved(addr);
    }

    // /// @dev Blacklists an address, preventing future endorsements.
    // /// @notice This would set the address status to 'BLACKLISTED' (5).
    // function blacklistAddress(address addr) external onlyOwner {
    //     endorsements[addr] = uint8(endorseState.BLACKLISTED);
    //     emit Blacklisted(addr);
    // }

    /// @notice Returns the endorsement status (0–4) for the specified address.
    /// @param addr The address whose endorsement status is being queried.
    /// @return uint8 representing the address's endorsement state.
    function getEndorsementStatus(address addr) public view returns (uint8) {
        return endorsements[addr];
    }
}
