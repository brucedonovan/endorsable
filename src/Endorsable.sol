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

contract Endorsable is Ownable {
    mapping(address => uint8) private endorsements;
    enum endorseState {
        UNASSIGNED, // 0
        REQUESTED, // 1
        ENDORSED, // 2
        REVOKED, // 3
        REMOVED // 4
        // BLACKLISTED // 5
    }

    event Endorsed(address indexed endorser);
    event EndorsementRevoked(address indexed endorser);
    event EndorsementRequested(address indexed addr);
    event EndorsementRemoved(address indexed addr);
    event Blacklisted(address indexed addr);

    /// @dev empty internal constructor, to prevent people from mistakenly deploying
    /// an instance of this contract, which should be used via inheritance. It also sets the ownership.
    // solium-disable-next-line
    constructor() Ownable(msg.sender) {}

    /// @notice tx sender endorses the contract, ONLY if requested to do so.
    /// @dev endorses a contract
    function endorse() external {
        require(
            endorsements[msg.sender] == uint8(endorseState.REQUESTED),
            "Endorsement not requested"
        );
        endorsements[msg.sender] = uint8(endorseState.ENDORSED);
        emit Endorsed(msg.sender);
    }

    /// @notice tx sender revokes thier address from endorsements
    /// @dev if not endorsed yet, it remains in the list as requested
    function revokeEndorsement() external {
        require(
            endorsements[msg.sender] == uint8(endorseState.ENDORSED),
            "Not endorsed, already revoked, or removed."
        );
        endorsements[msg.sender] = uint8(endorseState.REVOKED);
        emit EndorsementRevoked(msg.sender);
    }

    /// @dev Adds an address to the signatures requested
    /// Note: this will revert 'Removed' and 'Revoked' statuses back to 'Requested'.
    function requestEndorsement(address addr) external onlyOwner {
        require(
            endorsements[addr] != uint8(endorseState.ENDORSED),
            "Already endorsed."
        );
        require(
            endorsements[addr] != uint8(endorseState.REQUESTED),
            "Already requested."
        );
        // require(
        //     endorsements[addr] != uint8(endorseState.BLACKLISTED),
        //     "Cannot request from blacklisted address."
        // );
        endorsements[addr] = uint8(endorseState.REQUESTED);
        emit EndorsementRequested(addr);
    }

    /// @dev removes any address that has previously signed the item
    function removeEndorsement(address addr) external onlyOwner {
        require(
            endorsements[addr] == uint8(endorseState.ENDORSED) ||
            endorsements[addr] == uint8(endorseState.REQUESTED),
            "Not endorsed or requested."
        );
        endorsements[addr] = uint8(endorseState.REMOVED);
        emit EndorsementRemoved(addr);
    }

    // /// @dev Blacklists an address, preventing future endorsements ( - IS THIS EVEN NEEDED? )
    // function blacklistAddress(address addr) external onlyOwner {
    //     endorsements[addr] = uint8(endorseState.BLACKLISTED);
    //     emit Blacklisted(addr);
    // }

    /// Returns if the signature is requested.
    /// @dev retrieves the state of the endorsement
    /// @return endorseState representing the endorsement state of the contract
    function getEndorsementStatus(address addr) public view returns (uint8) {
        return endorsements[addr];
    }
}
