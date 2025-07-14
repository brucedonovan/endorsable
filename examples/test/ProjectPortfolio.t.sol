// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../ProjectPortfolio.sol";

contract ProjectPortfolioTest is Test {
    ProjectPortfolio public portfolio;
    
    address public owner = address(0x1);
    address public client1 = address(0x2);
    address public reviewer1 = address(0x3);
    address public expert1 = address(0x4);
    address public client2 = address(0x5);
    address public industryExpert = address(0x6);
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Set up initial contract-level endorsement requests
        address[] memory contractEndorsers = new address[](1);
        contractEndorsers[0] = industryExpert;
        
        portfolio = new ProjectPortfolio(
            "Tech Startup Portfolio",
            contractEndorsers
        );
        
        vm.stopPrank();
    }
    
    function testInitialSetup() public {
        assertEq(portfolio.portfolioName(), "Tech Startup Portfolio");
        assertEq(portfolio.portfolioOwner(), owner);
        assertEq(portfolio.getProjectCount(), 0);
        
        // Check contract-level endorsement request
        assertEq(uint8(portfolio.getEndorsementStatus(industryExpert)), 1); // REQUESTED
    }
    
    function testCreateProject() public {
        vm.prank(owner);
        portfolio.createProject(
            "web-app-v1",
            "E-commerce Web Application",
            "Full-stack web app with payment integration",
            2 ether,
            true
        );
        
        assertEq(portfolio.getProjectCount(), 1);
        string[] memory projectIds = portfolio.getAllProjectIds();
        assertEq(projectIds[0], "web-app-v1");
        
        // Check project details
        (
            string memory name,
            string memory description,
            uint256 budget,
            uint256 completionDate,
            bool isCompleted,
            bool isPublic
        ) = portfolio.projects("web-app-v1");
        
        assertEq(name, "E-commerce Web Application");
        assertEq(description, "Full-stack web app with payment integration");
        assertEq(budget, 2 ether);
        assertEq(completionDate, 0);
        assertFalse(isCompleted);
        assertTrue(isPublic);
    }
    
    function testProjectEndorsementFlow() public {
        // Create project
        vm.prank(owner);
        portfolio.createProject(
            "mobile-app",
            "Mobile Banking App",
            "Secure mobile banking application",
            3 ether,
            false
        );
        
        // Request endorsements
        address[] memory endorsers = new address[](3);
        endorsers[0] = client1;
        endorsers[1] = reviewer1;
        endorsers[2] = expert1;
        
        vm.prank(owner);
        portfolio.requestProjectEndorsements(
            "mobile-app",
            endorsers,
            "Please review and endorse this mobile banking project"
        );
        
        // Check that endorsements were requested
        assertEq(portfolio.getStateEndorsementStatus(owner, "mobile-app", client1), 1); // REQUESTED
        assertEq(portfolio.getStateEndorsementStatus(owner, "mobile-app", reviewer1), 1); // REQUESTED
        assertEq(portfolio.getStateEndorsementStatus(owner, "mobile-app", expert1), 1); // REQUESTED
        
        // Endorsers endorse the project
        vm.prank(client1);
        portfolio.endorseState(owner, "mobile-app", "Excellent user experience");
        
        vm.prank(reviewer1);
        portfolio.endorseState(owner, "mobile-app", "Clean code and good architecture");
        
        vm.prank(expert1);
        portfolio.endorseState(owner, "mobile-app", "Meets industry security standards");
        
        // Check endorsement statuses
        assertEq(portfolio.getStateEndorsementStatus(owner, "mobile-app", client1), 2); // ENDORSED
        assertEq(portfolio.getStateEndorsementStatus(owner, "mobile-app", reviewer1), 2); // ENDORSED
        assertEq(portfolio.getStateEndorsementStatus(owner, "mobile-app", expert1), 2); // ENDORSED
    }
    
    function testBatchEndorsementChecks() public {
        // Create and set up project
        vm.prank(owner);
        portfolio.createProject("batch-test", "Batch Test Project", "Testing batch operations", 1 ether, true);
        
        address[] memory endorsers = new address[](3);
        endorsers[0] = client1;
        endorsers[1] = reviewer1;
        endorsers[2] = expert1;
        
        vm.prank(owner);
        portfolio.requestProjectEndorsements("batch-test", endorsers, "Test batch operations");
        
        // Some endorse, some don't
        vm.prank(client1);
        portfolio.endorseState(owner, "batch-test", "Good project");
        
        vm.prank(expert1);
        portfolio.endorseState(owner, "batch-test", "Solid work");
        
        // Check individual statuses since we removed batch function
        assertEq(portfolio.getStateEndorsementStatus(owner, "batch-test", client1), 2); // ENDORSED
        assertEq(portfolio.getStateEndorsementStatus(owner, "batch-test", reviewer1), 1); // REQUESTED  
        assertEq(portfolio.getStateEndorsementStatus(owner, "batch-test", expert1), 2); // ENDORSED
        
        // Check endorsement summary
        (uint256 endorsed, uint256 requested, uint256 revoked) = 
            portfolio.getProjectEndorsementSummary(owner, "batch-test", endorsers);
        assertEq(endorsed, 2);
        assertEq(requested, 1);
        assertEq(revoked, 0);
    }
    
    function testProjectCompletion() public {
        vm.prank(owner);
        portfolio.createProject("completion-test", "Test Project", "Testing completion", 1 ether, true);
        
        // Check initial state
        (, , , uint256 completionDate, bool isCompleted, ) = portfolio.projects("completion-test");
        assertEq(completionDate, 0);
        assertFalse(isCompleted);
        
        // Complete project
        vm.prank(owner);
        portfolio.completeProject("completion-test");
        
        // Check updated state
        (, , , completionDate, isCompleted, ) = portfolio.projects("completion-test");
        assertTrue(isCompleted);
        assertGt(completionDate, 0);
    }
    
    function testProjectReputationScore() public {
        // Create project
        vm.prank(owner);
        portfolio.createProject("reputation-test", "High-Value Project", "Testing reputation", 2 ether, true);
        
        // Set up endorsements
        address[] memory endorsers = new address[](3);
        endorsers[0] = client1;
        endorsers[1] = reviewer1;
        endorsers[2] = expert1;
        
        vm.prank(owner);
        portfolio.requestProjectEndorsements("reputation-test", endorsers, "Rate this project");
        
        // Get endorsements
        vm.prank(client1);
        portfolio.endorseState(owner, "reputation-test", "Great project");
        
        vm.prank(reviewer1);
        portfolio.endorseState(owner, "reputation-test", "Well executed");
        
        // Complete the project
        vm.prank(owner);
        portfolio.completeProject("reputation-test");
        
        // Check reputation score
        uint256 score = portfolio.getProjectReputationScore(owner, "reputation-test", endorsers);
        // Expected: 30 (2 endorsements * 15) + 20 (completed) + 10 (high-value) + 5 (public) + 5 (on-time) = 70
        assertEq(score, 70);
    }
    
    function testHighQualityProject() public {
        // Create high-value project
        vm.prank(owner);
        portfolio.createProject("quality-test", "Premium Project", "High-quality project", 1 ether, true);
        
        address[] memory endorsers = new address[](3);
        endorsers[0] = client1;
        endorsers[1] = reviewer1;
        endorsers[2] = expert1;
        
        vm.prank(owner);
        portfolio.requestProjectEndorsements("quality-test", endorsers, "Quality assessment");
        
        // Get multiple endorsements
        vm.prank(client1);
        portfolio.endorseState(owner, "quality-test", "High quality");
        
        vm.prank(reviewer1);
        portfolio.endorseState(owner, "quality-test", "Excellent work");
        
        // Complete project
        vm.prank(owner);
        portfolio.completeProject("quality-test");
        
        // Should be high quality (2+ endorsements, completed, >= 0.5 ether)
        assertTrue(portfolio.isHighQualityProject(owner, "quality-test", endorsers));
    }
    
    function testRevokeStateEndorsement() public {
        // Set up project and endorsement
        vm.prank(owner);
        portfolio.createProject("revoke-test", "Test Project", "Testing revocation", 1 ether, true);
        
        vm.prank(owner);
        portfolio.requestStateEndorsement("revoke-test", client1, "Please endorse");
        
        vm.prank(client1);
        portfolio.endorseState(owner, "revoke-test", "Initial endorsement");
        
        assertEq(portfolio.getStateEndorsementStatus(owner, "revoke-test", client1), 2); // ENDORSED
        
        // Revoke endorsement
        vm.prank(client1);
        portfolio.revokeStateEndorsement(owner, "revoke-test", "Changed my mind");
        
        assertEq(portfolio.getStateEndorsementStatus(owner, "revoke-test", client1), 3); // REVOKED
    }
    
    function testUpdateProject() public {
        vm.prank(owner);
        portfolio.createProject("update-test", "Original Name", "Original description", 1 ether, false);
        
        vm.prank(owner);
        portfolio.updateProject("update-test", "Updated description", 2 ether, true);
        
        (, string memory description, uint256 budget, , , bool isPublic) = portfolio.projects("update-test");
        assertEq(description, "Updated description");
        assertEq(budget, 2 ether);
        assertTrue(isPublic);
    }
    
    function test_RevertWhen_CreateDuplicateProject() public {
        vm.startPrank(owner);
        portfolio.createProject("duplicate", "First", "First project", 1 ether, true);
        
        vm.expectRevert("Project already exists");
        portfolio.createProject("duplicate", "Second", "Second project", 2 ether, false);
        vm.stopPrank();
    }
    
    function test_RevertWhen_EndorseNonExistentProject() public {
        vm.prank(client1);
        vm.expectRevert("Not requested");
        portfolio.endorseState(owner, "non-existent", "This should fail");
    }
    
    function test_RevertWhen_NonOwnerProjectOperations() public {
        vm.prank(client1); // Not owner
        vm.expectRevert();
        portfolio.createProject("unauthorized", "Test", "Should fail", 1 ether, true);
        
        vm.prank(reviewer1); // Not owner
        vm.expectRevert();
        portfolio.completeProject("any-project");
    }
    
    function testMultipleProjects() public {
        vm.startPrank(owner);
        
        // Create multiple projects
        portfolio.createProject("project1", "First Project", "Description 1", 1 ether, true);
        portfolio.createProject("project2", "Second Project", "Description 2", 2 ether, false);
        portfolio.createProject("project3", "Third Project", "Description 3", 3 ether, true);
        
        vm.stopPrank();
        
        assertEq(portfolio.getProjectCount(), 3);
        
        string[] memory projectIds = portfolio.getAllProjectIds();
        assertEq(projectIds.length, 3);
        assertEq(projectIds[0], "project1");
        assertEq(projectIds[1], "project2");
        assertEq(projectIds[2], "project3");
    }
}
