// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/forge-std/src/Test.sol";
import "../src/EndorsableState.sol";

/**
 * @title EndorsableStateTest
 * @dev Test the simplified state-based endorsement system
 */
contract EndorsableStateTest is Test {
    EndorsableState endorsableContract;
    
    address owner = address(0x1);
    address alice = address(0x2);
    address bob = address(0x3);
    address charlie = address(0x4);
    
    address[] initialEndorsers = [alice, bob];
    
    // Events for testing
    event StateEndorsed(bytes32 indexed stateId, address indexed endorser, string comment);
    event StateEndorsementRequested(bytes32 indexed stateId, address indexed addr, string comment);
    event StateEndorsementRevoked(bytes32 indexed stateId, address indexed endorser, string comment);
    
    function setUp() public {
        vm.prank(owner);
        endorsableContract = new EndorsableState(initialEndorsers);
    }
    
    function testStateEndorsementFlow() public {
        // Alice requests endorsement from Bob for her "profile" state
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse my profile");
        
        // Check that Bob has REQUESTED status (1) for Alice's profile state
        uint8 status = endorsableContract.getStateEndorsementStatus(alice, "profile", bob);
        assertEq(status, 1, "Should be REQUESTED");
        
        // Bob endorses Alice's profile state
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Great profile!");
        
        // Check that Bob now has ENDORSED status (2) for Alice's profile state  
        status = endorsableContract.getStateEndorsementStatus(alice, "profile", bob);
        assertEq(status, 2, "Should be ENDORSED");
        
        // Bob revokes his endorsement
        vm.prank(bob);
        endorsableContract.revokeStateEndorsement(alice, "profile", "Changed my mind");
        
        // Check that Bob now has REVOKED status (3)
        status = endorsableContract.getStateEndorsementStatus(alice, "profile", bob);
        assertEq(status, 3, "Should be REVOKED");
    }
    
    function testCannotEndorseWithoutRequest() public {
        // Charlie tries to endorse Alice's profile state without a request
        vm.prank(charlie);
        vm.expectRevert("Not requested");
        endorsableContract.endorseState(alice, "profile", "Trying to endorse without request");
    }
    
    function testMultipleEndorsers() public {
        // Alice requests endorsements from Bob and Charlie for her profile
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse from Bob");
        
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", charlie, "Please endorse from Charlie");
        
        // Bob endorses Alice's profile
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Bob endorses");
        
        // Charlie endorses Alice's profile
        vm.prank(charlie);
        endorsableContract.endorseState(alice, "profile", "Charlie endorses");
        
        // Check both endorsements
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 2, "Bob should have endorsed");
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", charlie), 2, "Charlie should have endorsed");
        
        // Test endorsement counting
        address[] memory endorsers = new address[](2);
        endorsers[0] = bob;
        endorsers[1] = charlie;
        
        uint256 count = endorsableContract.getStateEndorsementCount(alice, "profile", endorsers);
        assertEq(count, 2, "Should have 2 endorsements");
    }
    
    function testIndependentStates() public {
        // Alice and Bob both request endorsements for their respective profiles
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", charlie, "Endorse Alice profile");
        
        vm.prank(bob);
        endorsableContract.requestStateEndorsement("profile", charlie, "Endorse Bob profile");
        
        // Charlie endorses only Alice's profile
        vm.prank(charlie);
        endorsableContract.endorseState(alice, "profile", "Endorsing Alice");
        
        // Check that only Alice's profile is endorsed by Charlie
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", charlie), 2, "Alice should be endorsed");
        assertEq(endorsableContract.getStateEndorsementStatus(bob, "profile", charlie), 1, "Bob should still be requested");
    }
    
    function testCannotRequestFromSelf() public {
        // Alice tries to request endorsement from herself
        vm.prank(alice);
        vm.expectRevert("Cannot request endorsement from self");
        endorsableContract.requestStateEndorsement("profile", alice, "Self endorsement");
    }
    
    function testCannotRevokeWithoutEndorsement() public {
        // Alice requests endorsement from Bob
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        // Bob tries to revoke without endorsing first
        vm.prank(bob);
        vm.expectRevert("Not endorsed");
        endorsableContract.revokeStateEndorsement(alice, "profile", "Cannot revoke");
    }
    
    function testBatchGetStateEndorsementStatus() public {
        // Alice requests endorsements from Bob and Charlie
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse from Bob");
        
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", charlie, "Please endorse from Charlie");
        
        // Bob endorses
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Bob endorses");
        
        // Check batch status
        address[] memory addresses = new address[](2);
        addresses[0] = bob;
        addresses[1] = charlie;
        
        uint8[] memory statuses = endorsableContract.batchGetStateEndorsementStatus(alice, "profile", addresses);
        assertEq(statuses[0], 2, "Bob should be endorsed");
        assertEq(statuses[1], 1, "Charlie should be requested");
    }
}
