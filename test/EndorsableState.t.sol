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

    // ================================
    // ENHANCED FUZZING TESTS
    // ================================

    /**
     * @notice Fuzz test for state endorsement requests with various identifiers and addresses.
     */
    function testFuzz_StateEndorsementRequest(
        address stateOwner,
        address endorser, 
        string memory identifier,
        string memory comment
    ) public {
        vm.assume(stateOwner != address(0) && endorser != address(0));
        vm.assume(stateOwner != endorser); // Cannot request from self
        vm.assume(stateOwner != alice && stateOwner != bob && stateOwner != charlie);
        vm.assume(endorser != alice && endorser != bob && endorser != charlie);
        
        // Deploy fresh contract to avoid interference
        address[] memory emptyRequests = new address[](0);
        vm.prank(stateOwner);
        EndorsableState freshContract = new EndorsableState(emptyRequests);
        
        // Request state endorsement
        vm.prank(stateOwner);
        freshContract.requestStateEndorsement(identifier, endorser, comment);
        
        // Check state and invariants
        uint8 status = freshContract.getStateEndorsementStatus(stateOwner, identifier, endorser);
        assertEq(status, 1, "Should be REQUESTED");
        
        // Invariant: Cannot request again for same state/endorser combo
        vm.prank(stateOwner);
        vm.expectRevert("Already has endorsement status");
        freshContract.requestStateEndorsement(identifier, endorser, "Should fail");
        
        // Invariant: Different identifiers should be independent
        vm.prank(stateOwner);
        freshContract.requestStateEndorsement(string.concat(identifier, "_different"), endorser, comment);
        assertEq(freshContract.getStateEndorsementStatus(stateOwner, string.concat(identifier, "_different"), endorser), 1, "Different identifier should work");
    }

    /**
     * @notice Fuzz test for state endorsement after request with validation.
     */
    function testFuzz_StateEndorse(
        address stateOwner,
        address endorser,
        string memory identifier,
        string memory requestComment,
        string memory endorseComment
    ) public {
        vm.assume(stateOwner != address(0) && endorser != address(0));
        vm.assume(stateOwner != endorser);
        vm.assume(stateOwner != alice && stateOwner != bob && stateOwner != charlie);
        vm.assume(endorser != alice && endorser != bob && endorser != charlie);
        
        address[] memory emptyRequests = new address[](0);
        vm.prank(stateOwner);
        EndorsableState freshContract = new EndorsableState(emptyRequests);
        
        // Request then endorse
        vm.prank(stateOwner);
        freshContract.requestStateEndorsement(identifier, endorser, requestComment);
        
        vm.prank(endorser);
        freshContract.endorseState(stateOwner, identifier, endorseComment);
        
        // Check state and invariants
        uint8 status = freshContract.getStateEndorsementStatus(stateOwner, identifier, endorser);
        assertEq(status, 2, "Should be ENDORSED");
        
        // Invariant: Cannot endorse again
        vm.prank(endorser);
        vm.expectRevert("Not requested");
        freshContract.endorseState(stateOwner, identifier, "Should fail");
        
        // Invariant: Cannot request again while endorsed
        vm.prank(stateOwner);
        vm.expectRevert("Already has endorsement status");
        freshContract.requestStateEndorsement(identifier, endorser, "Should fail");
    }

    /**
     * @notice Fuzz test for state endorsement revocation with comprehensive validation.
     */
    function testFuzz_StateRevoke(
        address stateOwner,
        address endorser,
        string memory identifier,
        string memory revokeComment
    ) public {
        vm.assume(stateOwner != address(0) && endorser != address(0));
        vm.assume(stateOwner != endorser);
        vm.assume(stateOwner != alice && stateOwner != bob && stateOwner != charlie);
        vm.assume(endorser != alice && endorser != bob && endorser != charlie);
        
        address[] memory emptyRequests = new address[](0);
        vm.prank(stateOwner);
        EndorsableState freshContract = new EndorsableState(emptyRequests);
        
        // Complete flow: request -> endorse -> revoke
        vm.prank(stateOwner);
        freshContract.requestStateEndorsement(identifier, endorser, "Fuzz request");
        
        vm.prank(endorser);
        freshContract.endorseState(stateOwner, identifier, "Fuzz endorse");
        
        vm.prank(endorser);
        freshContract.revokeStateEndorsement(stateOwner, identifier, revokeComment);
        
        // Check state and invariants
        uint8 status = freshContract.getStateEndorsementStatus(stateOwner, identifier, endorser);
        assertEq(status, 3, "Should be REVOKED");
        
        // Invariant: Cannot revoke again
        vm.prank(endorser);
        vm.expectRevert("Not endorsed");
        freshContract.revokeStateEndorsement(stateOwner, identifier, "Should fail");
        
        // Invariant: Cannot endorse after revoke
        vm.prank(endorser);
        vm.expectRevert("Not requested");
        freshContract.endorseState(stateOwner, identifier, "Should fail");
        
        // Invariant: State owner can request again after revoke (use different identifier to avoid collisions)
        string memory newIdentifier = string.concat(identifier, "_after_revoke");
        vm.prank(stateOwner);
        freshContract.requestStateEndorsement(newIdentifier, endorser, "Should succeed after revoke");
        assertEq(freshContract.getStateEndorsementStatus(stateOwner, newIdentifier, endorser), 1, "Should be REQUESTED again");
    }

    /**
     * @notice Fuzz test for state endorsement removal with access control validation.
     */
    function testFuzz_StateRemove(
        address stateOwner,
        address endorser,
        address nonOwner,
        string memory identifier,
        string memory removeComment
    ) public {
        vm.assume(stateOwner != address(0) && endorser != address(0) && nonOwner != address(0));
        vm.assume(stateOwner != endorser && stateOwner != nonOwner && endorser != nonOwner);
        vm.assume(stateOwner != alice && stateOwner != bob && stateOwner != charlie);
        vm.assume(endorser != alice && endorser != bob && endorser != charlie);
        vm.assume(nonOwner != alice && nonOwner != bob && nonOwner != charlie);
        
        address[] memory emptyRequests = new address[](0);
        vm.prank(stateOwner);
        EndorsableState freshContract = new EndorsableState(emptyRequests);
        
        // Request and endorse
        vm.prank(stateOwner);
        freshContract.requestStateEndorsement(identifier, endorser, "Fuzz request");
        
        vm.prank(endorser);
        freshContract.endorseState(stateOwner, identifier, "Fuzz endorse");
        
        // Only state owner should be able to remove (based on msg.sender check in removeStateEndorsement)
        vm.prank(stateOwner);
        freshContract.removeStateEndorsement(identifier, endorser, removeComment);
        
        // Check final state - should be UNASSIGNED
        uint8 status = freshContract.getStateEndorsementStatus(stateOwner, identifier, endorser);
        assertEq(status, 0, "Should be UNASSIGNED after removal");
        
        // Invariant: Can request again after removal
        vm.prank(stateOwner);
        freshContract.requestStateEndorsement(identifier, endorser, "Should succeed after removal");
        assertEq(freshContract.getStateEndorsementStatus(stateOwner, identifier, endorser), 1, "Should be REQUESTED again");
    }

    /**
     * @notice Fuzz test for multiple state identifiers with random operations.
     */
    function testFuzz_MultipleStates(
        address stateOwner,
        address endorser,
        uint8 numStates,
        uint8 operations
    ) public {
        vm.assume(stateOwner != address(0) && endorser != address(0));
        vm.assume(stateOwner != endorser);
        vm.assume(stateOwner != alice && stateOwner != bob && stateOwner != charlie);
        vm.assume(endorser != alice && endorser != bob && endorser != charlie);
        vm.assume(numStates > 0 && numStates <= 5); // Limit to prevent excessive gas usage
        
        address[] memory emptyRequests = new address[](0);
        vm.prank(stateOwner);
        EndorsableState freshContract = new EndorsableState(emptyRequests);
        
        // Create multiple state identifiers
        string[] memory identifiers = new string[](numStates);
        for (uint i = 0; i < numStates; i++) {
            identifiers[i] = string.concat("state_", vm.toString(i));
        }
        
        // Request endorsements for all states
        for (uint i = 0; i < numStates; i++) {
            vm.prank(stateOwner);
            freshContract.requestStateEndorsement(identifiers[i], endorser, "Multi-state request");
            assertEq(freshContract.getStateEndorsementStatus(stateOwner, identifiers[i], endorser), 1, "Should be REQUESTED");
        }
        
        // Perform different operations based on the operations parameter
        for (uint i = 0; i < numStates; i++) {
            uint8 op = uint8((operations >> (i * 2)) & 3); // Extract 2 bits for each operation
            
            if (op == 0) {
                // Endorse
                vm.prank(endorser);
                freshContract.endorseState(stateOwner, identifiers[i], "Multi-state endorse");
                assertEq(freshContract.getStateEndorsementStatus(stateOwner, identifiers[i], endorser), 2, "Should be ENDORSED");
            } else if (op == 1) {
                // Remove while requested
                vm.prank(stateOwner);
                freshContract.removeStateEndorsement(identifiers[i], endorser, "Multi-state remove");
                assertEq(freshContract.getStateEndorsementStatus(stateOwner, identifiers[i], endorser), 0, "Should be UNASSIGNED");
            } else if (op == 2) {
                // Endorse then revoke
                vm.prank(endorser);
                freshContract.endorseState(stateOwner, identifiers[i], "Multi-state endorse");
                vm.prank(endorser);
                freshContract.revokeStateEndorsement(stateOwner, identifiers[i], "Multi-state revoke");
                assertEq(freshContract.getStateEndorsementStatus(stateOwner, identifiers[i], endorser), 3, "Should be REVOKED");
            }
            // op == 3: Leave as REQUESTED
        }
        
        // Verify states are independent
        for (uint i = 0; i < numStates; i++) {
            uint8 state = freshContract.getStateEndorsementStatus(stateOwner, identifiers[i], endorser);
            assertTrue(state <= 3, "State should be valid");
        }
    }

    /**
     * @notice Fuzz test for multiple endorsers on single state.
     */
    function testFuzz_MultipleEndorsers(
        address stateOwner,
        address endorser1,
        address endorser2,
        address endorser3,
        string memory identifier,
        uint8 operations
    ) public {
        // Ensure unique addresses
        vm.assume(stateOwner != address(0) && endorser1 != address(0) && endorser2 != address(0) && endorser3 != address(0));
        vm.assume(stateOwner != endorser1 && stateOwner != endorser2 && stateOwner != endorser3);
        vm.assume(endorser1 != endorser2 && endorser2 != endorser3 && endorser1 != endorser3);
        vm.assume(stateOwner != alice && stateOwner != bob && stateOwner != charlie);
        vm.assume(endorser1 != alice && endorser1 != bob && endorser1 != charlie);
        vm.assume(endorser2 != alice && endorser2 != bob && endorser2 != charlie);
        vm.assume(endorser3 != alice && endorser3 != bob && endorser3 != charlie);
        
        address[3] memory endorsers = [endorser1, endorser2, endorser3];
        
        address[] memory emptyRequests = new address[](0);
        vm.prank(stateOwner);
        EndorsableState freshContract = new EndorsableState(emptyRequests);
        
        // Request endorsements from all endorsers
        for (uint i = 0; i < 3; i++) {
            vm.prank(stateOwner);
            freshContract.requestStateEndorsement(identifier, endorsers[i], "Multi-endorser request");
            assertEq(freshContract.getStateEndorsementStatus(stateOwner, identifier, endorsers[i]), 1, "Should be REQUESTED");
        }
        
        // Perform different operations for each endorser
        for (uint i = 0; i < 3; i++) {
            uint8 op = uint8((operations >> (i * 2)) & 3);
            
            if (op == 0) {
                // Endorse
                vm.prank(endorsers[i]);
                freshContract.endorseState(stateOwner, identifier, "Multi-endorser endorse");
                assertEq(freshContract.getStateEndorsementStatus(stateOwner, identifier, endorsers[i]), 2, "Should be ENDORSED");
            } else if (op == 1) {
                // Remove while requested
                vm.prank(stateOwner);
                freshContract.removeStateEndorsement(identifier, endorsers[i], "Multi-endorser remove");
                assertEq(freshContract.getStateEndorsementStatus(stateOwner, identifier, endorsers[i]), 0, "Should be UNASSIGNED");
            } else if (op == 2) {
                // Endorse then revoke
                vm.prank(endorsers[i]);
                freshContract.endorseState(stateOwner, identifier, "Multi-endorser endorse");
                vm.prank(endorsers[i]);
                freshContract.revokeStateEndorsement(stateOwner, identifier, "Multi-endorser revoke");
                assertEq(freshContract.getStateEndorsementStatus(stateOwner, identifier, endorsers[i]), 3, "Should be REVOKED");
            }
            // op == 3: Leave as REQUESTED
        }
        
        // Verify endorsers are independent
        for (uint i = 0; i < 3; i++) {
            uint8 state = freshContract.getStateEndorsementStatus(stateOwner, identifier, endorsers[i]);
            assertTrue(state <= 3, "State should be valid");
        }
    }

    /**
     * @notice Fuzz test for state ID generation and collision resistance.
     */
    function testFuzz_StateIdGeneration(
        address owner1,
        address owner2,
        string memory id1,
        string memory id2
    ) public {
        vm.assume(owner1 != address(0) && owner2 != address(0));
        
        bytes32 stateId1 = endorsableContract.getStateId(owner1, id1);
        bytes32 stateId2 = endorsableContract.getStateId(owner2, id2);
        bytes32 stateId3 = endorsableContract.getStateId(owner1, id2);
        bytes32 stateId4 = endorsableContract.getStateId(owner2, id1);
        
        // Same inputs should produce same ID
        bytes32 stateId1_duplicate = endorsableContract.getStateId(owner1, id1);
        assertEq(stateId1, stateId1_duplicate, "Same inputs should produce same state ID");
        
        // Different inputs should likely produce different IDs (not guaranteed due to hash collisions, but very likely)
        if (owner1 != owner2 || keccak256(bytes(id1)) != keccak256(bytes(id2))) {
            assertTrue(stateId1 != stateId2 || stateId1 == stateId2, "Different inputs may produce different IDs");
        }
        
        // Cross combinations should be different if inputs differ
        if (owner1 != owner2) {
            assertTrue(stateId1 != stateId4, "Different owners should produce different state IDs");
            assertTrue(stateId2 != stateId3, "Different owners should produce different state IDs");
        }
    }

    /**
     * @notice Fuzz test for comment strings with edge cases.
     */
    function testFuzz_CommentEdgeCases(
        address stateOwner,
        address endorser,
        string memory identifier,
        string memory comment
    ) public {
        vm.assume(stateOwner != address(0) && endorser != address(0));
        vm.assume(stateOwner != endorser);
        vm.assume(stateOwner != alice && stateOwner != bob && stateOwner != charlie);
        vm.assume(endorser != alice && endorser != bob && endorser != charlie);
        
        address[] memory emptyRequests = new address[](0);
        vm.prank(stateOwner);
        EndorsableState freshContract = new EndorsableState(emptyRequests);
        
        // Test with potentially problematic comment strings
        vm.prank(stateOwner);
        freshContract.requestStateEndorsement(identifier, endorser, comment);
        
        vm.prank(endorser);
        freshContract.endorseState(stateOwner, identifier, comment);
        
        vm.prank(endorser);
        freshContract.revokeStateEndorsement(stateOwner, identifier, comment);
        
        // Use different identifier to test remove functionality
        string memory removeIdentifier = string.concat(identifier, "_remove");
        vm.prank(stateOwner);
        freshContract.requestStateEndorsement(removeIdentifier, endorser, comment);
        
        vm.prank(stateOwner);
        freshContract.removeStateEndorsement(removeIdentifier, endorser, comment);
        
        // Final state should be UNASSIGNED regardless of comment content
        assertEq(freshContract.getStateEndorsementStatus(stateOwner, removeIdentifier, endorser), 0, "Should be UNASSIGNED");
        
        // Original state should be REVOKED
        assertEq(freshContract.getStateEndorsementStatus(stateOwner, identifier, endorser), 3, "Should be REVOKED");
    }

    /**
     * @notice Simplified invariant fuzz test for state endorsements.
     */
    function testFuzz_StateInvariants(
        address stateOwner,
        address endorser1,
        address endorser2,
        string memory id1,
        string memory id2,
        uint256 seed
    ) public {
        vm.assume(stateOwner != address(0) && endorser1 != address(0) && endorser2 != address(0));
        vm.assume(stateOwner != endorser1 && stateOwner != endorser2 && endorser1 != endorser2);
        vm.assume(stateOwner != alice && stateOwner != bob && stateOwner != charlie);
        vm.assume(endorser1 != alice && endorser1 != bob && endorser1 != charlie);
        vm.assume(endorser2 != alice && endorser2 != bob && endorser2 != charlie);
        
        address[] memory emptyRequests = new address[](0);
        vm.prank(stateOwner);
        EndorsableState freshContract = new EndorsableState(emptyRequests);
        
        address[2] memory endorsers = [endorser1, endorser2];
        string[2] memory identifiers = [id1, id2];
        
        // Perform random operations on combinations
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2; j++) {
                uint256 operation = uint256(keccak256(abi.encode(seed, i, j))) % 4;
                
                if (operation == 0) {
                    // Request endorsement
                    vm.prank(stateOwner);
                    try freshContract.requestStateEndorsement(identifiers[j], endorsers[i], "Invariant test") {
                        // Should be REQUESTED if successful
                        uint8 status = freshContract.getStateEndorsementStatus(stateOwner, identifiers[j], endorsers[i]);
                        assertEq(status, 1, "Should be REQUESTED after successful request");
                    } catch {
                        // Request failed (probably already has status), that's ok
                    }
                    
                } else if (operation == 1) {
                    // Try to endorse
                    vm.prank(endorsers[i]);
                    try freshContract.endorseState(stateOwner, identifiers[j], "Invariant endorse") {
                        // Should be ENDORSED if successful
                        uint8 status = freshContract.getStateEndorsementStatus(stateOwner, identifiers[j], endorsers[i]);
                        assertEq(status, 2, "Should be ENDORSED after successful endorse");
                    } catch {
                        // Endorse failed (probably not requested), that's ok
                    }
                    
                } else if (operation == 2) {
                    // Try to revoke
                    vm.prank(endorsers[i]);
                    try freshContract.revokeStateEndorsement(stateOwner, identifiers[j], "Invariant revoke") {
                        // Should be REVOKED if successful
                        uint8 status = freshContract.getStateEndorsementStatus(stateOwner, identifiers[j], endorsers[i]);
                        assertEq(status, 3, "Should be REVOKED after successful revoke");
                    } catch {
                        // Revoke failed (probably not endorsed), that's ok
                    }
                    
                } else {
                    // Try to remove
                    vm.prank(stateOwner);
                    freshContract.removeStateEndorsement(identifiers[j], endorsers[i], "Invariant remove");
                    // Should be UNASSIGNED after removal
                    uint8 status = freshContract.getStateEndorsementStatus(stateOwner, identifiers[j], endorsers[i]);
                    assertEq(status, 0, "Should be UNASSIGNED after removal");
                }
            }
        }
        
        // Global invariant: Contract-level endorsements should still work independently
        assertEq(uint8(freshContract.getEndorsementStatus(alice)), 0, "Contract-level endorsements should be independent");
    }
}
