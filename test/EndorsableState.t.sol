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
    event StateEndorsementRemoved(bytes32 indexed stateId, address indexed addr, string comment);
    
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

    // ================================
    // MISSING FUNCTIONALITY TESTS
    // ================================

    function testRemoveStateEndorsement() public {
        // Alice requests endorsement from Bob
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        // Verify Bob has REQUESTED status
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 1, "Should be REQUESTED");
        
        // Alice removes Bob's endorsement status
        vm.prank(alice);
        endorsableContract.removeStateEndorsement("profile", bob, "Removing endorsement");
        
        // Verify Bob now has UNASSIGNED status
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 0, "Should be UNASSIGNED");
    }

    function testRemoveStateEndorsementFromEndorsed() public {
        // Alice requests endorsement from Bob
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        // Bob endorses Alice's profile
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Great profile!");
        
        // Verify Bob has ENDORSED status
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 2, "Should be ENDORSED");
        
        // Alice removes Bob's endorsement status
        vm.prank(alice);
        endorsableContract.removeStateEndorsement("profile", bob, "Removing endorsement");
        
        // Verify Bob now has UNASSIGNED status
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 0, "Should be UNASSIGNED");
    }

    function testRemoveStateEndorsementFromRevoked() public {
        // Complete flow: request -> endorse -> revoke -> remove
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Great profile!");
        
        vm.prank(bob);
        endorsableContract.revokeStateEndorsement(alice, "profile", "Changed my mind");
        
        // Verify Bob has REVOKED status
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 3, "Should be REVOKED");
        
        // Alice removes Bob's endorsement status
        vm.prank(alice);
        endorsableContract.removeStateEndorsement("profile", bob, "Removing revoked endorsement");
        
        // Verify Bob now has UNASSIGNED status
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 0, "Should be UNASSIGNED");
    }

    function testRemoveStateEndorsementFromUnassigned() public {
        // Try to remove endorsement status that doesn't exist
        vm.prank(alice);
        endorsableContract.removeStateEndorsement("profile", bob, "Removing non-existent");
        
        // Should still be UNASSIGNED (no error, just no-op)
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 0, "Should remain UNASSIGNED");
    }

    // ================================
    // EVENT EMISSION TESTS
    // ================================

    function testStateEndorsementRequestedEvent() public {
        bytes32 expectedStateId = endorsableContract.getStateId(alice, "profile");
        
        vm.expectEmit(true, true, false, true);
        emit StateEndorsementRequested(expectedStateId, bob, "Please endorse my profile");
        
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse my profile");
    }

    function testStateEndorsedEvent() public {
        // Setup: Alice requests endorsement from Bob
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        bytes32 expectedStateId = endorsableContract.getStateId(alice, "profile");
        
        vm.expectEmit(true, true, false, true);
        emit StateEndorsed(expectedStateId, bob, "Great profile!");
        
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Great profile!");
    }

    function testStateEndorsementRevokedEvent() public {
        // Setup: Alice requests endorsement from Bob, Bob endorses
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Great profile!");
        
        bytes32 expectedStateId = endorsableContract.getStateId(alice, "profile");
        
        vm.expectEmit(true, true, false, true);
        emit StateEndorsementRevoked(expectedStateId, bob, "Changed my mind");
        
        vm.prank(bob);
        endorsableContract.revokeStateEndorsement(alice, "profile", "Changed my mind");
    }

    function testStateEndorsementRemovedEvent() public {
        // Setup: Alice requests endorsement from Bob
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        bytes32 expectedStateId = endorsableContract.getStateId(alice, "profile");
        
        vm.expectEmit(true, true, false, true);
        emit StateEndorsementRemoved(expectedStateId, bob, "Removing endorsement");
        
        vm.prank(alice);
        endorsableContract.removeStateEndorsement("profile", bob, "Removing endorsement");
    }

    // ================================
    // EDGE CASES AND ERROR CONDITIONS
    // ================================

    function testCannotRequestWhenAlreadyRequested() public {
        // Alice requests endorsement from Bob
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        // Alice tries to request again from Bob
        vm.prank(alice);
        vm.expectRevert("Already has endorsement status");
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse again");
    }

    function testCannotRequestWhenAlreadyEndorsed() public {
        // Complete endorsement flow
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Great profile!");
        
        // Alice tries to request again from Bob
        vm.prank(alice);
        vm.expectRevert("Already has endorsement status");
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse again");
    }

    function testCannotRequestWhenAlreadyRevoked() public {
        // Complete flow to revoked state
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Great profile!");
        
        vm.prank(bob);
        endorsableContract.revokeStateEndorsement(alice, "profile", "Changed my mind");
        
        // Alice tries to request again from Bob
        vm.prank(alice);
        vm.expectRevert("Already has endorsement status");
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse again");
    }

    function testRequestAfterRemoval() public {
        // Complete flow: request -> remove -> request again
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse");
        
        vm.prank(alice);
        endorsableContract.removeStateEndorsement("profile", bob, "Removing");
        
        // Now Alice should be able to request again
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse again");
        
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 1, "Should be REQUESTED");
    }

    // ================================
    // DIFFERENT STATE IDENTIFIERS
    // ================================

    function testMultipleStateIdentifiers() public {
        // Alice requests endorsements for different states from Bob
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Endorse profile");
        
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("skills", bob, "Endorse skills");
        
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("education", bob, "Endorse education");
        
        // Bob endorses only the profile
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Great profile!");
        
        // Check states are independent
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 2, "Profile should be ENDORSED");
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "skills", bob), 1, "Skills should be REQUESTED");
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "education", bob), 1, "Education should be REQUESTED");
    }

    function testStateIdGeneration() public {
        // Test that different combinations produce different state IDs
        bytes32 aliceProfile = endorsableContract.getStateId(alice, "profile");
        bytes32 bobProfile = endorsableContract.getStateId(bob, "profile");
        bytes32 aliceSkills = endorsableContract.getStateId(alice, "skills");
        
        // All should be different
        assertTrue(aliceProfile != bobProfile, "Different owners should have different state IDs");
        assertTrue(aliceProfile != aliceSkills, "Different identifiers should have different state IDs");
        assertTrue(bobProfile != aliceSkills, "All combinations should be unique");
        
        // Same inputs should produce same ID
        bytes32 aliceProfile2 = endorsableContract.getStateId(alice, "profile");
        assertEq(aliceProfile, aliceProfile2, "Same inputs should produce same state ID");
    }

    function testEmptyStringIdentifier() public {
        // Test with empty string identifier
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("", bob, "Empty identifier");
        
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "", bob), 1, "Should work with empty string");
    }

    // ================================
    // INTEGRATION WITH INHERITED ENDORSABLE
    // ================================

    function testContractAndStateEndorsementsIndependent() public {
        // Test that contract-level and state-level endorsements are independent
        
        // Alice requests contract-level endorsement from Bob (this should be in initialRequests)
        // Since bob is in initialRequests, he should already have REQUESTED status for contract-level
        uint8 contractStatus = uint8(endorsableContract.getEndorsementStatus(bob));
        assertEq(contractStatus, 1, "Bob should have REQUESTED status for contract-level");
        
        // Alice requests state-level endorsement from Bob
        vm.prank(alice);
        endorsableContract.requestStateEndorsement("profile", bob, "Please endorse my profile");
        
        // Check both statuses are independent
        assertEq(uint8(endorsableContract.getEndorsementStatus(bob)), 1, "Contract-level should still be REQUESTED");
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 1, "State-level should be REQUESTED");
        
        // Bob endorses state-level
        vm.prank(bob);
        endorsableContract.endorseState(alice, "profile", "Great profile!");
        
        // Contract-level should be unaffected
        assertEq(uint8(endorsableContract.getEndorsementStatus(bob)), 1, "Contract-level should still be REQUESTED");
        assertEq(endorsableContract.getStateEndorsementStatus(alice, "profile", bob), 2, "State-level should be ENDORSED");
    }

    function testConstructorWithInitialRequests() public {
        // Verify that the constructor properly set up initial requests
        // Bob and Alice were in initialRequests array
        assertEq(uint8(endorsableContract.getEndorsementStatus(alice)), 1, "Alice should have REQUESTED status");
        assertEq(uint8(endorsableContract.getEndorsementStatus(bob)), 1, "Bob should have REQUESTED status");
        
        // Charlie was not in initial requests
        assertEq(uint8(endorsableContract.getEndorsementStatus(charlie)), 0, "Charlie should have UNASSIGNED status");
    }
}
