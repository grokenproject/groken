// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {GrokenToken} from "../../src/GrokenToken.sol";
import {ImmutableLPLock} from "../../src/ImmutableLPLock.sol";
import {ExperimentTreasury} from "../../src/ExperimentTreasury.sol";
import {TeamVestLock} from "../../src/TeamVestLock.sol";
import {ListingReserve} from "../../src/ListingReserve.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockWETH} from "../mocks/MockWETH.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 */
abstract contract Fixture is Test {
    uint256 internal constant AMM_ALLOCATION = 80_000_000 ether;
    uint256 internal constant TEAM_ALLOCATION = 10_000_000 ether;
    uint256 internal constant TREASURY_ALLOCATION = 5_000_000 ether;
    uint256 internal constant LISTING_ALLOCATION = 5_000_000 ether;
    uint256 internal constant LP_LOCKED = 1000 ether;

    address internal launch;
    address internal teamWallet;
    address internal proposer;
    address internal dead;
    address internal ammRecipient;
    address internal dustDemo;
    address internal listingFeeDest;
    address internal mmDest;
    address internal lpBeneficiary;
    address internal stranger;

    GrokenToken internal token;
    TeamVestLock internal vest;
    ExperimentTreasury internal treasury;
    ListingReserve internal listing;
    ImmutableLPLock internal locker;
    MockERC20 internal lpToken;
    MockWETH internal weth;

    uint256 internal vestStart;
    uint256 internal treasuryStart;
    uint256 internal listingStart;
    uint256 internal lockerUnlock;

    function setUp() public virtual {
        launch = makeAddr("launch");
        teamWallet = makeAddr("teamWallet");
        proposer = makeAddr("proposer");
        dead = address(0x000000000000000000000000000000000000dEaD);
        ammRecipient = makeAddr("ammRecipient");
        dustDemo = makeAddr("dustDemo");
        listingFeeDest = makeAddr("listingFeeDest");
        mmDest = makeAddr("mmDest");
        lpBeneficiary = makeAddr("lpBeneficiary");
        stranger = makeAddr("stranger");

        weth = new MockWETH();
        lpToken = new MockERC20("Mock LP", "mLP");

        vm.prank(launch);
        token = new GrokenToken(launch);

        vestStart = block.timestamp;
        vest = new TeamVestLock(address(token), teamWallet);

        address[] memory dustRecipients = new address[](1);
        dustRecipients[0] = dustDemo;
        treasuryStart = block.timestamp;
        treasury = new ExperimentTreasury(address(token), address(weth), dead, proposer, dustRecipients);

        lpToken.mint(launch, LP_LOCKED);
        locker = _deployLocker(launch, address(lpToken), lpBeneficiary, LP_LOCKED);
        lockerUnlock = locker.unlockTime();

        address[] memory allowlist = new address[](2);
        allowlist[0] = listingFeeDest;
        allowlist[1] = mmDest;
        address[] memory projectAddresses = new address[](6);
        projectAddresses[0] = address(token);
        projectAddresses[1] = address(vest);
        projectAddresses[2] = address(treasury);
        projectAddresses[3] = teamWallet;
        projectAddresses[4] = ammRecipient;
        projectAddresses[5] = address(locker);
        listingStart = block.timestamp;
        listing = new ListingReserve(address(token), dead, proposer, allowlist, projectAddresses);
    }

    /// @dev approve consumes nonce N; CREATE uses N+1.
    function _deployLocker(address deployer, address lp, address beneficiary, uint256 amount)
        internal
        returns (ImmutableLPLock deployed)
    {
        address predicted = vm.computeCreateAddress(deployer, vm.getNonce(deployer) + 1);
        vm.prank(deployer);
        IERC20(lp).approve(predicted, amount);
        vm.prank(deployer);
        deployed = new ImmutableLPLock(lp, beneficiary, amount);
    }

    function runLaunchDistribution() internal {
        vm.startPrank(launch);
        token.transfer(address(vest), TEAM_ALLOCATION);
        token.transfer(address(treasury), TREASURY_ALLOCATION);
        token.transfer(address(listing), LISTING_ALLOCATION);
        token.transfer(ammRecipient, AMM_ALLOCATION);
        vm.stopPrank();
    }

    function assertNoSelector(address target, bytes memory data) internal {
        (bool ok,) = target.call(data);
        assertFalse(ok, "admin selector must not succeed");
    }
}
