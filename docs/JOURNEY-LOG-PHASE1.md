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

## 2026-09-03 — Base Sepolia (84532) launch batch broadcast

Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

The locker token is a **mock LP**, not Uniswap or Aerodrome. `AMM_RECIPIENT` is a labeled **test stand-in, not a live pool**. All addresses below are TESTNET. Chain id 8453 was refused. No mainnet transaction. Keys were not committed.

- RPC `https://sepolia.base.org` (`eth_chainId` = 84532). Explorer `https://sepolia.basescan.org`.
- Throwaway deployer / `initialHolder` / broadcast signer: `0x2c3DfED863Dd422b605c9a737deBc4123C1e8cE1`. After the batch, `GRKN.balanceOf(initialHolder) = 0` (verified on-chain).
- Mock LP first: `MockLpToken` `0x09274C5b39605cB70e2aF03eaF369D78d9cEfCF0`, constructor `amount = 1e18`, tx `0x29c9edd75842223e39b773ee818a6c9e94ccb4f1eb0d40429f4a82ec9abfc160`, block 46329627. Name `Groken Mock LP (TESTNET ONLY)`.
- Then `LaunchBatch.s.sol` with `CONFIRM_LAUNCH_BATCH=YES`, `LISTING_ALLOWLIST` empty, `DEAD = 0x000000000000000000000000000000000000dEaD`, `WETH = 0x4200000000000000000000000000000000000006`, `LP_AMOUNT = 1e18`, `LP_BENEFICIARY = PAIRING_BENEFICIARY`.

### Five contracts (TESTNET)

| Contract | Address | Deploy tx | Constructor args |
|---|---|---|---|
| GrokenToken | `0xDB162864150859787158F7C9Aa092c61479A2F34` | `0xbb8d8a51c3cfbdd5e6ead92c3f9b6778384197fd1418cbad2fca90bbc386b76f` | `initialHolder = 0x2c3DfED863Dd422b605c9a737deBc4123C1e8cE1` |
| TeamVestLock | `0x0925e8107184cEbD026D111c07037068c2584034` | `0xbb3a795d068c1144e276285c70bec7ffdf053846c4a1af9d01571ee08f83ae59` | `token = GrokenToken`, `beneficiary = 0xC4137793697Eb95fa41454f22525C065D6E4CE02` |
| ExperimentTreasury | `0x01bB8E28b943caCD4ad0fDFC42416fc4eC091B59` | `0x008d9808e01ec601029012413087fd300ea1aa875ab8871d7f6b30133da470ca` | `grkn`, `weth`, `dead`, `proposer = 0x5a0C7B91FD38e9E046C7Bf2d8994A54a38481960`, `pairingBeneficiary = 0x3F133aD764bbF185d3ab431880273EfDeeaD69e3`, `dustRecipients = [0x8cFC6078ED04c966037bF0c43FF9664D24834F6F]` |
| ImmutableLPLock | `0x2441F5b6aa67A4bFE732E08C3ac5152EA3C20A24` | `0xf61db4184a9b9d7ab63d9affd066481d30636637ef7e98df7546859b9dd356fa` | `lpToken = MockLpToken`, `beneficiary = pairingBeneficiary`, `amount = 1e18`. `unlockTime = 1796203326`. |
| ListingReserve | `0xc37E4597A38E2256D7bCF5C7C51DB0Ac95EfF288` | `0x324f73dbed0d87cb056b4c6d1367fdf343514e574d477368da44aa373a5f32ce` | `token`, `dead`, `proposer`, `allowlist = []`, `projectAddresses = [token, vest, treasury, team, AMM stand-in, locker]` |

### Post-batch GRKN (verified)

- AMM stand-in `0xDEFb9e5aF851D04F0ad4FB8357A00a47aCa0e6C1`: 80,000,000 (test stand-in, not a pool)
- TeamVestLock: 10,000,000
- ExperimentTreasury: 5,000,000
- ListingReserve: 5,000,000
- initialHolder and team wallet: 0
- totalSupply: 100,000,000e18

Mock LP: locker holds 1e18; deployer holds 0. Listing `projectBlocked(locker) = true`.

Distribution txs: approve `0x8363b208e33d2f100e71b1b00286b1bc510d811854903fbdbf6863286a0a79a9`; vest `0x0f92d1bdc69775d92214c396e6cd95ee49b8484359aac28ed837415c0e5aa295`; treasury `0x8c958ae755425519b6cd3a9adf5fddb758a7cc96e885d0b6f9139e86cbbb9be0`; listing `0xb779017a77843f6bc3337b5a159ecbaecc2b264f66ba729dac8f6b59f0d04091`; AMM stand-in `0x8f6cb5184d076db6e84513ef9e998585481dc39a4399f61c1a4f5dddb90b9947`.

Source was submitted to Sourcify (`exact_match` on the six contracts). That is not a Sourcify or Basescan endorsement. Basescan verify was not performed (`ETHERSCAN_API_KEY` unset). This repo does not claim an audit.

README line one remains the full disclosure. See `WALLETS.md` for the labeled table.

## 2026-09-04 — Sepolia documentation pass (no new deploy)

Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

- Operator chose: keep documenting Base Sepolia only. No real AMM pool. No mainnet. No Phase 2 socials.
- Re-checked RPC `https://sepolia.base.org` (`eth_chainId` = 84532).
- On-chain GRKN still: totalSupply 100,000,000; AMM stand-in `0xDEFb9e5aF851D04F0ad4FB8357A00a47aCa0e6C1` 80,000,000; TeamVestLock `0x0925e8107184cEbD026D111c07037068c2584034` 10,000,000; ExperimentTreasury `0x01bB8E28b943caCD4ad0fDFC42416fc4eC091B59` 5,000,000; ListingReserve `0xc37E4597A38E2256D7bCF5C7C51DB0Ac95EfF288` 5,000,000; initialHolder `0x2c3DfED863Dd422b605c9a737deBc4123C1e8cE1` 0; team wallet `0xC4137793697Eb95fa41454f22525C065D6E4CE02` 0; dead 0; locker GRKN 0.
- ImmutableLPLock `0x2441F5b6aa67A4bFE732E08C3ac5152EA3C20A24` still holds 1e18 of MockLpToken `0x09274C5b39605cB70e2aF03eaF369D78d9cEfCF0` (`Groken Mock LP (TESTNET ONLY)`). Not Uniswap/Aerodrome. The 80M recipient remains a labeled stand-in, not a live pool. This does not prove the AMM path.
- Addresses unchanged from `WALLETS.md` on main. Dev Bot PASS-reviewed the Sepolia writeup against CONTRACT-PHASE0.md. Sourcify exact_match was previously recorded; that is not an endorsement. Not audited.
- Howey flags stay on the packet. H1(d) locker `release()` after 90 days remains a pairing-asset return path.

## Not done in Phase 1 (intentionally)

- Mainnet
- Funded operator wallet
- Social accounts
- Price / return / FDV / market-cap commentary
- On-chain unique-user (K2) oracle
- Claiming a third-party audit
- Real Uniswap/Aerodrome pool
- Treating Sepolia mock LP as a mainnet dress rehearsal
