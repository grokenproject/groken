# AUDIT.md

Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

This file records conservative choices, a static-analysis **plan**, and a self-review checklist. It does **not** claim that the contracts are “audited” by a firm. It does not claim Coinbase, Base, Uniswap, OpenZeppelin-as-auditor, or Sourcify endorsement.

Raw tool output (this revision):

- [reports/slither.txt](reports/slither.txt)
- [reports/aderyn.md](reports/aderyn.md)
- [reports/slither-check-erc.txt](reports/slither-check-erc.txt)
- [reports/README.md](reports/README.md) — versions, commands, why CI does not re-run them

## Scope

In scope: the five contracts under `src/`, the launch-batch script, and the Foundry tests.

Out of scope: any AMM pool, any off-chain K2 unique-user process, any testnet or mainnet deployment, any wallet operational security outside this repo.

## Conservative choices (underspecified items)

These are binding interpretations where the Phase 1 brief left a gap. They were chosen to avoid new allocations and to avoid new admin powers.

1. **Vesting math.** “12-month cliff then 36-month linear” is implemented as: 0% until `start + 365 days` (including the exact cliff timestamp); then linear from 0 to 100% over the next `3 * 365 days`; 100% at `start + 4 * 365 days`. A 365-day year is used rather than calendar months. At the exact cliff instant, releasable is 0.

2. **Dust week window.** The 1,000 GRKN/week cap is a **bucket** that resets on the first dust send at or after `weekStart + 7 days`, setting `weekStart = block.timestamp`. It is not a sliding 7-day window.

3. **Empty dust set.** `ExperimentTreasury` accepts an empty frozen recipient list. Dust then cannot be sent; only the dead sink remains. Tests use one log-demo recipient.

4. **Pairing destination (FLAG closed).** After the 7-day delay, pairing ETH/WETH may leave only to (a) `pairingBeneficiary`, an immutable published project wallet set at deploy, or (b) the documented dead address. A random `to` reverts (`BadPairingDestination`). This is **not** a GRKN path and does not add a GRKN third destination. Delay is still 7 days. Not OZ TimelockController. A pending pairing proposal cannot be replaced (no delay reset).

5. **Pairing leftover after T+90d.** Pairing assets still require the 7-day delay. Experiment end does not create a pairing dust path or an instant pairing drain.

6. **One pending, no cancel.** Both `ExperimentTreasury` pairing and `ListingReserve` transfers revert if a proposal already exists. There is no cancel function (would be an extra admin power).

7. **Per-contract clocks.** Each contract stores its own `start` / `unlockTime` at construction. Clocks can differ by a few seconds in a sequential deploy. There is no shared experiment oracle.

8. **Listing proposer.** The brief names one proposer for the treasury. Listing uses the same pattern: one immutable proposer constructor argument. The launch script may set them equal. This is not a role-admin.

9. **Listing blocklist includes locker.** The launch batch deploys `ImmutableLPLock` before `ListingReserve` and passes the locker address in the project-blocked set so listing cannot send GRKN to the locker. Tests assert `projectBlocked(locker)`.

10. **AMM recipient.** Phase 1 does not deploy or call an AMM. The 80M GRKN goes to a caller-supplied address. That address is placed on the listing project blocklist when known. This repo does not name a Uniswap router or pair as if it were official.

11. **Dead address.** Tests and docs use the conventional `0x000000000000000000000000000000000000dEaD`. Constructors take `dead` as a parameter so a deploy cannot silently bind a different sink without it appearing in the calldata. This repo does not publish a mainnet instance.

12. **WETH.** Treasury pairing ERC-20 is a constructor argument. On Base / Base Sepolia the canonical WETH is the well-known `0x4200000000000000000000000000000000000006`. That is a chain preinstall, not a project wallet, and is not treated as a Groken deploy address.

13. **Extra tokens sent later.** `TeamVestLock` vests `balance + released` on the same schedule. Extra GRKN sent after deploy also vest. Conservative: no admin clawback.

14. **Dead-sends: proposer-only until T+90, then permissionless remainder.** Before `start+90d`, `sendGrknToDead` / `sendToDead` revert for a non-proposer (no day-0 grief of the 5M bags). After T+90d those same functions are permissionless remainder-to-dead. `sendRemainingGrknToDead` / `sendRemainderToDead` remain permissionless only after experiment end (listing remainder still deletes any dying pending and includes that amount). Pairing FLAG is closed in code: pairing `to` is beneficiary or dead only.

15. **No kill function.** Experiment end is `start + 90 days`. There is no `kill()` on any of the five contracts. Calling a missing `kill()` does not unlock the locker or the vest.

16. **H1(d) kept.** `ImmutableLPLock.release()` after 90 days returns LP to the beneficiary. This is a pairing-asset return path. It was **not** changed to a museum-only (no-release) lock.

17. **K2.** No on-chain unique-user oracle is shipped.

18. **No invented allocation.** 80 / 10 / 5 / 5 is the only GRKN split. No additional buckets.

19. **`via_ir = true` in `foundry.toml`.** Enabled so the launch script and invariant handler compile under solc 0.8.24 without inventing extra contracts. The five production contracts are written to compile without IR; IR is a compiler setting, not an admin surface.

## Static analysis plan (tools)

Do not tick these as executed unless the command was actually run in this environment.

### Slither

```bash
pipx install slither-analyzer
# or: pip install slither-analyzer
slither . --filter-paths lib --exclude-dependencies
```

