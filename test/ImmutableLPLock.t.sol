// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Fixture} from "./helpers/Fixture.sol";
import {ImmutableLPLock} from "../src/ImmutableLPLock.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 */
contract ImmutableLPLockTest is Fixture {
    function setUp() public override {
        super.setUp();
    }

    function test_constructorPullsLpAndSetsUnlock() public view {
        assertEq(lpToken.balanceOf(address(locker)), LP_LOCKED);
        assertEq(locker.beneficiary(), lpBeneficiary);
        assertEq(locker.unlockTime(), block.timestamp + 90 days);
        assertEq(address(locker.lpToken()), address(lpToken));
    }

    function test_constructorRejectsZero() public {
        vm.expectRevert(ImmutableLPLock.ZeroAddress.selector);
        new ImmutableLPLock(address(0), lpBeneficiary, 1);
        vm.expectRevert(ImmutableLPLock.ZeroAddress.selector);
        new ImmutableLPLock(address(lpToken), address(0), 1);
        vm.expectRevert(ImmutableLPLock.ZeroAmount.selector);
        new ImmutableLPLock(address(lpToken), lpBeneficiary, 0);
    }

    function test_cannotReleaseBeforeUnlock() public {
        vm.expectRevert(
            abi.encodeWithSelector(ImmutableLPLock.StillLocked.selector, locker.unlockTime(), block.timestamp)
        );
        locker.release();
    }

    function test_fuzz_cannotReleaseEarly(uint256 dt) public {
        dt = bound(dt, 0, 90 days - 1);
        vm.warp(block.timestamp + dt);
        vm.expectRevert();
        locker.release();
        assertEq(lpToken.balanceOf(address(locker)), LP_LOCKED);
        assertEq(lpToken.balanceOf(lpBeneficiary), 0);
    }

    function test_releaseAfterUnlockSendsToBeneficiary() public {
        vm.warp(locker.unlockTime());
        locker.release();
        assertEq(lpToken.balanceOf(address(locker)), 0);
        assertEq(lpToken.balanceOf(lpBeneficiary), LP_LOCKED);
    }

    function test_releaseAfterUnlockPlusOne() public {
        vm.warp(locker.unlockTime() + 1);
        locker.release();
        assertEq(lpToken.balanceOf(lpBeneficiary), LP_LOCKED);
    }

    function test_releaseEmptyReverts() public {
        vm.warp(locker.unlockTime());
        locker.release();
        vm.expectRevert(ImmutableLPLock.Empty.selector);
        locker.release();
    }

    function test_noOwnerPauseExtendEmergency() public {
        address l = address(locker);
        assertNoSelector(l, abi.encodeWithSignature("owner()"));
        assertNoSelector(l, abi.encodeWithSignature("pause()"));
        assertNoSelector(l, abi.encodeWithSignature("extend(uint256)", uint256(1)));
        assertNoSelector(l, abi.encodeWithSignature("shorten(uint256)", uint256(1)));
        assertNoSelector(l, abi.encodeWithSignature("emergencyWithdraw()"));
        assertNoSelector(l, abi.encodeWithSignature("kill()"));
        assertEq(lpToken.balanceOf(l), LP_LOCKED);
    }

    function test_killIsNotAFunctionAndDoesNotUnlockEarly() public {
        (bool ok,) = address(locker).call(abi.encodeWithSignature("kill()"));
        assertFalse(ok);
        vm.expectRevert();
        locker.release();
    }
}
