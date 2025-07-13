// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../ReputableBusiness.sol";

contract ReputableBusinessTest is Test {
    ReputableBusiness public business;
    
    address public owner = address(0x1);
    address public auditor1 = address(0x2);
    address public partner1 = address(0x3);
    address public customer1 = address(0x4);
    address public partner2 = address(0x5);
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Set up initial endorsement requests
        address[] memory initialRequests = new address[](3);
        initialRequests[0] = auditor1;
        initialRequests[1] = partner1;
        initialRequests[2] = customer1;
        
        business = new ReputableBusiness(
            "Acme Corp",
            "Software Development",
            5, // years in business
            initialRequests
        );
        
        vm.stopPrank();
    }
    
    function testInitialSetup() public {
        assertEq(business.businessName(), "Acme Corp");
        assertEq(business.businessType(), "Software Development");
        assertEq(business.businessOwner(), owner);
        assertEq(business.yearsInBusiness(), 5);
        assertEq(business.successfulTransactions(), 0);
        assertFalse(business.isAudited());
        
        // Check initial endorsement requests
        assertEq(uint8(business.getEndorsementStatus(auditor1)), 1); // REQUESTED
        assertEq(uint8(business.getEndorsementStatus(partner1)), 1); // REQUESTED
        assertEq(uint8(business.getEndorsementStatus(customer1)), 1); // REQUESTED
        assertEq(uint8(business.getEndorsementStatus(partner2)), 0); // UNASSIGNED
    }
    
    function testEndorsementFlow() public {
        // Auditor endorses the business
        vm.prank(auditor1);
        business.endorse("Excellent financial practices");
        assertEq(uint8(business.getEndorsementStatus(auditor1)), 2); // ENDORSED
        
        // Partner endorses the business
        vm.prank(partner1);
        business.endorse("Great collaboration and delivery");
        assertEq(uint8(business.getEndorsementStatus(partner1)), 2); // ENDORSED
        
        // Customer endorses the business
        vm.prank(customer1);
        business.endorse("Outstanding service quality");
        assertEq(uint8(business.getEndorsementStatus(customer1)), 2); // ENDORSED
    }
    
    function testRequestAdditionalEndorsement() public {
        vm.prank(owner);
        business.requestEndorsement(partner2, "Requesting endorsement from new partner");
        assertEq(uint8(business.getEndorsementStatus(partner2)), 1); // REQUESTED
        
        vm.prank(partner2);
        business.endorse("Solid business partnership");
        assertEq(uint8(business.getEndorsementStatus(partner2)), 2); // ENDORSED
    }
    
    function testRevokeEndorsement() public {
        // First endorse
        vm.prank(auditor1);
        business.endorse("Initial endorsement");
        assertEq(uint8(business.getEndorsementStatus(auditor1)), 2); // ENDORSED
        
        // Then revoke
        vm.prank(auditor1);
        business.revokeEndorsement("Revoking due to policy changes");
        assertEq(uint8(business.getEndorsementStatus(auditor1)), 3); // REVOKED
    }
    
    function testBusinessMetricsUpdate() public {
        vm.prank(owner);
        business.updateBusinessMetrics(7, 150, true);
        
        assertEq(business.yearsInBusiness(), 7);
        assertEq(business.successfulTransactions(), 150);
        assertTrue(business.isAudited());
    }
    
    function testRecordTransaction() public {
        vm.prank(owner);
        business.recordSuccessfulTransaction();
        assertEq(business.successfulTransactions(), 1);
        
        vm.prank(owner);
        business.recordSuccessfulTransaction();
        assertEq(business.successfulTransactions(), 2);
    }
    
    function testReputationScore() public {
        // Set up endorsements
        vm.prank(auditor1);
        business.endorse("Great business");
        
        vm.prank(partner1);
        business.endorse("Reliable partner");
        
        vm.prank(customer1);
        business.endorse("Excellent service");
        
        // Update business metrics
        vm.prank(owner);
        business.updateBusinessMetrics(5, 100, true);
        
        // Check reputation score
        address[] memory endorsers = new address[](3);
        endorsers[0] = auditor1;
        endorsers[1] = partner1;
        endorsers[2] = customer1;
        
        uint256 score = business.getReputationScore(endorsers);
        // Expected: 30 (3 endorsements * 10) + 10 (years >= 5) + 10 (transactions >= 100) + 10 (audited) = 60
        assertEq(score, 60);
    }
    
    function testTrustworthiness() public {
        // Need at least 3 endorsements, 2+ years, and audited status
        vm.prank(auditor1);
        business.endorse("Trustworthy");
        
        vm.prank(partner1);
        business.endorse("Reliable");
        
        vm.prank(customer1);
        business.endorse("Excellent");
        
        vm.prank(owner);
        business.updateBusinessMetrics(2, 50, true);
        
        address[] memory endorsers = new address[](3);
        endorsers[0] = auditor1;
        endorsers[1] = partner1;
        endorsers[2] = customer1;
        
        assertTrue(business.isTrustworthy(endorsers));
        
        // Test with insufficient endorsements
        address[] memory fewEndorsers = new address[](2);
        fewEndorsers[0] = auditor1;
        fewEndorsers[1] = partner1;
        
        assertFalse(business.isTrustworthy(fewEndorsers));
    }
    
    function test_RevertWhen_EndorseWithoutRequest() public {
        vm.prank(partner2); // Not requested
        vm.expectRevert("Endorsement not requested.");
        business.endorse("Trying to endorse without request");
    }
    
    function test_RevertWhen_RevokeWithoutEndorsement() public {
        vm.prank(auditor1); // Has request but not endorsed
        vm.expectRevert("Not endorsed, already revoked, or removed.");
        business.revokeEndorsement("Trying to revoke without endorsement");
    }
    
    function test_RevertWhen_NonOwnerActions() public {
        vm.prank(auditor1); // Not owner
        vm.expectRevert();
        business.requestEndorsement(partner2, "Not authorized");
        
        vm.prank(partner1); // Not owner
        vm.expectRevert();
        business.updateBusinessMetrics(10, 200, true);
    }
}
