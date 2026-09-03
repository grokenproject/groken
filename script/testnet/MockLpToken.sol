// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 * @title MockLpToken
 * @dev TESTNET ONLY. Stand-in ERC-20 so `ImmutableLPLock` can lock a real token on Base Sepolia
 *      when no Uniswap / Aerodrome pool exists. This is not an AMM pair, not live liquidity,
 *      and not a protocol contract. Constructor refuses chain id 8453.
 */
contract MockLpToken is ERC20 {
    error MainnetForbidden();
    error ZeroAmount();

    /**
     * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
     * @param amount Minted once to the deployer. Must be > 0.
     */
    constructor(uint256 amount) ERC20("Groken Mock LP (TESTNET ONLY)", "MOCKLP-TESTNET") {
        if (block.chainid == 8453) revert MainnetForbidden();
        if (amount == 0) revert ZeroAmount();
        _mint(msg.sender, amount);
    }
}
