// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {GrokenToken} from "../src/GrokenToken.sol";
import {ImmutableLPLock} from "../src/ImmutableLPLock.sol";
import {ExperimentTreasury} from "../src/ExperimentTreasury.sol";
import {TeamVestLock} from "../src/TeamVestLock.sol";
import {ListingReserve} from "../src/ListingReserve.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 * @title LaunchBatchScript
 * @dev Documents the Phase 1 launch batch. This script does not invent addresses and is not a
 *      mainnet deploy. It refuses chain id 8453. Optional Base Sepolia use requires a throwaway
 *      key and a public RPC supplied by the operator — this repository ships neither.
 *
 *      GrokenToken's constructor still mints 100% to `initialHolder`. This script is the
 *      documented distribution; the token does not encode the batch.
 *
 *      Intended post-batch GRKN balances:
 *        - 80_000_000 to the caller-supplied AMM recipient (pool created out of band)
 *        - 10_000_000 to TeamVestLock (the vest — not the published team wallet)
 *        -  5_000_000 to ExperimentTreasury
 *        -  5_000_000 to ListingReserve
 *        - initialHolder / throwaway deployer = 0
 *
 *      LP tokens (created out of band) are approved and pulled into ImmutableLPLock.
 *
 *      Required env (no live-looking defaults):
 *        INITIAL_HOLDER, TEAM_WALLET, PROPOSER, DEAD, PAIRING_BENEFICIARY, WETH, AMM_RECIPIENT
 *        DUST_RECIPIENTS (comma-separated; may be empty)
 *        LISTING_ALLOWLIST (comma-separated; may be empty)
 *        LP_TOKEN, LP_AMOUNT, LP_BENEFICIARY
 *
 *      Broadcast is gated on CONFIRM_LAUNCH_BATCH=YES. Without it, the script only prints the plan.
 */
