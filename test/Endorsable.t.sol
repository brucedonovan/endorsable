// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Endorsable.sol";

contract EndorsableTest is Test {
    Endorsable endorsable;
    address owner = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);

    function setUp() public {
        vm.prank(owner);
        endorsable = new Endorsable();
    }

    function testRequestEndorsement() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);

        uint8 status = endorsable.getEndorsementStatus(user1);
        assertEq(status, 1, "User1 should be in REQUESTED state");
    }

    function testEndorse() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);

        vm.prank(user1);
        endorsable.endorse();

        uint8 status = endorsable.getEndorsementStatus(user1);
        assertEq(status, 2, "User1 should be in ENDORSED state");
    }

    function testCannotEndorseWithoutRequest() public {
        vm.prank(user1);
        vm.expectRevert("Endorsement not requested.");
        endorsable.endorse();
    }

    function testRevokeEndorsement() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);
        vm.prank(user1);
        endorsable.endorse();
        vm.prank(user1);
        endorsable.revokeEndorsement();

        uint8 status = endorsable.getEndorsementStatus(user1);
        assertEq(status, 3, "User1 should be in REVOKED state");
    }

    function testCannotRevokeIfNotEndorsed() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);

        vm.prank(user1);
        vm.expectRevert("Not endorsed, already revoked, or removed.");
        endorsable.revokeEndorsement();
    }

    function testRemoveEndorsement() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);
        vm.prank(user1);
        endorsable.endorse();
        vm.prank(owner);
        endorsable.removeEndorsement(user1);

        uint8 status = endorsable.getEndorsementStatus(user1);
        assertEq(status, 4, "User1 should be in REMOVED state");
    }

    function testCannotRemoveIfNotEndorsedOrRequested() public {
        vm.prank(owner);
        vm.expectRevert("Not endorsed or requested.");
        endorsable.removeEndorsement(user1);
    }

    function testFuzzRequestEndorsement(address randomUser) public {
        vm.assume(randomUser != address(0));
        vm.prank(owner);
        endorsable.requestEndorsement(randomUser);

        uint8 status = endorsable.getEndorsementStatus(randomUser);
        assertEq(status, 1, "Random user should be in REQUESTED state");
    }

    function testFuzzEndorse(address randomUser) public {
        vm.assume(randomUser != address(0));
        vm.prank(owner);
        endorsable.requestEndorsement(randomUser);
        vm.prank(randomUser);
        endorsable.endorse();

        uint8 status = endorsable.getEndorsementStatus(randomUser);
        assertEq(status, 2, "Random user should be in ENDORSED state");
    }

    function testFuzzRevokeEndorsement(address randomUser) public {
        vm.assume(randomUser != address(0));
        vm.prank(owner);
        endorsable.requestEndorsement(randomUser);
        vm.prank(randomUser);
        endorsable.endorse();
        vm.prank(randomUser);
        endorsable.revokeEndorsement();

        uint8 status = endorsable.getEndorsementStatus(randomUser);
        assertEq(status, 3, "Random user should be in REVOKED state");
    }
}
