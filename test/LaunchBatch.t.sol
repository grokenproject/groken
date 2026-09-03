// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Fixture} from "./helpers/Fixture.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 */
contract LaunchBatchTest is Fixture {
    function setUp() public override {
        super.setUp();
        runLaunchDistribution();
    }

    function test_allocationAndEmptyHolder() public view {
        assertEq(token.balanceOf(ammRecipient), AMM_ALLOCATION);
        assertEq(token.balanceOf(address(vest)), TEAM_ALLOCATION);
        assertEq(token.balanceOf(address(treasury)), TREASURY_ALLOCATION);
        assertEq(token.balanceOf(address(listing)), LISTING_ALLOCATION);
        assertEq(token.balanceOf(launch), 0);
        assertEq(token.balanceOf(teamWallet), 0);
        assertEq(token.totalSupply(), token.TOTAL_SUPPLY());
        assertEq(AMM_ALLOCATION + TEAM_ALLOCATION + TREASURY_ALLOCATION + LISTING_ALLOCATION, token.TOTAL_SUPPLY());
    }

    function test_deployerIsNotAHiddenHolder() public view {
        // Token deployer was `launch`. After the batch it holds zero.
        // This test does not encode a fake in-constructor batch; distribution is explicit transfers.
        assertEq(token.balanceOf(launch), 0);
    }

    function test_lpIsInLocker() public view {
        assertEq(lpToken.balanceOf(address(locker)), LP_LOCKED);
        assertEq(lpToken.balanceOf(launch), 0);
    }

    function test_tenMillionIsInVestNotTeamWallet() public view {
        assertEq(token.balanceOf(address(vest)), 10_000_000 ether);
        assertEq(token.balanceOf(teamWallet), 0);
    }
}
