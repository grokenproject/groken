// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 * @title GrokenToken
 * @dev Plain OpenZeppelin v5 ERC-20. Admin surface is off: no Ownable, AccessControl,
 *      post-deploy mint, privileged burn, pause, blacklist, upgradeability, fee-on-transfer,
 *      ERC-777, Permit, or custom `_update`. Supply is a hardcoded constant, not a constructor argument.
 *      The constructor mints 100% to `initialHolder`. The launch batch (documented in
 *      `script/LaunchBatch.s.sol`) is expected to empty that holder; this contract does not encode
 *      that batch.
 */
contract GrokenToken is ERC20 {
    /// @notice Fixed total supply: 100,000,000 GRKN (18 decimals).
    uint256 public constant TOTAL_SUPPLY = 100_000_000 * 10 ** 18;

    error ZeroInitialHolder();

    /**
     * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
     * @param initialHolder Recipient of the one-time mint. Rejects `address(0)`.
     */
    constructor(address initialHolder) ERC20("Groken", "GRKN") {
        if (initialHolder == address(0)) revert ZeroInitialHolder();
        _mint(initialHolder, TOTAL_SUPPLY);
    }
}