contract LaunchBatchScript is Script {
    uint256 public constant AMM_ALLOCATION = 80_000_000 * 10 ** 18;
    uint256 public constant TEAM_ALLOCATION = 10_000_000 * 10 ** 18;
    uint256 public constant TREASURY_ALLOCATION = 5_000_000 * 10 ** 18;
    uint256 public constant LISTING_ALLOCATION = 5_000_000 * 10 ** 18;

    struct Plan {
        address initialHolder;
        address teamWallet;
        address proposer;
        address dead;
        address pairingBeneficiary;
        address weth;
        address ammRecipient;
        address lpToken;
        address lpBeneficiary;
        uint256 lpAmount;
        address[] dustRecipients;
        address[] allowlist;
    }

    function run() external {
        Plan memory p = _readPlan();
        _logPlan(p);

        if (!_eq(vm.envOr("CONFIRM_LAUNCH_BATCH", string("NO")), "YES")) {
            console2.log("CONFIRM_LAUNCH_BATCH != YES; not broadcasting.");
            return;
        }
        if (block.chainid == 8453) revert("Refusing Base mainnet (8453).");

        _broadcast(p);
    }

    function _readPlan() internal view returns (Plan memory p) {
        p.initialHolder = _req("INITIAL_HOLDER");
        p.teamWallet = _req("TEAM_WALLET");
        p.proposer = _req("PROPOSER");
        p.dead = _req("DEAD");
        p.pairingBeneficiary = _req("PAIRING_BENEFICIARY");
        p.weth = _req("WETH");
        p.ammRecipient = _req("AMM_RECIPIENT");
        p.lpToken = _req("LP_TOKEN");
        p.lpBeneficiary = _req("LP_BENEFICIARY");
        p.lpAmount = vm.envUint("LP_AMOUNT");
        if (p.lpAmount == 0) revert("LP_AMOUNT must be > 0");
        p.dustRecipients = _csv("DUST_RECIPIENTS");
        p.allowlist = _csv("LISTING_ALLOWLIST");
    }

    function _logPlan(Plan memory p) internal pure {
        console2.log("Launch batch plan (not a mainnet deploy).");
        console2.log("initialHolder", p.initialHolder);
        console2.log("teamWallet (beneficiary, not the vest)", p.teamWallet);
        console2.log("proposer", p.proposer);
        console2.log("dead", p.dead);
        console2.log("pairingBeneficiary (pairing ETH/WETH only)", p.pairingBeneficiary);
        console2.log("weth", p.weth);
        console2.log("ammRecipient (80M GRKN; pool created out of band)", p.ammRecipient);
        console2.log("lpToken", p.lpToken);
        console2.log("lpBeneficiary", p.lpBeneficiary);
        console2.log("lpAmount", p.lpAmount);
    }

    function _broadcast(Plan memory p) internal {
        vm.startBroadcast();

        GrokenToken token = new GrokenToken(p.initialHolder);
        TeamVestLock vest = new TeamVestLock(address(token), p.teamWallet);
        ExperimentTreasury treasury =
            new ExperimentTreasury(address(token), p.weth, p.dead, p.proposer, p.pairingBeneficiary, p.dustRecipients);
        // Locker before listing so the locker address is on the listing project-blocklist.
        ImmutableLPLock locker = _lockLp(p);
        ListingReserve listing = _deployListing(token, vest, treasury, locker, p);
        _distribute(token, vest, treasury, listing, p);

        vm.stopBroadcast();
        _requireEmptyHolder(address(token), p.initialHolder);
        _logDeployed(address(token), address(vest), address(treasury), address(listing), address(locker));
    }

    function _deployListing(
        GrokenToken token,
        TeamVestLock vest,
        ExperimentTreasury treasury,
        ImmutableLPLock locker,
        Plan memory p
    ) internal returns (ListingReserve listing) {
        address[] memory projectAddresses = new address[](6);
        projectAddresses[0] = address(token);
        projectAddresses[1] = address(vest);
        projectAddresses[2] = address(treasury);
        projectAddresses[3] = p.teamWallet;
        projectAddresses[4] = p.ammRecipient;
        projectAddresses[5] = address(locker);
        listing = new ListingReserve(address(token), p.dead, p.proposer, p.allowlist, projectAddresses);
    }

    function _distribute(
        GrokenToken token,
        TeamVestLock vest,
        ExperimentTreasury treasury,
        ListingReserve listing,
        Plan memory p
    ) internal {
        // Signer must be `initialHolder` so these transfers succeed.
        token.transfer(address(vest), TEAM_ALLOCATION);
        token.transfer(address(treasury), TREASURY_ALLOCATION);
        token.transfer(address(listing), LISTING_ALLOCATION);
        token.transfer(p.ammRecipient, AMM_ALLOCATION);
    }

    function _lockLp(Plan memory p) internal returns (ImmutableLPLock locker) {
        // approve consumes nonce N; CREATE uses N+1.
        address predictedLocker = vm.computeCreateAddress(msg.sender, vm.getNonce(msg.sender) + 1);
        IERC20(p.lpToken).approve(predictedLocker, p.lpAmount);
        locker = new ImmutableLPLock(p.lpToken, p.lpBeneficiary, p.lpAmount);
    }

    function _requireEmptyHolder(address token, address initialHolder) internal view {
        if (IERC20(token).balanceOf(initialHolder) != 0) {
            revert("initialHolder is not zero after the batch");
        }
    }

    function _logDeployed(address token, address vest, address treasury, address listing, address locker)
        internal
        pure
    {
        console2.log("GrokenToken", token);
        console2.log("TeamVestLock", vest);
        console2.log("ExperimentTreasury", treasury);
        console2.log("ListingReserve", listing);
        console2.log("ImmutableLPLock", locker);
    }

    function _req(string memory key) internal view returns (address) {
        address a = vm.envAddress(key);
        if (a == address(0)) revert(string.concat(key, " is address(0); refusing to invent"));
        return a;
    }

    function _csv(string memory key) internal view returns (address[] memory out) {
        string memory raw = vm.envOr(key, string(""));
        if (bytes(raw).length == 0) {
            return new address[](0);
        }
        uint256 n = 1;
        bytes memory b = bytes(raw);
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == ",") n++;
        }
        out = new address[](n);
        uint256 idx = 0;
        uint256 start_ = 0;
        for (uint256 i = 0; i <= b.length; i++) {
            if (i == b.length || b[i] == ",") {
                out[idx] = vm.parseAddress(_trim(string(_slice(b, start_, i))));
                if (out[idx] == address(0)) revert("csv contains address(0)");
                idx++;
                start_ = i + 1;
            }
        }
    }

    function _slice(bytes memory b, uint256 start_, uint256 end) internal pure returns (bytes memory out) {
        out = new bytes(end - start_);
        for (uint256 i = 0; i < out.length; i++) {
            out[i] = b[start_ + i];
        }
    }

    function _trim(string memory s) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        uint256 i = 0;
        uint256 j = b.length;
        while (i < j && b[i] == 0x20) i++;
        while (j > i && b[j - 1] == 0x20) j--;
        return string(_slice(b, i, j));
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
