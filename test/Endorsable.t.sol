// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Endorsable.sol";

contract EndorsableTest is Test {
    Endorsable endorsable;
    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    function setUp() public {
        vm.prank(owner);
        endorsable = new Endorsable();
    }

    function testRequestEndorsement() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);
        assertEq(uint(endorsable.getEndorsementStatus(user1)), uint(Endorsable.endorseState.REQUESTED));
    }

    function testCannotRequestEndorsementIfAlreadyRequested() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);
        vm.prank(owner);
        vm.expectRevert("The signature has already been requested.");
        endorsable.requestEndorsement(user1);
    }

    function testCannotRequestEndorsementIfAlreadyEndorsed() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);
        vm.prank(user1);
        endorsable.endorse();
        vm.prank(owner);
        vm.expectRevert("This item has already been endorsed.");
        endorsable.requestEndorsement(user1);
    }

    function testEndorse() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);
        vm.prank(user1);
        endorsable.endorse();
        assertEq(uint(endorsable.getEndorsementStatus(user1)), uint(Endorsable.endorseState.ENDORSED));
    }

    function testCannotEndorseWithoutRequest() public {
        vm.prank(user1);
        vm.expectRevert("Account has not been explicitly requested to endorsed this item.");
        endorsable.endorse();
    }

    function testRevokeEndorsement() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);
        vm.prank(user1);
        endorsable.endorse();
        vm.prank(user1);
        endorsable.revokeEndorsement();
        assertEq(uint(endorsable.getEndorsementStatus(user1)), uint(Endorsable.endorseState.REVOKED));
    }

    function testCannotRevokeIfNotEndorsed() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);
        vm.prank(user1);
        vm.expectRevert("Element not endorsed, or previously revoked or removed");
        endorsable.revokeEndorsement();
    }

    function testRemoveEndorsement() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);
        vm.prank(user1);
        endorsable.endorse();
        vm.prank(owner);
        endorsable.removeEndorsement(user1);
        assertEq(uint(endorsable.getEndorsementStatus(user1)), uint(Endorsable.endorseState.REMOVED));
    }

    function testCannotRemoveIfNotEndorsed() public {
        vm.prank(owner);
        endorsable.requestEndorsement(user1);
        vm.prank(owner);
        vm.expectRevert("Element not endorsed, or previously revoked or removed");
        endorsable.removeEndorsement(user1);
    }

    function testEndorseAddress() public {
        vm.prank(owner);
        Endorsable anotherEndorsable = new Endorsable();
        vm.prank(owner);
        anotherEndorsable.requestEndorsement(address(endorsable));
        vm.prank(owner);
        endorsable.endorseAddress(address(anotherEndorsable));
        assertEq(uint(anotherEndorsable.getEndorsementStatus(address(endorsable))), uint(Endorsable.endorseState.ENDORSED));
    }
}
