// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 * @title TeamVestLock
 * @dev Vest-survives (frozen). The 10M team allocation is locked in this contract, not in a hot
 *      wallet. The published team wallet is the beneficiary of `release()`, not the vest itself.
 *
 *      Schedule: 0% TGE; 12-month cliff; then 36-month linear; fully vested at start + 48 months.
 *      `release()` sends only to the immutable beneficiary. No admin shorten, revoke, exit,
 *      or `sendUnreleasedToDead`. Kill / experiment end does not unlock, accelerate, or burn.
 *
 *      Operator economic interest outlives the 90-day experiment. This is a disclosure, not a
 *      claim of alignment.
 */
contract TeamVestLock {
    using SafeERC20 for IERC20;

    /// @notice 12-month cliff, using 365-day years (see AUDIT.md).
    uint256 public constant CLIFF = 365 days;
    /// @notice Fully vested at start + 48 months (4 * 365 days).
    uint256 public constant DURATION = 4 * 365 days;

    IERC20 public immutable token;
    address public immutable beneficiary;
    uint256 public immutable start;
    uint256 public released;

    error ZeroAddress();
    error NothingToRelease();

    event Released(address indexed beneficiary, uint256 amount);

    /**
     * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
     */
    constructor(address token_, address beneficiary_) {
        if (token_ == address(0) || beneficiary_ == address(0)) revert ZeroAddress();
        token = IERC20(token_);
        beneficiary = beneficiary_;
        start = block.timestamp;
    }

    function cliffEnd() public view returns (uint256) {
        return start + CLIFF;
    }

    function vestEnd() public view returns (uint256) {
        return start + DURATION;
    }

    /**
     * @notice Tokens vested as of `timestamp`, based on current balance plus already released.
     * @dev Before the cliff: 0. At the exact cliff instant: 0 (linear starts after the cliff).
     *      After `start + DURATION`: 100% of (balance + released).
     */
    function vestedAmount(uint256 timestamp) public view returns (uint256) {
        uint256 total = token.balanceOf(address(this)) + released;
        if (timestamp < start + CLIFF) return 0;
        if (timestamp >= start + DURATION) return total;
        uint256 linearStart = start + CLIFF;
        uint256 linearDuration = DURATION - CLIFF;
        return (total * (timestamp - linearStart)) / linearDuration;
    }

    function releasable() public view returns (uint256) {
        uint256 vested = vestedAmount(block.timestamp);
        if (vested <= released) return 0;
        return vested - released;
    }

    /**
     * @notice Release vested GRKN to the immutable published team wallet. Anyone may call.
     */
    function release() external {
        uint256 amount = releasable();
        if (amount == 0) revert NothingToRelease();
        released += amount;
        token.safeTransfer(beneficiary, amount);
        emit Released(beneficiary, amount);
    }
}
