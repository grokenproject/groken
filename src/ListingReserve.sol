// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 * @title ListingReserve
 * @dev Immutable allowlist at deploy (empty allowlist is valid). This contract is never an AMM
 *      and has no swap / addLiquidity surface. Transfers to constructor-frozen project addresses
 *      hard-revert. `proposeTransfer` takes purpose `ListingFee` or `MMInventory`, a 7-day delay,
 *      and at most one pending proposal. `executeTransfer` reverts after start+90d (no post-kill
 *      execute; pending-before-90 die). `sendToDead` is available anytime. After start+90d, new
 *      proposes revert and remainder-to-dead is permissionless. Unused GRKN goes to dead.
 *      There is no leftover-deal exception.
 */
contract ListingReserve {
    using SafeERC20 for IERC20;

    enum Purpose {
        ListingFee,
        MMInventory
    }

    uint256 public constant DELAY = 7 days;
    uint256 public constant EXPERIMENT_DURATION = 90 days;

    IERC20 public immutable token;
    address public immutable dead;
    address public immutable proposer;
    uint256 public immutable start;

    mapping(address => bool) public allowlisted;
    mapping(address => bool) public projectBlocked;

    struct Pending {
        address to;
        uint256 amount;
        Purpose purpose;
        uint256 eta;
        bool exists;
    }

    Pending public pending;

    error ZeroAddress();
    error NotProposer();
    error NotAllowlisted();
    error ProjectAddress();
    error ZeroAmount();
    error PendingExists();
    error NoPending();
    error DelayNotMet(uint256 eta, uint256 now_);
    error ExperimentEnded();
    error ExperimentNotEnded();
    error BadPurpose();

    event Allowlisted(address indexed account);
    event ProjectBlocked(address indexed account);
    event TransferProposed(address indexed to, uint256 amount, Purpose purpose, uint256 eta);
    event TransferExecuted(address indexed to, uint256 amount, Purpose purpose);
    event SentToDead(address indexed dead, uint256 amount);

    modifier onlyProposer() {
        if (msg.sender != proposer) revert NotProposer();
        _;
    }

    /**
     * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
     * @param token_ GRKN.
     * @param dead_ Documented sink.
     * @param proposer_ Sole proposer for allowlisted transfers.
     * @param allowlist_ Immutable destinations. Empty is valid.
     * @param projectAddresses_ Frozen blocklist (token, treasury, vest, team wallet, AMM pair, …).
     */
    constructor(
        address token_,
        address dead_,
        address proposer_,
        address[] memory allowlist_,
        address[] memory projectAddresses_
    ) {
        if (token_ == address(0) || dead_ == address(0) || proposer_ == address(0)) {
            revert ZeroAddress();
        }

        token = IERC20(token_);
        dead = dead_;
        proposer = proposer_;
        start = block.timestamp;

        uint256 plen = projectAddresses_.length;
        for (uint256 i = 0; i < plen; i++) {
            address p = projectAddresses_[i];
            if (p == address(0)) revert ZeroAddress();
            projectBlocked[p] = true;
            emit ProjectBlocked(p);
        }

        // Always treat self, token, and dead as non-allowlist destinations.
        projectBlocked[address(this)] = true;
        projectBlocked[token_] = true;
        emit ProjectBlocked(address(this));
        emit ProjectBlocked(token_);

        uint256 alen = allowlist_.length;
        for (uint256 i = 0; i < alen; i++) {
            address a = allowlist_[i];
            if (a == address(0) || a == dead_) revert ZeroAddress();
            if (projectBlocked[a]) revert ProjectAddress();
            if (allowlisted[a]) revert NotAllowlisted(); // duplicate
            allowlisted[a] = true;
            emit Allowlisted(a);
        }
    }

    function experimentEnd() public view returns (uint256) {
        return start + EXPERIMENT_DURATION;
    }

    /**
     * @notice Propose a delayed GRKN transfer to an allowlisted destination with a listed purpose.
     */
    function proposeTransfer(address to, uint256 amount, Purpose purpose) external onlyProposer {
        if (block.timestamp >= experimentEnd()) revert ExperimentEnded();
        if (pending.exists) revert PendingExists();
        if (amount == 0) revert ZeroAmount();
        if (uint256(purpose) > uint256(Purpose.MMInventory)) revert BadPurpose();
        _assertValidTo(to);

        uint256 eta = block.timestamp + DELAY;
        pending = Pending({to: to, amount: amount, purpose: purpose, eta: eta, exists: true});
        emit TransferProposed(to, amount, purpose, eta);
    }

    /**
     * @notice Execute a matured allowlisted transfer. Reverts at or after start+90d; pending proposals die.
     */
    function executeTransfer() external {
        if (block.timestamp >= experimentEnd()) revert ExperimentEnded();
        Pending memory p = pending;
        if (!p.exists) revert NoPending();
        if (block.timestamp < p.eta) revert DelayNotMet(p.eta, block.timestamp);

        _assertValidTo(p.to);
        delete pending;

        token.safeTransfer(p.to, p.amount);
        emit TransferExecuted(p.to, p.amount, p.purpose);
    }

    /**
     * @notice Send GRKN to dead. Permissionless. Available anytime, including before T+90d.
     */
    function sendToDead(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        token.safeTransfer(dead, amount);
        emit SentToDead(dead, amount);
    }

    /**
     * @notice After start+90d, anyone may send the entire remaining GRKN balance to dead.
     */
    function sendRemainderToDead() external {
        if (block.timestamp < experimentEnd()) revert ExperimentNotEnded();
        uint256 amount = token.balanceOf(address(this));
        if (amount == 0) revert ZeroAmount();
        // Drop any dying pending so storage is clean; it cannot execute after T+90d anyway.
        delete pending;
        token.safeTransfer(dead, amount);
        emit SentToDead(dead, amount);
    }

    function _assertValidTo(address to) internal view {
        if (to == address(0) || to == dead) revert ZeroAddress();
        if (projectBlocked[to]) revert ProjectAddress();
        if (!allowlisted[to]) revert NotAllowlisted();
    }
}
