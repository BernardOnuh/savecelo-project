// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SaveCelo.sol";
import "../src/SaveToken.sol";

contract SaveCeloTest is Test {

    SaveCelo  public vault;
    SaveToken public token;

    address owner   = address(this);
    address alice   = makeAddr("alice");
    address bob     = makeAddr("bob");

    uint256 constant MINT_AMOUNT = 1_000 ether;

    function setUp() public {
        // Deploy a fresh token and vault for every test
        token = new SaveToken("Save Dollar", "SUSD", 18, 0);
        vault = new SaveCelo(address(token));

        // Fund alice and bob
        token.mint(alice, MINT_AMOUNT);
        token.mint(bob,   MINT_AMOUNT);
    }

    // ── Waitlist tests ────────────────────────────────────────

    function test_JoinWaitlist() public {
        vm.prank(alice);
        vault.joinWaitlist();
        assertEq(
            uint(vault.waitlistStatusOf(alice)),
            uint(SaveCelo.WaitlistStatus.Pending)
        );
    }

    function test_CannotJoinTwice() public {
        vm.startPrank(alice);
        vault.joinWaitlist();
        vm.expectRevert("Already on waitlist");
        vault.joinWaitlist();
        vm.stopPrank();
    }

    function test_ApproveUser() public {
        vm.prank(alice);
        vault.joinWaitlist();

        vault.approveUser(alice);   // called by owner (this contract)

        assertEq(
            uint(vault.waitlistStatusOf(alice)),
            uint(SaveCelo.WaitlistStatus.Approved)
        );
    }

    // ── Deposit / withdraw tests ──────────────────────────────

    function _approveAlice() internal {
        vm.prank(alice);
        vault.joinWaitlist();
        vault.approveUser(alice);
    }

    function test_Deposit() public {
        _approveAlice();

        vm.startPrank(alice);
        token.approve(address(vault), 300 ether);
        vault.deposit(address(token), 300 ether);
        vm.stopPrank();

        assertEq(vault.getBalance(alice, address(token)), 500 ether);
    }

    function test_Withdraw() public {
        _approveAlice();

        vm.startPrank(alice);
        token.approve(address(vault), 500 ether);
        vault.deposit(address(token), 500 ether);
        vault.withdraw(address(token), 200 ether);
        vm.stopPrank();

        assertEq(vault.getBalance(alice, address(token)), 300 ether);
    }

    function test_WithdrawAll() public {
        _approveAlice();

        vm.startPrank(alice);
        token.approve(address(vault), 1000 ether);
        vault.deposit(address(token), 1000 ether);
        vault.withdrawAll(address(token));
        vm.stopPrank();

        assertEq(vault.getBalance(alice, address(token)), 0);
    }

    function test_UnapprovedCannotDeposit() public {
        vm.startPrank(alice);
        
        token.approve(address(vault), 500 ether);
        vm.expectRevert("Not approved: join the waitlist");
        vault.deposit(address(token), 500 ether);
        vm.stopPrank();
    }

    // ── Multi-token tests ─────────────────────────────────────

    function test_AddSecondToken() public {
        SaveToken token2 = new SaveToken("Save Usd", "SUSD", 18, 0);
        vault.addToken(address(token2), "SUSD");
        assertTrue(vault.tokenEnabled(address(token2)));
    }

    function test_DisabledTokenBlocksDeposit() public {
        _approveAlice();
        vault.disableToken(address(token));

        vm.startPrank(alice);
        token.approve(address(vault), 100 ether);
        vm.expectRevert("Token not supported");
        vault.deposit(address(token), 100 ether);
        vm.stopPrank();
    }
}
