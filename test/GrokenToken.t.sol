// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Fixture} from "./helpers/Fixture.sol";
import {GrokenToken} from "../src/GrokenToken.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 */
contract GrokenTokenTest is Fixture {
    function setUp() public override {
        super.setUp();
    }

    function test_metadata() public view {
        assertEq(token.name(), "Groken");
        assertEq(token.symbol(), "GRKN");
        assertEq(token.decimals(), 18);
        assertEq(token.TOTAL_SUPPLY(), 100_000_000 ether);
        assertEq(token.totalSupply(), token.TOTAL_SUPPLY());
    }

    function test_constructorMintsAllToInitialHolder() public view {
        assertEq(token.balanceOf(launch), token.TOTAL_SUPPLY());
    }

    function test_constructorRejectsZero() public {
        vm.expectRevert(GrokenToken.ZeroInitialHolder.selector);
        new GrokenToken(address(0));
    }

    function test_noAdminSelectors() public {
        address t = address(token);
        assertNoSelector(t, abi.encodeWithSignature("owner()"));
        assertNoSelector(t, abi.encodeWithSignature("mint(address,uint256)", launch, uint256(1)));
        assertNoSelector(t, abi.encodeWithSignature("burn(uint256)", uint256(1)));
        assertNoSelector(t, abi.encodeWithSignature("pause()"));
        assertNoSelector(t, abi.encodeWithSignature("blacklist(address)", launch));
        assertNoSelector(t, abi.encodeWithSignature("permit(address,address,uint256,uint256,uint8,bytes32,bytes32)"));
        assertEq(token.totalSupply(), token.TOTAL_SUPPLY());
    }

    function test_transferDoesNotChangeSupply(address to, uint256 amount) public {
        vm.assume(to != address(0));
        amount = bound(amount, 0, token.balanceOf(launch));
        vm.prank(launch);
        token.transfer(to, amount);
        assertEq(token.totalSupply(), token.TOTAL_SUPPLY());
    }
}
