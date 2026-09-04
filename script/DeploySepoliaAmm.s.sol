// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ImmutableLPLock} from "../src/ImmutableLPLock.sol";
import {
    IUniswapV2FactoryMinimal,
    IUniswapV2Router02Minimal,
    IUniswapV2PairMinimal
} from "./uniswap/IUniswapV2Minimal.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 * @title DeploySepoliaAmmScript
 * @dev TESTNET ONLY. Deploys official Uniswap V2 Factory + Router02 on Base Sepolia (84532),
 *      creates GRKN/WETH, moves the 80M stand-in bag into the pair, seeds addLiquidityETH
 *      with leftover deployer ETH, and locks the real pair LP in a new ImmutableLPLock.
 *
 *      feeToSetter = dead so protocol fees cannot be turned on.
 *      Seed ETH is not a valuation. No price / FDV / market-cap commentary.
 *      The previous mock locker is left as-is.
 *
 *      Refuses chain id 8453. Broadcast requires 84532 and CONFIRM_SEPOLIA_AMM=YES.
 *
 *      Env (no live-looking defaults except documented constants):
 *        DEPLOYER_PRIVATE_KEY, AMM_STANDIN_PRIVATE_KEY  (off-repo; never commit)
 *        CONFIRM_SEPOLIA_AMM=YES
 */
