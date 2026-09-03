// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Fixture} from "./helpers/Fixture.sol";
import {ExperimentTreasury} from "../src/ExperimentTreasury.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 */
contract ExperimentTreasuryTest is Fixture {
    function setUp() public override {
        super.setUp();
        runLaunchDistribution();
        vm.deal(address(treasury), 10 ether);
        vm.deal(address(this), 10 ether);
        weth.deposit{value: 5 ether}();
        weth.transfer(address(treasury), 5 ether);
    }

    function test_dustHappyPath() public {
        vm.prank(proposer);
        treasury.sendDust(dustDemo, 100 ether, "log-demo");
        assertEq(token.balanceOf(dustDemo), 100 ether);
        assertEq(treasury.lifetimeDustUsed(), 100 ether);
    }

    function test_dustRejectsNonRecipientAndNonProposer() public {
        vm.prank(proposer);
        vm.expectRevert(ExperimentTreasury.NotDustRecipient.selector);
        treasury.sendDust(stranger, 1 ether, "no");

        vm.prank(stranger);
        vm.expectRevert(ExperimentTreasury.NotProposer.selector);
        treasury.sendDust(dustDemo, 1 ether, "no");
    }

    function test_dustCaps() public {
        vm.startPrank(proposer);
        vm.expectRevert(ExperimentTreasury.DustCapTx.selector);
        treasury.sendDust(dustDemo, 100 ether + 1, "too big");

        // 10 * 100 = 1000 fills the week
        for (uint256 i = 0; i < 10; i++) {
            treasury.sendDust(dustDemo, 100 ether, "week");
        }
        vm.expectRevert(ExperimentTreasury.DustCapWeek.selector);
        treasury.sendDust(dustDemo, 1, "week overflow");

        vm.warp(block.timestamp + 7 days);
        // lifetime 5000: already 1000, 40 more 100-unit txs = 5000
        for (uint256 i = 0; i < 40; i++) {
            if (i > 0 && i % 10 == 0) vm.warp(block.timestamp + 7 days);
            treasury.sendDust(dustDemo, 100 ether, "life");
        }
        // Week bucket is full; roll it so the next 1 wei hits the lifetime cap.
        vm.warp(block.timestamp + 7 days);
        vm.expectRevert(ExperimentTreasury.DustCapLifetime.selector);
        treasury.sendDust(dustDemo, 1, "life overflow");
        vm.stopPrank();
    }

    function test_dustRequiresReason() public {
        vm.prank(proposer);
        vm.expectRevert(ExperimentTreasury.EmptyReason.selector);
        treasury.sendDust(dustDemo, 1 ether, "");
    }

    function test_sendGrknToDeadIsProposerOnly() public {
        uint256 before_ = token.balanceOf(address(treasury));
        vm.prank(stranger);
        vm.expectRevert(ExperimentTreasury.NotProposer.selector);
        treasury.sendGrknToDead(1000 ether);

        vm.prank(proposer);
        treasury.sendGrknToDead(1000 ether);
        assertEq(token.balanceOf(dead), 1000 ether);
        assertEq(token.balanceOf(address(treasury)), before_ - 1000 ether);
    }

    function test_remainingToDeadOnlyAfter90dPermissionless() public {
        vm.expectRevert(ExperimentTreasury.ExperimentNotEnded.selector);
        treasury.sendRemainingGrknToDead();

        vm.warp(treasury.experimentEnd());
        uint256 leftover = token.balanceOf(address(treasury));
        vm.prank(stranger);
        treasury.sendRemainingGrknToDead();
        assertEq(token.balanceOf(dead), leftover);
        assertEq(token.balanceOf(address(treasury)), 0);
    }

    function test_noThirdGrknDestination() public {
        assertNoSelector(
            address(treasury), abi.encodeWithSignature("transfer(address,uint256)", stranger, uint256(1 ether))
        );
        assertNoSelector(
            address(treasury), abi.encodeWithSignature("proposeGrkn(address,uint256)", stranger, uint256(1 ether))
        );
        assertEq(token.balanceOf(stranger), 0);
    }

    function test_pairingCannotLeaveBeforeDelay_ETH() public {
        vm.prank(proposer);
        treasury.proposePairingWithdraw(address(0), stranger, 1 ether);

        vm.expectRevert();
        treasury.executePairingWithdraw();
        assertEq(address(treasury).balance, 10 ether);

        vm.warp(block.timestamp + 7 days - 1);
        vm.expectRevert();
        treasury.executePairingWithdraw();
        assertEq(address(treasury).balance, 10 ether);

        vm.warp(block.timestamp + 1);
        uint256 before_ = stranger.balance;
        treasury.executePairingWithdraw();
        assertEq(stranger.balance, before_ + 1 ether);
        assertEq(address(treasury).balance, 9 ether);
    }

    function test_pairingCannotLeaveBeforeDelay_WETH() public {
        vm.prank(proposer);
        treasury.proposePairingWithdraw(address(weth), stranger, 1 ether);

        vm.expectRevert();
        treasury.executePairingWithdraw();
        assertEq(weth.balanceOf(address(treasury)), 5 ether);

        vm.warp(block.timestamp + 7 days);
        treasury.executePairingWithdraw();
        assertEq(weth.balanceOf(stranger), 1 ether);
    }

    function test_pairingRejectsNonWethErc20() public {
        vm.prank(proposer);
        vm.expectRevert(ExperimentTreasury.BadPairingToken.selector);
        treasury.proposePairingWithdraw(address(token), stranger, 1 ether);
    }

    function test_pairingNoDustException() public {
        // Pairing has no 100-unit dust shortcut. Even 1 wei needs the delay.
        vm.prank(proposer);
        treasury.proposePairingWithdraw(address(0), stranger, 1);
        vm.expectRevert();
        treasury.executePairingWithdraw();
    }

    function test_onePendingPairing() public {
        vm.startPrank(proposer);
        treasury.proposePairingWithdraw(address(0), stranger, 1 ether);
        vm.expectRevert(ExperimentTreasury.PendingExists.selector);
        treasury.proposePairingWithdraw(address(0), stranger, 2 ether);
        vm.stopPrank();
    }

    function test_noTimelockAdmin() public {
        address t = address(treasury);
        assertNoSelector(t, abi.encodeWithSignature("updateDelay(uint256)", uint256(0)));
        assertNoSelector(t, abi.encodeWithSignature("DEFAULT_ADMIN_ROLE()"));
        assertNoSelector(t, abi.encodeWithSignature("grantRole(bytes32,address)", bytes32(0), proposer));
        assertNoSelector(t, abi.encodeWithSignature("owner()"));
    }

    function test_emptyRecipientSetIsValid() public {
        address[] memory none = new address[](0);
        ExperimentTreasury t2 = new ExperimentTreasury(address(token), address(weth), dead, proposer, none);
        assertEq(t2.dustRecipientCount(), 0);
        vm.prank(proposer);
        vm.expectRevert(ExperimentTreasury.NotDustRecipient.selector);
        t2.sendDust(dustDemo, 1 ether, "none");
    }
}
