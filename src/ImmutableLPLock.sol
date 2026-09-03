// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 * @title ImmutableLPLock
 * @dev Admin-off LP locker. Constructor sets an immutable beneficiary, sets
 *      `unlockTime = block.timestamp + 90 days`, and pulls `amount` of the LP token from the caller.
 *      The only state-changing function is `release()`, which sends the entire LP balance to the
 *      beneficiary after `unlockTime`.
 *
 *      There is no owner, pause, extend, shorten, emergency withdraw, or kill function.
 *      Kill is not a function on this contract and does not unlock early.
 *
 *      H1(d) FLAG — pairing-asset return path (not museum-only):
 *      After `unlockTime`, `release()` returns the LP token (the pairing-asset claim, typically
 *      a DEX pair token representing Groken + ETH/WETH) to `beneficiary`. This is intentional.
 *      This locker is not a forever museum lock. Do not treat `release()` as missing functionality.
 */
contract ImmutableLPLock {
    using SafeERC20 for IERC20;

    IERC20 public immutable lpToken;
    address public immutable beneficiary;
    uint256 public immutable unlockTime;

    uint256 public constant LOCK_DURATION = 90 days;

    error ZeroAddress();
    error ZeroAmount();
    error StillLocked(uint256 unlockTime_, uint256 now_);
    error Empty();

    event Locked(address indexed lpToken, address indexed beneficiary, uint256 amount, uint256 unlockTime);
    event Released(address indexed beneficiary, uint256 amount);

    /**
     * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
     */
    constructor(address lpToken_, address beneficiary_, uint256 amount) {
        if (lpToken_ == address(0) || beneficiary_ == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        lpToken = IERC20(lpToken_);
        beneficiary = beneficiary_;
        unlockTime = block.timestamp + LOCK_DURATION;

        IERC20(lpToken_).safeTransferFrom(msg.sender, address(this), amount);
        emit Locked(lpToken_, beneficiary_, amount, unlockTime);
    }

    /**
     * @notice After `unlockTime`, send the entire LP balance to the immutable beneficiary.
     * @dev H1(d): this is the pairing-asset return path. Anyone may call it; funds only go to `beneficiary`.
     */
    function release() external {
        if (block.timestamp < unlockTime) revert StillLocked(unlockTime, block.timestamp);
        uint256 amount = lpToken.balanceOf(address(this));
        if (amount == 0) revert Empty();
        lpToken.safeTransfer(beneficiary, amount);
        emit Released(beneficiary, amount);
    }
}
