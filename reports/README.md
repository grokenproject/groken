# Static analysis reports

Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

These files are **tool output**, not a third-party audit and not an endorsement by Coinbase, Base, Uniswap, OpenZeppelin, Cyfrin, or Trail of Bits.

| File | Tool | Version | Command | Date |
|---|---|---|---|---|
| `slither.txt` | Slither | 0.11.6 | `slither . --filter-paths "lib\|test\|script" --exclude-dependencies --solc-solcs-select 0.8.24` | 2026-09-03 |
| `aderyn.md` | Aderyn | 0.6.8 | `aderyn . --output reports/aderyn.md` | 2026-09-03 |
| `slither-check-erc.txt` | slither-check-erc | 0.11.6 (same package) | `slither-check-erc . GrokenToken --erc ERC20 --solc-solcs-select 0.8.24` | 2026-09-03 |

`slither-check-erc` was run against **this Foundry project and the `GrokenToken` source**, not against a live chain address. No testnet or mainnet address was invented.

## Why these tools are not in CI

The GitHub Actions job is Foundry-only (`foundry-rs/foundry-toolchain`, `forge test`). It does not install Python, `slither-analyzer`, `solc-select`, or the Aderyn binary.

- Slither exits non-zero when informational detectors fire (timestamp, low-level ETH send). Wiring that into CI would fail the PR on findings that this design **requires** (90-day clocks, 7-day pairing delay, ETH pairing `call`).
- Aderyn and Slither versions drift; committed snapshots are the review artifact for this revision.
- slither-check-erc needs Slither + solc 0.8.24. It does **not** need a published deploy address when pointed at the repo. CI has no reason to invent one.

Re-run the commands above locally before any deploy, including Base Sepolia. Do not treat a green `forge test` CI check as a substitute for these reports.

## Findings review (this revision)

Recorded in `AUDIT.md`. Short version:

- Slither `arbitrary-send-eth` / `low-level-calls` / `reentrancy-events` on treasury pairing ETH: pairing-custody path after 7 days to `pairingBeneficiary` or dead only (FLAG closed in code). `pendingPairing` is deleted before the call. Not a GRKN path.
- Slither `timestamp`: intentional lock / delay / vest / experiment-end clocks, including proposer-only-until-T+90 gates on `sendToDead` / `sendGrknToDead`.
- Slither `incorrect-equality` on `amount == 0`: empty-balance guards.
- slither-check-erc: ERC-20 surface present. The remaining checkbox is the well-known ERC-20 approval race; this token does not add Permit (admin-off / extra-surface rule).
- Aderyn: 0 high. Lows are style (pragma `^0.8.20`, PUSH0, numeric literal, single-use modifier).
