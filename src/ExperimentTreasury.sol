// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 * @title ExperimentTreasury
 * @dev Distinct treasury address. GRKN may leave ONLY via:
 *      (a) dust to a constructor-frozen recipient set, under 100 GRKN/tx, 1_000 GRKN/week,
 *          and 5_000 GRKN lifetime, with a reason string and event; OR
 *      (b) the documented dead address (same sink at experiment end / T+90d, or earlier).
 *      There is no third GRKN destination and no delayed GRKN-to-arbitrary-wallet path.
 *
 *      The 7-day delay applies to pairing assets (native ETH or WETH) only. Pairing leftovers
 *      have no dust exception. One immutable proposer key. This is not OpenZeppelin
 *      TimelockController: there is no DEFAULT_ADMIN_ROLE and no `updateDelay`.
 */
contract ExperimentTreasury {
    using SafeERC20 for IERC20;

    uint256 public constant DUST_PER_TX = 100 * 10 ** 18;
    uint256 public constant DUST_PER_WEEK = 1000 * 10 ** 18;
    uint256 public constant DUST_LIFETIME = 5000 * 10 ** 18;
    uint256 public constant PAIRING_DELAY = 7 days;
    uint256 public constant EXPERIMENT_DURATION = 90 days;

    IERC20 public immutable grkn;
    address public immutable weth;
    address public immutable dead;
    address public immutable proposer;
    uint256 public immutable start;

    mapping(address => bool) public isDustRecipient;
    address[] private _dustRecipients;

    uint256 public weeklyDustUsed;
    uint256 public weekStart;
    uint256 public lifetimeDustUsed;

    struct PairingProposal {
        address token; // address(0) = native ETH; otherwise must be `weth`
        address to;
        uint256 amount;
        uint256 eta;
        bool exists;
    }

    PairingProposal public pendingPairing;

    error ZeroAddress();
    error NotProposer();
    error NotDustRecipient();
    error DustCapTx();
    error DustCapWeek();
    error DustCapLifetime();
    error EmptyReason();
    error ZeroAmount();
    error BadPairingToken();
    error PendingExists();
    error NoPending();
    error DelayNotMet(uint256 eta, uint256 now_);
    error InsufficientPairing();
    error PairingTransferFailed();
    error ExperimentNotEnded();

    event DustRecipientFrozen(address indexed recipient);
    event DustSent(address indexed to, uint256 amount, string reason);
    event GrknSentToDead(address indexed dead, uint256 amount);
    event PairingProposed(address indexed token, address indexed to, uint256 amount, uint256 eta);
    event PairingExecuted(address indexed token, address indexed to, uint256 amount);

    modifier onlyProposer() {
        if (msg.sender != proposer) revert NotProposer();
        _;
    }

    /**
     * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
     * @param grkn_ GRKN token. Distinct from this contract.
     * @param weth_ Pairing-asset ERC-20 (canonical WETH on the chosen chain).
     * @param dead_ Documented burn/sink address.
     * @param proposer_ Sole proposer key for dust and pairing proposals. Immutable.
     * @param dustRecipients_ Frozen recipient set. Empty is valid (dust unused; only dead remains).
     */
    constructor(address grkn_, address weth_, address dead_, address proposer_, address[] memory dustRecipients_) {
        if (grkn_ == address(0) || weth_ == address(0) || dead_ == address(0) || proposer_ == address(0)) {
            revert ZeroAddress();
        }

        grkn = IERC20(grkn_);
        weth = weth_;
        dead = dead_;
        proposer = proposer_;
        start = block.timestamp;
        weekStart = block.timestamp;

        uint256 len = dustRecipients_.length;
        for (uint256 i = 0; i < len; i++) {
            address r = dustRecipients_[i];
            if (r == address(0) || r == dead_ || r == address(this) || r == grkn_ || r == weth_) revert ZeroAddress();
            if (isDustRecipient[r]) revert NotDustRecipient(); // duplicate
            isDustRecipient[r] = true;
            _dustRecipients.push(r);
            emit DustRecipientFrozen(r);
        }
    }

    receive() external payable {}

    function dustRecipientCount() external view returns (uint256) {
        return _dustRecipients.length;
    }

    function dustRecipientAt(uint256 index) external view returns (address) {
        return _dustRecipients[index];
    }

    function experimentEnd() public view returns (uint256) {
        return start + EXPERIMENT_DURATION;
    }

    /**
     * @notice Send dust GRKN to a frozen recipient. Proposer only. Limits: 100/tx, 1_000/week, 5_000 lifetime.
     */
    function sendDust(address to, uint256 amount, string calldata reason) external onlyProposer {
        if (!isDustRecipient[to]) revert NotDustRecipient();
        if (amount == 0) revert ZeroAmount();
        if (amount > DUST_PER_TX) revert DustCapTx();
        if (bytes(reason).length == 0) revert EmptyReason();

        _rollDustWeek();
        if (weeklyDustUsed + amount > DUST_PER_WEEK) revert DustCapWeek();
        if (lifetimeDustUsed + amount > DUST_LIFETIME) revert DustCapLifetime();

        weeklyDustUsed += amount;
        lifetimeDustUsed += amount;

        grkn.safeTransfer(to, amount);
        emit DustSent(to, amount, reason);
    }

    /**
     * @notice Send unused GRKN to the documented dead address. Proposer only.
     * @dev Early unused-remainder path. Not a public grief button on the treasury bag.
     */
    function sendGrknToDead(uint256 amount) external onlyProposer {
        if (amount == 0) revert ZeroAmount();
        grkn.safeTransfer(dead, amount);
        emit GrknSentToDead(dead, amount);
    }

    /**
     * @notice After T+90d, anyone may send the remaining GRKN balance to dead.
     */
    function sendRemainingGrknToDead() external {
        if (block.timestamp < experimentEnd()) revert ExperimentNotEnded();
        uint256 amount = grkn.balanceOf(address(this));
        if (amount == 0) revert ZeroAmount();
        grkn.safeTransfer(dead, amount);
        emit GrknSentToDead(dead, amount);
    }

    /**
     * @notice Propose a pairing-asset (ETH or WETH) withdrawal. 7-day delay. One pending. Proposer only.
     * @dev Replaces nothing: reverts if a proposal is already pending (conservative; does not reset delay).
     *      Destination is chosen by the proposer. Documented in AUDIT.md as an operator pairing capability,
     *      not a GRKN destination.
     */
    function proposePairingWithdraw(address token, address to, uint256 amount) external onlyProposer {
        if (pendingPairing.exists) revert PendingExists();
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (token != address(0) && token != weth) revert BadPairingToken();

        uint256 eta = block.timestamp + PAIRING_DELAY;
        pendingPairing = PairingProposal({token: token, to: to, amount: amount, eta: eta, exists: true});
        emit PairingProposed(token, to, amount, eta);
    }

    /**
     * @notice Execute a matured pairing-asset proposal. Anyone may execute. No dust exception.
     */
    function executePairingWithdraw() external {
        PairingProposal memory p = pendingPairing;
        if (!p.exists) revert NoPending();
        if (block.timestamp < p.eta) revert DelayNotMet(p.eta, block.timestamp);

        delete pendingPairing;

        if (p.token == address(0)) {
            if (address(this).balance < p.amount) revert InsufficientPairing();
            (bool ok,) = p.to.call{value: p.amount}("");
            if (!ok) revert PairingTransferFailed();
        } else {
            if (IERC20(p.token).balanceOf(address(this)) < p.amount) revert InsufficientPairing();
            IERC20(p.token).safeTransfer(p.to, p.amount);
        }

        emit PairingExecuted(p.token, p.to, p.amount);
    }

    function _rollDustWeek() internal {
        if (block.timestamp >= weekStart + 7 days) {
            weekStart = block.timestamp;
            weeklyDustUsed = 0;
        }
    }
}
