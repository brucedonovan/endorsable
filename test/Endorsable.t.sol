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
            uint(endorsable.getEndorsementStatus(initRequest)),
            uint(Endorsable.State.REQUESTED),
            "initRequest should be in REQUESTED state"
        );
        assertEq(
            uint(endorsable.getEndorsementStatus(initRequest2)),
            uint(Endorsable.State.REQUESTED),
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
        assertEq(
            uint8(status),
            uint8(Endorsable.State.REQUESTED),
            "Expected state: REQUESTED"
        );
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
        assertEq(
            uint8(status),
            uint8(Endorsable.State.ENDORSED),
            "Expected state: ENDORSED"
        );
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
        assertEq(
            uint8(status),
            uint8(Endorsable.State.REVOKED),
            "Expected state: REVOKED"
        );
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
        assertEq(
            uint8(status),
            uint8(Endorsable.State.REMOVED),
            "Expected state: REMOVED"
        );
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
        assertEq(
            uint8(status),
            uint8(Endorsable.State.REMOVED),
            "Expected state: REMOVED"
        );
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
    // Fuzz Tests
    // -----------------------------------------------

    /**
     * @notice Fuzz test for requesting endorsements with arbitrary addresses.
     * @dev We skip address(0) or contract addresses if desired, but here we keep it simple.
     */
    function testFuzz_RequestEndorsement(
        address randomAddr,
        string memory comment
    ) public {
        // Only the owner can request
        vm.prank(owner);

        // If the random address is already testUser or testUser2 with a prior state, skip
        // Or we can just safely catch any revert to demonstrate fuzzing approach.
        vm.expectEmit(true, false, false, true);
        emit EndorsementRequested(randomAddr, comment);
        endorsable.requestEndorsement(randomAddr, comment);

        // Check state
        Endorsable.State status = endorsable.getEndorsementStatus(randomAddr);
        assertEq(
            uint8(status),
            uint8(Endorsable.State.REQUESTED),
            "Should be REQUESTED"
        );
    }

    /**
     * @notice Fuzz test that once requested, random address can successfully call `endorse()`.
     */
    function testFuzz_EndorseAfterRequest(
        address randomAddr,
        string memory comment
    ) public {
        // Only allow fuzzed addresses that aren't the zero address to reduce meaningless calls
        vm.assume(randomAddr != address(0));

        // 1) Owner requests endorsement for randomAddr
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, comment);

        // 2) randomAddr endorses
        vm.prank(randomAddr);
        endorsable.endorse(comment);

        // Check final state
        Endorsable.State status = endorsable.getEndorsementStatus(randomAddr);
        assertEq(
            uint8(status),
            uint8(Endorsable.State.ENDORSED),
            "Should be ENDORSED"
        );
    }

    /**
     * @notice Fuzz test for revoking endorsement from random addresses (only valid if state is ENDORSED).
     */
    function testFuzz_RevokeEndorsement(
        address randomAddr,
        string memory comment
    ) public {
        vm.assume(randomAddr != address(0));

        // 1) Request
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, "Requesting...");

        // 2) Endorse
        vm.prank(randomAddr);
        endorsable.endorse("Endorsing...");

        // 3) Revoke
        vm.prank(randomAddr);
        endorsable.revokeEndorsement(comment);

        // Check final state
        Endorsable.State status = endorsable.getEndorsementStatus(randomAddr);
        assertEq(
            uint8(status),
            uint8(Endorsable.State.REVOKED),
            "Should be REVOKED"
        );
    }

    /**
     * @notice Fuzz test for removing endorsements from random addresses (only owner can remove).
     */
    function testFuzz_RemoveEndorsement(
        address randomAddr,
        string memory comment
    ) public {
        vm.assume(randomAddr != address(0));

        // 1) Request
        vm.prank(owner);
        endorsable.requestEndorsement(randomAddr, "Requesting for test...");

        // 2) Endorse or skip to directly removing. Let's do the full cycle:
        vm.prank(randomAddr);
        endorsable.endorse("Endorsing in fuzz test...");

        // 3) Remove
        vm.prank(owner);
        endorsable.removeEndorsement(randomAddr, comment);

        // Check final state
        Endorsable.State status = endorsable.getEndorsementStatus(randomAddr);
        assertEq(
            uint8(status),
            uint8(Endorsable.State.REMOVED),
            "Should be REMOVED"
        );
    }
}
