// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {MockLpToken} from "../script/testnet/MockLpToken.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 * @dev Guards the testnet-only mock LP. Not a protocol contract test.
 */
contract MockLpTokenTest is Test {
    function test_mintsToDeployerOnNonMainnet() public {
        MockLpToken lp = new MockLpToken(1_000 ether);
        assertEq(lp.name(), "Groken Mock LP (TESTNET ONLY)");
        assertEq(lp.symbol(), "MOCKLP-TESTNET");
        assertEq(lp.balanceOf(address(this)), 1_000 ether);
    }

    function test_revertsZeroAmount() public {
        vm.expectRevert(MockLpToken.ZeroAmount.selector);
        new MockLpToken(0);
    }

    function test_refusesBaseMainnet8453() public {
        vm.chainId(8453);
        vm.expectRevert(MockLpToken.MainnetForbidden.selector);
        new MockLpToken(1 ether);
    }
}
