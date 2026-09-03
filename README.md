Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

Phase 1 public repository. Testnet and source only. No mainnet. No funded wallet.

This repository is the Phase 1 Foundry project: five contracts, tests, and a documented launch-batch script. It is not an investment offering. Nothing here promises a price, a return, an FDV, or a market cap. There are no official social accounts in this repo.

## What this is

Placeholders: token name `Groken`, symbol `GRKN`. One chain family: Base (8453) and Base Sepolia (84532). No mainnet addresses are published here because none have been created by this repository.

The five contracts have **admin off** in the sense defined below. Do not add owners, pausers, minters, or delay-updaters.

K2 (unique-user accounting) is off-chain only. This repo does not ship an on-chain unique-user oracle.

## Disclosure (also on every contract `@notice`)

Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

## Allocation (documented launch batch — not encoded in the token)

`GrokenToken` mints **100,000,000 GRKN** once, to `initialHolder`. The constructor does not take a supply argument and does not perform the batch.

The documented batch (`script/LaunchBatch.s.sol`, exercised in `test/LaunchBatch.t.sol`) then moves:

| Destination | Amount | Notes |
|---|---|---|
| AMM recipient (caller-supplied) | 80,000,000 | Pool is created out of band. This repo does not ship an AMM integration. |
| `TeamVestLock` | 10,000,000 | This contract is the vest. The published team wallet is the **beneficiary**, not a 10M hot wallet and not “the vest”. |
| `ExperimentTreasury` | 5,000,000 | Distinct address. |
| `ListingReserve` | 5,000,000 | Unused remainder goes to the documented dead address. |
| `initialHolder` / throwaway deployer | 0 | After the batch. Do not treat the deployer as a holder. |

LP tokens created out of band are pulled into `ImmutableLPLock`.

The script refuses chain id 8453 and does not broadcast unless `CONFIRM_LAUNCH_BATCH=YES`. This repository does not contain a private key and does not invent deploy addresses.

## Contracts

### 1. GrokenToken

OpenZeppelin Contracts v5 ERC-20 only (`v5.4.0` git tag). `TOTAL_SUPPLY` is hardcoded `100_000_000 * 10**18`. Constructor `_mint(initialHolder, TOTAL_SUPPLY)` only. Rejects `address(0)`. No Ownable, AccessControl, post-deploy mint, privileged burn, ERC20Burnable, pause, blacklist, upgradeability, fee-on-transfer, ERC-777, Permit, or custom `_update`.

### 2. ImmutableLPLock

No admin. Constructor: LP token, immutable beneficiary, `unlockTime = now + 90 days`; pulls LP in. Only state-changing function: `release()` after `unlockTime`, which sends LP to the beneficiary. No owner, pause, extend, shorten, or emergency withdraw. Kill is not a function and does not unlock early.

**H1(d) flag — pairing-asset return path (not museum-only):** after `unlockTime`, `release()` returns the LP token (the pairing-asset claim) to `beneficiary`. This is intentional. This locker is not a forever museum lock.

### 3. ExperimentTreasury

Distinct address. GRKN may leave **only** as:

- (a) dust to a constructor-frozen recipient set (empty set is valid; tests use one log-demo address), under **100 GRKN/tx**, **1,000 GRKN/week**, **5,000 GRKN lifetime**, with a reason string and event; or
- (b) the documented dead address (same sink at experiment end / T+90d, or earlier). Early `sendGrknToDead` is proposer-only unused-remainder; after T+90d, `sendRemainingGrknToDead` is permissionless.

No third GRKN destination. No delayed GRKN-to-arbitrary-wallet. The 7-day delay is **pairing asset (ETH / WETH) only**. Leftover pairing asset has no dust exception. One documented proposer key, immutable. This is not OpenZeppelin `TimelockController`. There is no `DEFAULT_ADMIN_ROLE` and no `updateDelay`.

### 4. TeamVestLock

Vest-survives (frozen). The 10M allocation is locked **here**, not in the published team wallet. 0% TGE; 12-month cliff; then 36-month linear; fully vested at start + 48 months. `release()` only to the published team wallet (beneficiary). No admin shorten, revoke, or exit. No `sendUnreleasedToDead`. Kill / experiment end does not unlock, accelerate, or burn.

**Disclosure:** operator economic interest outlives the 90-day experiment. This is not marketed as alignment.

### 5. ListingReserve

Immutable allowlist at deploy (empty allowlist is valid). Never an AMM. Hard-reverts transfers to constructor-frozen project addresses. `proposeTransfer(ListingFee | MMInventory)` with a 7-day delay and one pending proposal. `executeTransfer` reverts at or after start+90d (no post-kill execute; pending-before-90 die). `sendToDead` is proposer-only (anytime). After start+90d, new proposes revert and remainder-to-dead is permissionless. Unused GRKN goes to dead. No leftover-deal exception.

## Stack

- Foundry
- Solidity `^0.8.20` (solc `0.8.24` in `foundry.toml`)
- OpenZeppelin Contracts **v5.4.0** (exact git tag, not a floating `^`)
- forge-std **v1.9.6** (exact git tag)

## Build and test

```bash
forge install
forge build
forge test
```

CI runs `forge test` on every push and pull request.

## Review status

This repository includes a self-review checklist and a static-analysis plan in `AUDIT.md`. It does **not** claim a third-party audit. It does not claim Coinbase, Base, Uniswap, OpenZeppelin-as-auditor, or Sourcify endorsement. OpenZeppelin Contracts is a library dependency, not an audit.

## Docs

- `AUDIT.md` — conservative choices, analysis plan, self-review
- `WALLETS.md` — address template (fill after a real deploy; no invented addresses)
- `docs/JOURNEY-LOG-PHASE1.md` — public Phase 1 log
- `script/LaunchBatch.s.sol` — documented batch; do not run on mainnet