contract DeploySepoliaAmmScript is Script {
    address public constant GRKN = 0xDB162864150859787158F7C9Aa092c61479A2F34;
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public constant PAIRING_BENEFICIARY = 0x3F133aD764bbF185d3ab431880273EfDeeaD69e3;
    address public constant AMM_STANDIN = 0xDEFb9e5aF851D04F0ad4FB8357A00a47aCa0e6C1;
    address public constant OLD_MOCK_LOCKER = 0x2441F5b6aa67A4bFE732E08C3ac5152EA3C20A24;
    uint256 public constant GRKN_LIQUIDITY = 80_000_000 * 10 ** 18;
    /// @dev ETH sent to the stand-in so it can transfer 80M GRKN. Residual stays there.
    uint256 public constant STANDIN_GAS = 0.000005 ether;
    /// @dev Held back after deploys for addLiquidity + locker. Not part of the seed.
    uint256 public constant POST_DEPLOY_RESERVE = 0.00004 ether;

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 standinKey = vm.envUint("AMM_STANDIN_PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        address standin = vm.addr(standinKey);

        console2.log("Sepolia AMM plan (TESTNET ONLY). Seed ETH is not a valuation.");
        console2.log("chainid", block.chainid);
        console2.log("deployer", deployer);
        console2.log("standin", standin);
        console2.log("old mock locker (unchanged)", OLD_MOCK_LOCKER);

        if (block.chainid == 8453) revert("Refusing Base mainnet (8453).");
        if (!_eq(vm.envOr("CONFIRM_SEPOLIA_AMM", string("NO")), "YES")) {
            console2.log("CONFIRM_SEPOLIA_AMM != YES; not broadcasting.");
            return;
        }
        if (block.chainid != 84532) revert("Base Sepolia (84532) only.");
        if (standin != AMM_STANDIN) revert("stand-in key does not match documented AMM_STANDIN");
        if (IERC20(GRKN).balanceOf(standin) < GRKN_LIQUIDITY) revert("stand-in GRKN < 80M");

        address factory = _deployFactory(deployerKey);
        address router = _deployRouter(deployerKey, factory);
        address pair = _createPair(deployerKey, factory);
        _pullGrkn(deployerKey, standinKey, deployer, standin);
        (uint256 seedEth, uint256 lpAmount, address locker) = _seedAndLock(deployerKey, deployer, router, pair);

        console2.log("UniswapV2Factory TESTNET", factory);
        console2.log("UniswapV2Router02 TESTNET", router);
        console2.log("GRKN/WETH pair TESTNET", pair);
        console2.log("seed ETH wei (not a valuation)", seedEth);
        console2.log("ImmutableLPLock (real pair LP) TESTNET", locker);
        console2.log("LP locked", lpAmount);
        console2.log("stand-in GRKN after", IERC20(GRKN).balanceOf(standin));
        console2.log("deployer GRKN after", IERC20(GRKN).balanceOf(deployer));
    }

    function _deployFactory(uint256 deployerKey) internal returns (address factory) {
        bytes memory creation =
            abi.encodePacked(_readHex("script/uniswap/bytecode/UniswapV2Factory.hex"), abi.encode(DEAD));
        vm.startBroadcast(deployerKey);
        factory = _create(creation);
        vm.stopBroadcast();
        if (IUniswapV2FactoryMinimal(factory).feeToSetter() != DEAD) revert("feeToSetter is not dead");
    }

    function _deployRouter(uint256 deployerKey, address factory) internal returns (address router) {
        bytes memory creation = abi.encodePacked(
            _readHex("script/uniswap/bytecode/UniswapV2Router02.hex"), abi.encode(factory, WETH)
        );
        vm.startBroadcast(deployerKey);
        router = _create(creation);
        vm.stopBroadcast();
        if (IUniswapV2Router02Minimal(router).factory() != factory) revert("router factory mismatch");
        if (IUniswapV2Router02Minimal(router).WETH() != WETH) revert("router WETH mismatch");
    }

    function _createPair(uint256 deployerKey, address factory) internal returns (address pair) {
        vm.startBroadcast(deployerKey);
        pair = IUniswapV2FactoryMinimal(factory).createPair(GRKN, WETH);
        vm.stopBroadcast();
        if (pair == address(0)) revert("createPair returned zero");
        address t0 = IUniswapV2PairMinimal(pair).token0();
        address t1 = IUniswapV2PairMinimal(pair).token1();
        if (!((t0 == GRKN && t1 == WETH) || (t0 == WETH && t1 == GRKN))) revert("pair tokens mismatch");
    }

    function _pullGrkn(uint256 deployerKey, uint256 standinKey, address deployer, address standin) internal {
        vm.startBroadcast(deployerKey);
        (bool ok,) = payable(standin).call{value: STANDIN_GAS}("");
        if (!ok) revert("stand-in gas transfer failed");
        vm.stopBroadcast();

        vm.startBroadcast(standinKey);
        IERC20(GRKN).transfer(deployer, GRKN_LIQUIDITY);
        vm.stopBroadcast();

        if (IERC20(GRKN).balanceOf(deployer) < GRKN_LIQUIDITY) revert("deployer did not receive 80M");
    }

    function _seedAndLock(uint256 deployerKey, address deployer, address router, address pair)
        internal
        returns (uint256 seedEth, uint256 lpAmount, address locker)
    {
        seedEth = deployer.balance - POST_DEPLOY_RESERVE;
        if (seedEth == 0 || deployer.balance <= POST_DEPLOY_RESERVE) revert("insufficient ETH for seed + reserve");

        vm.startBroadcast(deployerKey);
        IERC20(GRKN).approve(router, GRKN_LIQUIDITY);
        IUniswapV2Router02Minimal(router).addLiquidityETH{value: seedEth}(
            GRKN, GRKN_LIQUIDITY, GRKN_LIQUIDITY, seedEth, deployer, block.timestamp + 1 hours
        );
        lpAmount = IERC20(pair).balanceOf(deployer);
        if (lpAmount == 0) revert("no LP minted to deployer");

        address predicted = vm.computeCreateAddress(deployer, vm.getNonce(deployer) + 1);
        IERC20(pair).approve(predicted, lpAmount);
        locker = address(new ImmutableLPLock(pair, PAIRING_BENEFICIARY, lpAmount));
        vm.stopBroadcast();

        if (IERC20(pair).balanceOf(locker) != lpAmount) revert("locker did not pull all LP");
        if (IERC20(pair).balanceOf(deployer) != 0) revert("deployer still holds pair LP");
    }

    function _create(bytes memory creation) internal returns (address addr) {
        assembly {
            addr := create(0, add(creation, 0x20), mload(creation))
        }
        if (addr == address(0)) revert("create returned zero");
    }

    function _readHex(string memory path) internal view returns (bytes memory) {
        return vm.parseBytes(vm.readFile(path));
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
