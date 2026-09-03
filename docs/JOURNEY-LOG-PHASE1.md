# Journey log — Phase 1

Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

Public log for the Phase 1 Foundry repository. Later phases should append, not rewrite.

## 2026-09-03 — repository opened

- Kept the canonical disclosure as README line one.
- Implemented five admin-off contracts: `GrokenToken`, `ImmutableLPLock`, `ExperimentTreasury`, `TeamVestLock`, `ListingReserve`.
- Pinned OpenZeppelin Contracts to git tag `v5.4.0` and forge-std to `v1.9.6`.
- solc `0.8.24` in `foundry.toml`; pragma `^0.8.20`.
- Documented the 80 / 10 / 5 / 5 launch batch in `script/LaunchBatch.s.sol` and `test/LaunchBatch.t.sol`. Constructor still mints 100% to `initialHolder`. Throwaway deployer is specified to hold zero after the batch; the batch is not faked inside the token.
- H1(d): locker `release()` after 90 days remains a pairing-asset return path (not museum-only).
- Vest-survives: 10M lives in `TeamVestLock`. Operator economic interest outlives the 90-day experiment; not marketed as alignment.
- K2 left off-chain. No unique-user oracle in this repo.
- Tests: unit, fuzz, and invariants for supply constancy, locker early-move, no locker owner, treasury GRKN destinations, pairing delay, vest cliff, and listing AMM / off-list rejection.
- `WALLETS.md` is a template. No mainnet addresses invented. No funded wallet. No socials.
- CI: `forge test`.
- No Base mainnet deploy. Sepolia deploy not performed (no throwaway key shipped).

## 2026-09-03 — Dev Bot review (CONTRACT-PHASE0)

- `ListingReserve.sendToDead` is proposer-only. `sendRemainderToDead` stays permissionless after start+90d and still deletes pending / includes the pending amount.
- `ExperimentTreasury.sendGrknToDead` is proposer-only. `sendRemainingGrknToDead` stays permissionless after experimentEnd.
- No `sendUnreleasedToDead` on `TeamVestLock`. Vest math unchanged.
- Static-analysis reports committed under `reports/` (see AUDIT.md “What was run”).
- README line one remains the full disclosure. No invented addresses. No mainnet.

## 2026-09-03 — CONTRACT-PHASE0 review follow-up

- `sendToDead` / `sendGrknToDead`: proposer-only before start+90d; a random address can call them after T+90 (permissionless remainder). Tests assert both sides.
- Launch batch deploys `ImmutableLPLock` first and puts it on the listing project-blocklist.
- Pairing `to` after 7 days remains a pairing-custody FLAG, not a GRKN path.
- Analysis reports remain under `reports/` and are re-run after this change.

## 2026-09-03 — pairing FLAG closed

- `ExperimentTreasury` pairing ETH/WETH after the 7-day delay may only go to the immutable `pairingBeneficiary` (constructor, published project wallet) or dead. Random `to` reverts. Not a GRKN path. Delay unchanged. Not TimelockController.

## 2026-09-03 — Base Sepolia deploy opened; faucet blocked

Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

- Operator opened Phase 1 Base Sepolia (84532) only. RPC `https://sepolia.base.org`. Explorer `https://sepolia.basescan.org`. Chain id 8453 refused everywhere in the launch and mock-LP scripts. No mainnet transaction. No mainnet address invented.
- Canonical WETH checked on-chain: `0x4200000000000000000000000000000000000006` on 84532 returns `Wrapped Ether` / `WETH` / 18. That is the OP-stack predeploy, not a Groken contract.
- Added testnet-only `script/testnet/MockLpToken.sol` and `script/DeployMockLp.s.sol`. This is a **mock LP**, not Uniswap or Aerodrome. It exists so `LaunchBatch.s.sol` can satisfy `LP_TOKEN` / `LP_AMOUNT > 0` and `ImmutableLPLock` can pull a real ERC-20. Constructor and script refuse 8453.
- Throwaway keys generated with Foundry `cast wallet new` and stored **outside** this repository. Not committed. Not written to `.env` in git.
- Throwaway deployer / `initialHolder` (TESTNET): `0x2c3DfED863Dd422b605c9a737deBc4123C1e8cE1`. Balance on 84532 is 0. Distinct TESTNET EOAs were also generated off-repo for `TEAM_WALLET`, `PROPOSER`, `PAIRING_BENEFICIARY`, `AMM_RECIPIENT` (test stand-in, not a live pool), and one log-demo dust recipient. `DEAD` = `0x000000000000000000000000000000000000dEaD`. `LISTING_ALLOWLIST` empty.
- Public faucet attempts (Triangle, LearnWeb3, Coinbase HTML faucet, CDP `/v2/evm/faucet`, Alchemy page, QuickNode page, Chainlink page, guessed thirdweb/Bware/L2faucet APIs) required captcha, login, API key, or mainnet-balance eligibility. Per operator rule: **stopped**. No broadcast.
- Five contract addresses do **not** exist yet. `WALLETS.md` contract rows stay `_TBD`. README line one remains the full disclosure.
- After the operator funds the deployer on Base Sepolia, a follow-up can: (1) `CONFIRM_MOCK_LP=YES` broadcast `DeployMockLp.s.sol`; (2) set `LP_TOKEN` / `LP_AMOUNT` and `CONFIRM_LAUNCH_BATCH=YES` on `LaunchBatch.s.sol` with `initialHolder` = the broadcast signer; (3) write the five addresses, tx hashes, and constructor args here and in `WALLETS.md`; (4) optionally verify on sepolia.basescan.org if an API key exists — do not claim Sourcify/Basescan endorsement.

## Not done in Phase 1 (intentionally)

- Mainnet
- Funded operator wallet
- Social accounts
- Price / return / FDV / market-cap commentary
- On-chain unique-user (K2) oracle
- Claiming a third-party audit