Review detectors that matter for this design: `arbitrary-send-eth`, `reentrancy-eth`, `suicidal`, `controlled-delegatecall`, `uninitialized-state`, `locked-ether` (treasury `receive` is intentional), `timestamp` (explicitly used for locks).

### slither-check-erc

```bash
# Source-based check (no invented live address):
slither-check-erc . GrokenToken --erc ERC20 --solc-solcs-select 0.8.24
# After a real deploy, re-run against that address. Do not invent one.
```

### Aderyn

```bash
# https://github.com/Cyfrin/aderyn
aderyn .
```

Treat Aderyn output as a lead list, not a certificate.

## Self-review checklist

Mark `[x]` only when verified in this revision.

- [x] README line one is the full disclosure sentence.
- [x] Every production contract `@notice` is the full disclosure sentence.
- [x] `GrokenToken` has no Ownable, AccessControl, mint-after-deploy, burn admin, pause, blacklist, upgrade, fee-on-transfer, ERC-777, Permit, or custom `_update`.
- [x] `TOTAL_SUPPLY` is hardcoded; constructor does not take supply.
- [x] Constructor rejects `address(0)` and mints only to `initialHolder`.
- [x] Launch batch is a script + test, not a fake in-constructor distribution.
- [x] `ImmutableLPLock` has no owner / pause / extend / shorten / emergency withdraw / kill.
- [x] Locker `release()` is documented as H1(d) pairing-asset return, not museum-only.
- [x] Treasury GRKN paths are only dust-to-frozen-set and dead.
- [x] Treasury pairing path is 7-day delayed ETH/WETH only; no dust exception.
- [x] Treasury is not OZ TimelockController; no `updateDelay`, no `DEFAULT_ADMIN_ROLE`.
- [x] Vest: 0% TGE, cliff then linear, release only to beneficiary; no revoke/shorten/`sendUnreleasedToDead`.
- [x] Vest is disclosed as outliving the 90-day experiment.
- [x] Listing: immutable allowlist (empty valid), project-address hard-revert, 7-day delay, one pending, execute dies at T+90d, unused to dead.
- [x] No leftover-deal exception on listing.
- [x] No on-chain unique-user oracle.
- [x] No price / return / FDV / market-cap language in README.
- [x] 10M published team wallet is not described as the vest.
- [x] Foundry unit + fuzz + invariant tests cover the listed properties.
- [x] CI runs `forge test`.
- [x] OpenZeppelin is pinned to git tag `v5.4.0`.
- [x] Slither run on this revision (see “What was run” and `reports/slither.txt`).
- [x] Aderyn run on this revision (`reports/aderyn.md`).
- [x] slither-check-erc run against this repo’s `GrokenToken` source (`reports/slither-check-erc.txt`). No live address invented.

## What was run

- `forge build` / `forge test` — local and CI
- **Slither 0.11.6** on 2026-09-03: `slither . --filter-paths "lib|test|script" --exclude-dependencies --solc-solcs-select 0.8.24` → `reports/slither.txt` (19 detector hits after T+90 access gates; see review below)
- **Aderyn 0.6.8** on 2026-09-03: `aderyn . --output reports/aderyn.md` → `reports/aderyn.md` (0 high after CEI reorder)
- **slither-check-erc 0.11.6** on 2026-09-03: `slither-check-erc . GrokenToken --erc ERC20 --solc-solcs-select 0.8.24` → `reports/slither-check-erc.txt` (ERC-20 functions/events present; approval-race checkbox unchecked, standard OZ ERC-20)

These three tools are **not** in GitHub Actions. CI is Foundry-only. Reasons: Slither exits non-zero on informational detectors this design requires (timestamp clocks, pairing ETH `call`); the Actions image does not ship Slither/Aderyn/solc-select; committed snapshots are the review artifact. slither-check-erc was run on **source**, not a published chain address.

### Slither / Aderyn review (not “audited”)

- `arbitrary-send-eth` / `low-level-calls` / `reentrancy-events` on `executePairingWithdraw`: pairing ETH after the 7-day delay to `pairingBeneficiary` or dead only. `pendingPairing` is deleted before the call. FLAG closed in code.
- `timestamp`: 90-day experiment end, 7-day delays, locker unlock, vest cliff. Intentional.
- `incorrect-equality` on `amount == 0`: empty-balance guards. Intentional.
- Aderyn H-1 (state change after `balanceOf`) was a CEI order issue on `sendRemainderToDead`. Fixed by deleting `pending` first, then reading the balance (pending tokens remain in the contract), then transferring. Behavior unchanged: remainder including any pending amount goes to dead; pending is cleared.
- slither-check-erc approval race: vanilla OZ v5 ERC-20. No Permit added (extra surface / admin-off rule).

## Known intentional behaviors (not defects)

- Treasury and listing can hold pairing ETH / leftover GRKN that operators fail to move. Early GRKN-to-dead is proposer-only; after T+90d the remainder-to-dead paths are permissionless. Pairing ETH has no dust exception and still needs the 7-day delay.
- A wrong pairing or listing proposal occupies the single pending slot until it executes (listing: or until T+90d remainder-to-dead). No cancel.
- Vest and locker ignore experiment end.
- Token transfers to arbitrary EOAs are unrestricted (plain ERC-20). Restrictions live on treasury, listing, vest, and locker.
