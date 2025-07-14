// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/forge-std/src/Test.sol";

// Import the Endorsable contract (adjust path as necessary).
import "../src/Endorsable.sol";

/**
 * @title EndorsableTest
 * @dev A Foundry test contract for the Endorsable contract.
 */
contract EndorsableTest is Test {
    Endorsable endorsable;

    // Predefined addresses for testing.
    address owner = address(0xAB);
    address testUser = address(0xCD);
    address testUser2 = address(0xEF);

    address initRequest = address(0x12);
    address initRequest2 = address(0x34);

    address[] initialRequests = [initRequest, initRequest2];

    // Events from the Endorsable contract. Re-declare here for `vm.expectEmit`.
    event Endorsed(address indexed endorser, string comment);
    event EndorsementRequested(address indexed addr, string comment);
    event EndorsementRevoked(address indexed endorser, string comment);
    event EndorsementRemoved(address indexed addr, string comment);

    /**
     * @notice Deploy a fresh Endorsable contract before each test.
     */
    function setUp() public {
        // Make `owner` the one who deploys the contract to ensure Ownable logic is set properly.
        vm.prank(owner);
        endorsable = new Endorsable(initialRequests);
    }

    // -----------------------------------------------
    // Basic Unit Tests
    // -----------------------------------------------

    /**
     * @notice Test that the constructor sets the initial requests correctly.
     */
    function testConstructorSetsInitialRequests() public {
        assertEq(
            uint256(endorsable.getEndorsementStatus(initRequest)),
            uint256(Endorsable.State.REQUESTED),
            "initRequest should be in REQUESTED state"
        );
        assertEq(
            uint256(endorsable.getEndorsementStatus(initRequest2)),
            uint256(Endorsable.State.REQUESTED),
            "initRequert2 should be in REQUESTED state"
        );
    }

    /**
     * @notice Test that only the owner can request endorsements.
     */
    function testCannotRequestEndorsementIfNotOwner() public {
        // Attempt to request endorsement from a non-owner address.
        vm.prank(testUser);
        vm.expectRevert();
        /// @dev this could be improved with a more specific revert message:
        // vm.expectRevert(
        //     abi.encodeWithSelector(
        //         OwnableUnauthorizedAccount.selector,
        //         testUser
        //     )
        // );
        endorsable.requestEndorsement(testUser2, "Request from non-owner");
    }

    /**
     * @notice Test that the owner can request endorsements, setting the state to REQUESTED.
     */
    function testRequestEndorsement() public {
        // Owner requests endorsement for `testUser`
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit EndorsementRequested(testUser, "Requesting endorsement");
        endorsable.requestEndorsement(testUser, "Requesting endorsement");

        // Confirm the state is REQUESTED
        Endorsable.State status = endorsable.getEndorsementStatus(testUser);
        assertEq(uint8(status), uint8(Endorsable.State.REQUESTED), "Expected state: REQUESTED");
    }

    /**
     * @notice Test that requesting endorsement fails if already in ENDORSED state.
     */
    function testRequestEndorsementFailIfEndorsed() public {
        // First, request endorsement from owner side
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Requesting endorsement");

        // Then, `testUser` endorses.
        vm.prank(testUser);
        endorsable.endorse("Endorsing after request");

        // Attempt to request endorsement again -> revert
        vm.prank(owner);
        vm.expectRevert(bytes("Already endorsed."));
        endorsable.requestEndorsement(testUser, "Duplicate request");
    }

    /**
     * @notice Test that requesting endorsement fails if already in REQUESTED state.
     */
    function testRequestEndorsementFailIfRequested() public {
        // Owner requests endorsement
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Requesting endorsement");

        // Attempt to request endorsement again
        vm.prank(owner);
        vm.expectRevert(bytes("Already requested."));
        endorsable.requestEndorsement(testUser, "Duplicate request");
    }

    /**
     * @notice Test that endorsing works only after a user has a REQUESTED state.
     */
    function testEndorseSuccessAfterRequest() public {
        // Owner requests endorsement for `testUser`
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Requesting endorsement");

        // `testUser` endorses
        vm.prank(testUser);
        vm.expectEmit(true, false, false, true);
        emit Endorsed(testUser, "Endorsing now");
        endorsable.endorse("Endorsing now");

        // Confirm the state is ENDORSED
        Endorsable.State status = endorsable.getEndorsementStatus(testUser);
        assertEq(uint8(status), uint8(Endorsable.State.ENDORSED), "Expected state: ENDORSED");
    }

    /**
     * @notice Test that endorsing reverts if user has not been REQUESTED.
     */
    function testEndorseRevertIfNotRequested() public {
        // `testUser` tries to endorse with no prior request
        vm.prank(testUser);
        vm.expectRevert(bytes("Endorsement not requested."));
        endorsable.endorse("Invalid endorsement attempt");
    }

    /**
     * @notice Test that endorsement can be revoked if user is currently ENDORSED.
     */
    function testRevokeEndorsement() public {
        // Owner requests endorsement
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Requesting endorsement");

        // `testUser` endorses
        vm.prank(testUser);
        endorsable.endorse("I endorse!");

        // `testUser` revokes
        vm.prank(testUser);
        vm.expectEmit(true, false, false, true);
        emit EndorsementRevoked(testUser, "Revoking endorsement");
        endorsable.revokeEndorsement("Revoking endorsement");

        // Confirm the state is REVOKED
        Endorsable.State status = endorsable.getEndorsementStatus(testUser);
        assertEq(uint8(status), uint8(Endorsable.State.REVOKED), "Expected state: REVOKED");
    }

    /**
     * @notice Test that revoking reverts if state is not ENDORSED.
     */
    function testRevokeEndorsementRevertsIfNotEndorsed() public {
        // Attempting to revoke from an address with default state (UNASSIGNED)
        vm.prank(testUser);
        vm.expectRevert(bytes("Not endorsed, already revoked, or removed."));
        endorsable.revokeEndorsement("Should fail");
    }

    /**
     * @notice Test that removing an endorsement is only callable by the owner.
     */
    function testRemoveEndorsementRevertsIfNotOwner() public {
        vm.prank(testUser);
        vm.expectRevert();
        /// @dev this could be improved with a more specific revert message:
        // vm.expectRevert(
        //     abi.encodeWithSelector(
        //         OwnableUnauthorizedAccount.selector,
        //         testUser
        //     )
        // );
        endorsable.removeEndorsement(testUser2, "Invalid remove call");
    }

    /**
     * @notice Test that removing an endorsement sets state to REMOVED if previously in ENDORSED or REQUESTED.
     */
    function testRemoveEndorsementFromEndorsed() public {
        // request => endorse => remove

        // request
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Requesting endorsement");
        // endorse
        vm.prank(testUser);
        endorsable.endorse("Endorsing now");

        // remove
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit EndorsementRemoved(testUser, "Removing endorsement");
        endorsable.removeEndorsement(testUser, "Removing endorsement");

        // Confirm the state
        Endorsable.State status = endorsable.getEndorsementStatus(testUser);
        assertEq(uint8(status), uint8(Endorsable.State.REMOVED), "Expected state: REMOVED");
    }

    /**
     * @notice Test that removing an endorsement from a requested address sets state to REMOVED.
     */
    function testRemoveEndorsementFromRequested() public {
        // request => remove

        // request
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Requesting endorsement");

        // remove
        vm.prank(owner);
        endorsable.removeEndorsement(testUser, "Removing un-endorsed request");

        // Confirm the state
        Endorsable.State status = endorsable.getEndorsementStatus(testUser);
        assertEq(uint8(status), uint8(Endorsable.State.REMOVED), "Expected state: REMOVED");
    }

    /**
     * @notice Test that removing an endorsement reverts if not in ENDORSED or REQUESTED state.
     */
    function testRemoveEndorsementRevertsIfNotEndorsedOrRequested() public {
        // The default state is UNASSIGNED, so it should revert
        vm.prank(owner);
        vm.expectRevert(bytes("Not endorsed or requested."));
        endorsable.removeEndorsement(testUser, "Should revert");
    }

    // -----------------------------------------------
    // Enhanced Fuzz Tests
    // -----------------------------------------------

    /**
     * @notice Enhanced fuzz test for requesting endorsements with edge cases.
     */
    function testFuzz_RequestEndorsement(address randomAddr, string memory comment) public {
        // Skip addresses that are pre-initialized in the constructor
        vm.assume(randomAddr != initRequest && randomAddr != initRequest2);
        // Allow address(0) to test edge case

        // Only the owner can request
        vm.prank(owner);

        vm.expectEmit(true, false, false, true);
        emit EndorsementRequested(randomAddr, comment);
        endorsable.requestEndorsement(randomAddr, comment);

        // Check state and invariants
        Endorsable.State status = endorsable.getEndorsementStatus(randomAddr);
        assertEq(uint8(status), uint8(Endorsable.State.REQUESTED), "Should be REQUESTED");

        // Invariant: Cannot request again
        vm.prank(owner);
        vm.expectRevert("Already requested.");
        endorsable.requestEndorsement(randomAddr, "Should fail");
    }

    /**
     * @notice Enhanced fuzz test for endorsing with state validation.
     */
    function testFuzz_EndorseAfterRequest(address randomAddr, string memory comment) public {
        // Skip addresses that are pre-initialized in the constructor
        vm.assume(randomAddr != initRequest && randomAddr != initRequest2);

        // 1) Owner requests endorsement for randomAddr
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, "Fuzz request");

        // 2) randomAddr endorses
        vm.prank(randomAddr);
        endorsable.endorse(comment);

        // Check final state and invariants
        Endorsable.State status = endorsable.getEndorsementStatus(randomAddr);
        assertEq(uint8(status), uint8(Endorsable.State.ENDORSED), "Should be ENDORSED");

        // Invariant: Cannot endorse again
        vm.prank(randomAddr);
        vm.expectRevert("Endorsement not requested.");
        endorsable.endorse("Should fail");

        // Invariant: Owner cannot request again while endorsed
        vm.prank(owner);
        vm.expectRevert("Already endorsed.");
        endorsable.requestEndorsement(randomAddr, "Should fail");
    }

    /**
     * @notice Enhanced fuzz test for revoking with comprehensive validation.
     */
    function testFuzz_RevokeEndorsement(address randomAddr, string memory comment) public {
        // Skip addresses that are pre-initialized in the constructor
        vm.assume(randomAddr != initRequest && randomAddr != initRequest2);

        // 1) Request
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, "Requesting...");

        // 2) Endorse
        vm.prank(randomAddr);
        endorsable.endorse("Endorsing...");

        // 3) Revoke
        vm.prank(randomAddr);
        endorsable.revokeEndorsement(comment);

        // Check final state and invariants
        Endorsable.State status = endorsable.getEndorsementStatus(randomAddr);
        assertEq(uint8(status), uint8(Endorsable.State.REVOKED), "Should be REVOKED");

        // Invariant: Cannot revoke again
        vm.prank(randomAddr);
        vm.expectRevert("Not endorsed, already revoked, or removed.");
        endorsable.revokeEndorsement("Should fail");

        // Invariant: Cannot endorse after revoke
        vm.prank(randomAddr);
        vm.expectRevert("Endorsement not requested.");
        endorsable.endorse("Should fail");

        // Invariant: Owner can request again after revoke
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, "Should succeed after revoke");
        assertEq(
            uint8(endorsable.getEndorsementStatus(randomAddr)),
            uint8(Endorsable.State.REQUESTED),
            "Should be REQUESTED again"
        );
    }

    /**
     * @notice Enhanced fuzz test for removing with access control validation.
     */
    function testFuzz_RemoveEndorsement(address randomAddr, string memory comment) public {
        // Skip addresses that are pre-initialized in the constructor
        vm.assume(randomAddr != initRequest && randomAddr != initRequest2);

        // 1) Request
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, "Requesting for test...");

        // 2) Endorse
        vm.prank(randomAddr);
        endorsable.endorse("Endorsing in fuzz test...");

        // 3) Verify non-owner cannot remove
        vm.prank(randomAddr);
        vm.expectRevert();
        endorsable.removeEndorsement(randomAddr, "Should fail - not owner");

        // 4) Owner removes
        vm.prank(owner);
        endorsable.removeEndorsement(randomAddr, comment);

        // Check final state and invariants
        Endorsable.State status = endorsable.getEndorsementStatus(randomAddr);
        assertEq(uint8(status), uint8(Endorsable.State.REMOVED), "Should be REMOVED");

        // Invariant: Cannot remove again
        vm.prank(owner);
        vm.expectRevert("Not endorsed or requested.");
        endorsable.removeEndorsement(randomAddr, "Should fail");

        // Invariant: Cannot endorse after removal
        vm.prank(randomAddr);
        vm.expectRevert("Endorsement not requested.");
        endorsable.endorse("Should fail");

        // Invariant: Owner can request again after removal
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, "Should succeed after removal");
        assertEq(
            uint8(endorsable.getEndorsementStatus(randomAddr)),
            uint8(Endorsable.State.REQUESTED),
            "Should be REQUESTED again"
        );
    }

    /**
     * @notice Fuzz test for state transitions with random sequences.
     */
    function testFuzz_StateTransitions(address randomAddr, uint8 sequence) public {
        vm.assume(randomAddr != initRequest && randomAddr != initRequest2);
        vm.assume(randomAddr != address(0));

        // Use sequence to determine which operations to perform
        // This creates different state transition paths
        uint8 operation = sequence % 4;

        // Always start with request
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, "Initial request");
        assertEq(
            uint8(endorsable.getEndorsementStatus(randomAddr)), uint8(Endorsable.State.REQUESTED), "Should be REQUESTED"
        );

        if (operation == 0) {
            // Path: Request -> Remove
            vm.prank(owner);
            endorsable.removeEndorsement(randomAddr, "Remove from requested");
            assertEq(
                uint8(endorsable.getEndorsementStatus(randomAddr)), uint8(Endorsable.State.REMOVED), "Should be REMOVED"
            );
        } else if (operation == 1) {
            // Path: Request -> Endorse -> Remove
            vm.prank(randomAddr);
            endorsable.endorse("Endorsing");
            vm.prank(owner);
            endorsable.removeEndorsement(randomAddr, "Remove from endorsed");
            assertEq(
                uint8(endorsable.getEndorsementStatus(randomAddr)), uint8(Endorsable.State.REMOVED), "Should be REMOVED"
            );
        } else if (operation == 2) {
            // Path: Request -> Endorse -> Revoke
            vm.prank(randomAddr);
            endorsable.endorse("Endorsing");
            vm.prank(randomAddr);
            endorsable.revokeEndorsement("Revoking");
            assertEq(
                uint8(endorsable.getEndorsementStatus(randomAddr)), uint8(Endorsable.State.REVOKED), "Should be REVOKED"
            );
        } else {
            // Path: Request -> Endorse -> Revoke -> Request again
            vm.prank(randomAddr);
            endorsable.endorse("Endorsing");
            vm.prank(randomAddr);
            endorsable.revokeEndorsement("Revoking");
            vm.prank(owner);
            endorsable.requestEndorsement(randomAddr, "Request after revoke");
            assertEq(
                uint8(endorsable.getEndorsementStatus(randomAddr)),
                uint8(Endorsable.State.REQUESTED),
                "Should be REQUESTED again"
            );
        }
    }

    /**
     * @notice Fuzz test for multiple addresses with random operations.
     */
    function testFuzz_MultipleAddresses(address addr1, address addr2, address addr3, uint8 operations) public {
        // Ensure unique addresses
        vm.assume(addr1 != addr2 && addr2 != addr3 && addr1 != addr3);
        vm.assume(addr1 != initRequest && addr1 != initRequest2);
        vm.assume(addr2 != initRequest && addr2 != initRequest2);
        vm.assume(addr3 != initRequest && addr3 != initRequest2);
        vm.assume(addr1 != address(0) && addr2 != address(0) && addr3 != address(0));

        address[3] memory addrs = [addr1, addr2, addr3];

        // Request endorsements for all addresses
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(owner);
            endorsable.requestEndorsement(addrs[i], "Multi request");
            assertEq(
                uint8(endorsable.getEndorsementStatus(addrs[i])),
                uint8(Endorsable.State.REQUESTED),
                "Should be REQUESTED"
            );
        }

        // Perform different operations based on the operations parameter
        for (uint256 i = 0; i < 3; i++) {
            uint8 op = uint8((operations >> (i * 2)) & 3); // Extract 2 bits for each operation

            if (op == 0) {
                // Endorse
                vm.prank(addrs[i]);
                endorsable.endorse("Multi endorse");
                assertEq(
                    uint8(endorsable.getEndorsementStatus(addrs[i])),
                    uint8(Endorsable.State.ENDORSED),
                    "Should be ENDORSED"
                );
            } else if (op == 1) {
                // Remove while requested
                vm.prank(owner);
                endorsable.removeEndorsement(addrs[i], "Multi remove");
                assertEq(
                    uint8(endorsable.getEndorsementStatus(addrs[i])),
                    uint8(Endorsable.State.REMOVED),
                    "Should be REMOVED"
                );
            } else if (op == 2) {
                // Endorse then revoke
                vm.prank(addrs[i]);
                endorsable.endorse("Multi endorse");
                vm.prank(addrs[i]);
                endorsable.revokeEndorsement("Multi revoke");
                assertEq(
                    uint8(endorsable.getEndorsementStatus(addrs[i])),
                    uint8(Endorsable.State.REVOKED),
                    "Should be REVOKED"
                );
            }
            // op == 3: Leave as REQUESTED
        }

        // Verify states are independent - no address should affect another
        for (uint256 i = 0; i < 3; i++) {
            Endorsable.State state = endorsable.getEndorsementStatus(addrs[i]);
            assertTrue(uint8(state) <= 4, "State should be valid");
        }
    }

    /**
     * @notice Fuzz test for comment strings with edge cases.
     */
    function testFuzz_CommentEdgeCases(address randomAddr, string memory comment) public {
        vm.assume(randomAddr != initRequest && randomAddr != initRequest2);
        vm.assume(randomAddr != address(0));

        // Test with potentially problematic comment strings
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, comment);

        vm.prank(randomAddr);
        endorsable.endorse(comment);

        vm.prank(randomAddr);
        endorsable.revokeEndorsement(comment);

        // Request again to test remove
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, comment);

        vm.prank(owner);
        endorsable.removeEndorsement(randomAddr, comment);

        // Final state should be REMOVED regardless of comment content
        assertEq(
            uint8(endorsable.getEndorsementStatus(randomAddr)), uint8(Endorsable.State.REMOVED), "Should be REMOVED"
        );
    }

    /**
     * @notice Fuzz test for access control violations.
     */
    function testFuzz_AccessControl(address randomAddr, address nonOwner) public {
        vm.assume(randomAddr != initRequest && randomAddr != initRequest2);
        vm.assume(randomAddr != address(0));
        vm.assume(nonOwner != owner);
        vm.assume(nonOwner != address(0));

        // Non-owner cannot request
        vm.prank(nonOwner);
        vm.expectRevert();
        endorsable.requestEndorsement(randomAddr, "Should fail");

        // Owner requests
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, "Valid request");

        // randomAddr endorses
        vm.prank(randomAddr);
        endorsable.endorse("Valid endorse");

        // Non-owner cannot remove
        vm.prank(nonOwner);
        vm.expectRevert();
        endorsable.removeEndorsement(randomAddr, "Should fail");

        // But the endorsed address can revoke their own endorsement
        vm.prank(randomAddr);
        endorsable.revokeEndorsement("Valid revoke");

        // Verify final state
        assertEq(
            uint8(endorsable.getEndorsementStatus(randomAddr)), uint8(Endorsable.State.REVOKED), "Should be REVOKED"
        );
    }

    /**
     * @notice Invariant fuzz test - contract should maintain consistent state.
     */
    function testFuzz_Invariants(address[] memory addresses, uint256 seed) public {
        // Limit array size to prevent excessive gas usage
        vm.assume(addresses.length <= 10);
        vm.assume(addresses.length > 0);

        for (uint256 i = 0; i < addresses.length; i++) {
            vm.assume(addresses[i] != initRequest && addresses[i] != initRequest2);
            vm.assume(addresses[i] != address(0));

            // Ensure no duplicates in the array
            for (uint256 j = i + 1; j < addresses.length; j++) {
                vm.assume(addresses[i] != addresses[j]);
            }
        }

        // Perform random operations on each address
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 operation = uint256(keccak256(abi.encode(seed, i))) % 4;

            if (operation == 0) {
                // Just request
                vm.prank(owner);
                endorsable.requestEndorsement(addresses[i], "Invariant test");

                // Invariant: State should be REQUESTED
                assertEq(
                    uint8(endorsable.getEndorsementStatus(addresses[i])),
                    uint8(Endorsable.State.REQUESTED),
                    "Should be REQUESTED"
                );
            } else if (operation == 1) {
                // Request and endorse
                vm.prank(owner);
                endorsable.requestEndorsement(addresses[i], "Invariant test");
                vm.prank(addresses[i]);
                endorsable.endorse("Invariant endorse");

                // Invariant: State should be ENDORSED
                assertEq(
                    uint8(endorsable.getEndorsementStatus(addresses[i])),
                    uint8(Endorsable.State.ENDORSED),
                    "Should be ENDORSED"
                );
            } else if (operation == 2) {
                // Full cycle: request -> endorse -> revoke
                vm.prank(owner);
                endorsable.requestEndorsement(addresses[i], "Invariant test");
                vm.prank(addresses[i]);
                endorsable.endorse("Invariant endorse");
                vm.prank(addresses[i]);
                endorsable.revokeEndorsement("Invariant revoke");

                // Invariant: State should be REVOKED
                assertEq(
                    uint8(endorsable.getEndorsementStatus(addresses[i])),
                    uint8(Endorsable.State.REVOKED),
                    "Should be REVOKED"
                );
            } else {
                // Request and remove
                vm.prank(owner);
                endorsable.requestEndorsement(addresses[i], "Invariant test");
                vm.prank(owner);
                endorsable.removeEndorsement(addresses[i], "Invariant remove");

                // Invariant: State should be REMOVED
                assertEq(
                    uint8(endorsable.getEndorsementStatus(addresses[i])),
                    uint8(Endorsable.State.REMOVED),
                    "Should be REMOVED"
                );
            }
        }

        // Global invariant: initRequest and initRequest2 should still be REQUESTED
        assertEq(
            uint8(endorsable.getEndorsementStatus(initRequest)),
            uint8(Endorsable.State.REQUESTED),
            "initRequest should remain REQUESTED"
        );
        assertEq(
            uint8(endorsable.getEndorsementStatus(initRequest2)),
            uint8(Endorsable.State.REQUESTED),
            "initRequest2 should remain REQUESTED"
        );
    }

    // ================================
    // ADDITIONAL EDGE CASE TESTS
    // ================================

    /**
     * @notice Test requesting endorsement after a previous REMOVED state.
     */
    function testRequestEndorsementAfterRemoved() public {
        // Complete flow: request -> endorse -> remove -> request again
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Initial request");

        vm.prank(testUser);
        endorsable.endorse("Endorsing");

        vm.prank(owner);
        endorsable.removeEndorsement(testUser, "Removing");

        // Verify state is REMOVED
        assertEq(uint8(endorsable.getEndorsementStatus(testUser)), uint8(Endorsable.State.REMOVED), "Should be REMOVED");

        // Now request again - should be allowed (resets to REQUESTED)
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Request after removal");

        assertEq(
            uint8(endorsable.getEndorsementStatus(testUser)),
            uint8(Endorsable.State.REQUESTED),
            "Should be REQUESTED again"
        );
    }

    /**
     * @notice Test requesting endorsement after a previous REVOKED state.
     */
    function testRequestEndorsementAfterRevoked() public {
        // Complete flow: request -> endorse -> revoke -> request again
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Initial request");

        vm.prank(testUser);
        endorsable.endorse("Endorsing");

        vm.prank(testUser);
        endorsable.revokeEndorsement("Revoking");

        // Verify state is REVOKED
        assertEq(uint8(endorsable.getEndorsementStatus(testUser)), uint8(Endorsable.State.REVOKED), "Should be REVOKED");

        // Now request again - should be allowed (resets to REQUESTED)
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Request after revocation");

        assertEq(
            uint8(endorsable.getEndorsementStatus(testUser)),
            uint8(Endorsable.State.REQUESTED),
            "Should be REQUESTED again"
        );
    }

    /**
     * @notice Test that removing endorsement fails for REVOKED state.
     */
    function testRemoveEndorsementFailsForRevoked() public {
        // Complete flow: request -> endorse -> revoke
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Initial request");

        vm.prank(testUser);
        endorsable.endorse("Endorsing");

        vm.prank(testUser);
        endorsable.revokeEndorsement("Revoking");

        // Try to remove a REVOKED endorsement - should fail
        vm.prank(owner);
        vm.expectRevert(bytes("Not endorsed or requested."));
        endorsable.removeEndorsement(testUser, "Cannot remove revoked");
    }

    /**
     * @notice Test that removing endorsement fails for REMOVED state.
     */
    function testRemoveEndorsementFailsForRemoved() public {
        // Complete flow: request -> remove
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Initial request");

        vm.prank(owner);
        endorsable.removeEndorsement(testUser, "Removing");

        // Try to remove again - should fail
        vm.prank(owner);
        vm.expectRevert(bytes("Not endorsed or requested."));
        endorsable.removeEndorsement(testUser, "Cannot remove already removed");
    }

    /**
     * @notice Test constructor with empty initial requests array.
     */
    function testConstructorWithEmptyArray() public {
        address[] memory emptyArray = new address[](0);

        vm.prank(owner);
        Endorsable emptyEndorsable = new Endorsable(emptyArray);

        // Verify that testUser has default UNASSIGNED state
        assertEq(
            uint8(emptyEndorsable.getEndorsementStatus(testUser)),
            uint8(Endorsable.State.UNASSIGNED),
            "Should be UNASSIGNED"
        );
    }

    /**
     * @notice Test constructor with duplicate addresses in initial requests.
     */
    function testConstructorWithDuplicateAddresses() public {
        address[] memory duplicateArray = new address[](3);
        duplicateArray[0] = testUser;
        duplicateArray[1] = testUser2;
        duplicateArray[2] = testUser; // Duplicate

        vm.prank(owner);
        Endorsable duplicateEndorsable = new Endorsable(duplicateArray);

        // Both addresses should be REQUESTED (duplicate should be overwritten)
        assertEq(
            uint8(duplicateEndorsable.getEndorsementStatus(testUser)),
            uint8(Endorsable.State.REQUESTED),
            "testUser should be REQUESTED"
        );
        assertEq(
            uint8(duplicateEndorsable.getEndorsementStatus(testUser2)),
            uint8(Endorsable.State.REQUESTED),
            "testUser2 should be REQUESTED"
        );
    }

    /**
     * @notice Test constructor with address(0) in initial requests.
     */
    function testConstructorWithAddressZero() public {
        address[] memory zeroArray = new address[](2);
        zeroArray[0] = address(0);
        zeroArray[1] = testUser;

        vm.prank(owner);
        Endorsable zeroEndorsable = new Endorsable(zeroArray);

        // Both addresses should be REQUESTED
        assertEq(
            uint8(zeroEndorsable.getEndorsementStatus(address(0))),
            uint8(Endorsable.State.REQUESTED),
            "address(0) should be REQUESTED"
        );
        assertEq(
            uint8(zeroEndorsable.getEndorsementStatus(testUser)),
            uint8(Endorsable.State.REQUESTED),
            "testUser should be REQUESTED"
        );
    }

    /**
     * @notice Test all functions with empty comment strings.
     */
    function testEmptyCommentStrings() public {
        // Request with empty comment
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "");

        // Endorse with empty comment
        vm.prank(testUser);
        endorsable.endorse("");

        assertEq(
            uint8(endorsable.getEndorsementStatus(testUser)), uint8(Endorsable.State.ENDORSED), "Should be ENDORSED"
        );

        // Revoke with empty comment
        vm.prank(testUser);
        endorsable.revokeEndorsement("");

        assertEq(uint8(endorsable.getEndorsementStatus(testUser)), uint8(Endorsable.State.REVOKED), "Should be REVOKED");

        // Request again to test remove with empty comment
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "");

        // Remove with empty comment
        vm.prank(owner);
        endorsable.removeEndorsement(testUser, "");

        assertEq(uint8(endorsable.getEndorsementStatus(testUser)), uint8(Endorsable.State.REMOVED), "Should be REMOVED");
    }

    /**
     * @notice Test multiple simultaneous endorsements and operations.
     */
    function testMultipleSimultaneousOperations() public {
        // Request endorsements for multiple users
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Request 1");

        vm.prank(owner);
        endorsable.requestEndorsement(testUser2, "Request 2");

        // testUser endorses, testUser2 does not
        vm.prank(testUser);
        endorsable.endorse("Endorsing from testUser");

        // Verify independent states
        assertEq(
            uint8(endorsable.getEndorsementStatus(testUser)),
            uint8(Endorsable.State.ENDORSED),
            "testUser should be ENDORSED"
        );
        assertEq(
            uint8(endorsable.getEndorsementStatus(testUser2)),
            uint8(Endorsable.State.REQUESTED),
            "testUser2 should be REQUESTED"
        );

        // Remove testUser2's request, revoke testUser's endorsement
        vm.prank(owner);
        endorsable.removeEndorsement(testUser2, "Removing testUser2");

        vm.prank(testUser);
        endorsable.revokeEndorsement("Revoking testUser");

        // Verify final states
        assertEq(
            uint8(endorsable.getEndorsementStatus(testUser)),
            uint8(Endorsable.State.REVOKED),
            "testUser should be REVOKED"
        );
        assertEq(
            uint8(endorsable.getEndorsementStatus(testUser2)),
            uint8(Endorsable.State.REMOVED),
            "testUser2 should be REMOVED"
        );
    }

    /**
     * @notice Test that getEndorsementStatus works correctly for all states.
     */
    function testGetEndorsementStatusAllStates() public {
        // Test UNASSIGNED (default)
        assertEq(
            uint8(endorsable.getEndorsementStatus(testUser)), uint8(Endorsable.State.UNASSIGNED), "Should be UNASSIGNED"
        );

        // Test REQUESTED
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Request");
        assertEq(
            uint8(endorsable.getEndorsementStatus(testUser)), uint8(Endorsable.State.REQUESTED), "Should be REQUESTED"
        );

        // Test ENDORSED
        vm.prank(testUser);
        endorsable.endorse("Endorse");
        assertEq(
            uint8(endorsable.getEndorsementStatus(testUser)), uint8(Endorsable.State.ENDORSED), "Should be ENDORSED"
        );

        // Test REVOKED
        vm.prank(testUser);
        endorsable.revokeEndorsement("Revoke");
        assertEq(uint8(endorsable.getEndorsementStatus(testUser)), uint8(Endorsable.State.REVOKED), "Should be REVOKED");

        // Test REMOVED (need to request again first)
        vm.prank(owner);
        endorsable.requestEndorsement(testUser, "Request again");
        vm.prank(owner);
        endorsable.removeEndorsement(testUser, "Remove");
        assertEq(uint8(endorsable.getEndorsementStatus(testUser)), uint8(Endorsable.State.REMOVED), "Should be REMOVED");
    }
}
