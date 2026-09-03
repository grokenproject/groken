// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";

import {MockLpToken} from "./testnet/MockLpToken.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 * @title DeployMockLpScript
 * @dev TESTNET ONLY. Deploys `MockLpToken` and mints `MOCK_LP_AMOUNT` to the broadcast signer
 *      so `LaunchBatch.s.sol` can lock a real ERC-20 in `ImmutableLPLock`.
 *
 *      This token is not a Uniswap or Aerodrome pair. There is no live AMM.
 *
 *      Refuses chain id 8453. Broadcast additionally requires Base Sepolia (84532) and
 *      CONFIRM_MOCK_LP=YES. Without confirmation the script only prints the plan.
 *
 *      Env:
 *        MOCK_LP_AMOUNT (uint; default 1000e18)
 *        CONFIRM_MOCK_LP=YES to broadcast
 */
contract DeployMockLpScript is Script {
    uint256 public constant DEFAULT_AMOUNT = 1000 * 10 ** 18;

    function run() external {
        uint256 amount = vm.envOr("MOCK_LP_AMOUNT", DEFAULT_AMOUNT);
        console2.log("Mock LP plan (TESTNET ONLY; not Uniswap/Aerodrome).");
        console2.log("chainid", block.chainid);
        console2.log("amount", amount);

        if (block.chainid == 8453) revert("Refusing Base mainnet (8453).");
        if (!_eq(vm.envOr("CONFIRM_MOCK_LP", string("NO")), "YES")) {
            console2.log("CONFIRM_MOCK_LP != YES; not broadcasting.");
            return;
        }
        if (block.chainid != 84532) revert("Base Sepolia (84532) only.");

        vm.startBroadcast();
        MockLpToken lp = new MockLpToken(amount);
        vm.stopBroadcast();

        console2.log("MockLpToken (TESTNET ONLY, not Uniswap/Aerodrome)", address(lp));
        console2.log("minted to signer", amount);
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
