// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Fixture} from "./helpers/Fixture.sol";
import {TeamVestLock} from "../src/TeamVestLock.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 */
contract TeamVestLockTest is Fixture {
    function setUp() public override {
        super.setUp();
        runLaunchDistribution();
    }

    function test_constructorRejectsZero() public {
        vm.expectRevert(TeamVestLock.ZeroAddress.selector);
        new TeamVestLock(address(0), teamWallet);
        vm.expectRevert(TeamVestLock.ZeroAddress.selector);
        new TeamVestLock(address(token), address(0));
    }

    function test_nothingReleasableBeforeCliff() public {
        assertEq(vest.releasable(), 0);
        vm.expectRevert(TeamVestLock.NothingToRelease.selector);
        vest.release();
    }

    function test_fuzz_noReleaseBeforeCliff(uint256 dt) public {
        dt = bound(dt, 0, vest.CLIFF() - 1);
        vm.warp(vest.start() + dt);
        assertEq(vest.vestedAmount(block.timestamp), 0);
        assertEq(vest.releasable(), 0);
        vm.expectRevert(TeamVestLock.NothingToRelease.selector);
        vest.release();
        assertEq(token.balanceOf(teamWallet), 0);
    }

    function test_zeroAtExactCliff() public {
        vm.warp(vest.cliffEnd());
        assertEq(vest.vestedAmount(block.timestamp), 0);
        vm.expectRevert(TeamVestLock.NothingToRelease.selector);
        vest.release();
    }

    function test_linearMidpoint() public {
        // Halfway through the 36-month linear period.
        uint256 linear = vest.DURATION() - vest.CLIFF();
        vm.warp(vest.cliffEnd() + linear / 2);
        uint256 vested = vest.vestedAmount(block.timestamp);
        assertEq(vested, TEAM_ALLOCATION / 2);
        vest.release();
        assertEq(token.balanceOf(teamWallet), TEAM_ALLOCATION / 2);
    }

    function test_fullyVestedAt48Months() public {
        vm.warp(vest.vestEnd());
        assertEq(vest.vestedAmount(block.timestamp), TEAM_ALLOCATION);
        vest.release();
        assertEq(token.balanceOf(teamWallet), TEAM_ALLOCATION);
        assertEq(token.balanceOf(address(vest)), 0);
    }

    function test_onlySendsToBeneficiary() public {
        vm.warp(vest.vestEnd());
        vest.release();
        assertEq(token.balanceOf(teamWallet), TEAM_ALLOCATION);
        assertEq(token.balanceOf(stranger), 0);
        assertEq(token.balanceOf(launch), 0);
    }

    function test_noAdminShortenRevokeExitOrSendUnreleased() public {
        address v = address(vest);
        assertNoSelector(v, abi.encodeWithSignature("owner()"));
        assertNoSelector(v, abi.encodeWithSignature("shorten(uint256)", uint256(1)));
        assertNoSelector(v, abi.encodeWithSignature("revoke()"));
        assertNoSelector(v, abi.encodeWithSignature("exit()"));
        assertNoSelector(v, abi.encodeWithSignature("sendUnreleasedToDead()"));
        assertNoSelector(v, abi.encodeWithSignature("kill()"));
        assertEq(token.balanceOf(v), TEAM_ALLOCATION);
    }

    function test_killDoesNotUnlockOrBurn() public {
        (bool ok,) = address(vest).call(abi.encodeWithSignature("kill()"));
        assertFalse(ok);
        vm.warp(vest.start() + 90 days);
        vm.expectRevert(TeamVestLock.NothingToRelease.selector);
        vest.release();
        assertEq(token.balanceOf(address(vest)), TEAM_ALLOCATION);
        assertEq(token.totalSupply(), token.TOTAL_SUPPLY());
    }

    function test_fuzz_vestedMonotonic(uint256 t1, uint256 t2) public view {
        t1 = bound(t1, vest.start(), vest.start() + vest.DURATION() + 30 days);
        t2 = bound(t2, t1, vest.start() + vest.DURATION() + 60 days);
        assertLe(vest.vestedAmount(t1), vest.vestedAmount(t2));
    }
}
