// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {DeploySepoliaAmmScript} from "../script/DeploySepoliaAmm.s.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 */
contract DeploySepoliaAmmTest is Test {
    function test_refusesBaseMainnet8453() public {
        vm.chainId(8453);
        vm.setEnv("CONFIRM_SEPOLIA_AMM", "YES");
        vm.setEnv("DEPLOYER_PRIVATE_KEY", vm.toString(uint256(0xA11CE)));
        vm.setEnv("AMM_STANDIN_PRIVATE_KEY", vm.toString(uint256(0xB0B)));
        DeploySepoliaAmmScript s = new DeploySepoliaAmmScript();
        vm.expectRevert(bytes("Refusing Base mainnet (8453)."));
        s.run();
    }

    function test_constantsMatchDocumentedTestnet() public {
        DeploySepoliaAmmScript s = new DeploySepoliaAmmScript();
        assertEq(s.GRKN(), 0xDB162864150859787158F7C9Aa092c61479A2F34);
        assertEq(s.WETH(), 0x4200000000000000000000000000000000000006);
        assertEq(s.DEAD(), 0x000000000000000000000000000000000000dEaD);
        assertEq(s.PAIRING_BENEFICIARY(), 0x3F133aD764bbF185d3ab431880273EfDeeaD69e3);
        assertEq(s.AMM_STANDIN(), 0xDEFb9e5aF851D04F0ad4FB8357A00a47aCa0e6C1);
        assertEq(s.OLD_MOCK_LOCKER(), 0x2441F5b6aa67A4bFE732E08C3ac5152EA3C20A24);
        assertEq(s.GRKN_LIQUIDITY(), 80_000_000 ether);
    }
}
