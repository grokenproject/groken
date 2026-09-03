# WALLETS.md

Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

Template only. **Do not invent addresses.** Fill a contract row after that contract actually exists on Base Sepolia (84532). Refuse chain id 8453. Phase 1 has not broadcast the five contracts. There is no funded wallet in this repo. No mainnet addresses.

**Base Sepolia (84532) TESTNET status — 2026-09-03:** throwaway deployer generated; public faucets required captcha, login, or mainnet-balance eligibility. Operator: send Base Sepolia ETH to the deployer below, then the mock-LP + launch batch can run. Private key is not in this repository.

| Role | Chain | Address | Notes |
|---|---|---|---|
| Team wallet (beneficiary of the vest, **not** the vest) | Base Sepolia 84532 TESTNET | _TBD — not deployed_ | Published team wallet. Receives `TeamVestLock.release()` only after the cliff. Holds 0 GRKN at launch. |
| TeamVestLock (the vest) | Base Sepolia 84532 TESTNET | _TBD — not deployed_ | Holds the 10M allocation. Vest survives the 90-day experiment. |
| ListingReserve | Base Sepolia 84532 TESTNET | _TBD — not deployed_ | Holds the 5M listing allocation. Unused to dead. |
| ExperimentTreasury | Base Sepolia 84532 TESTNET | _TBD — not deployed_ | Holds the 5M treasury allocation. Distinct address. |
| ImmutableLPLock | Base Sepolia 84532 TESTNET | _TBD — not deployed_ | Will lock a **mock LP ERC-20** (not Uniswap / Aerodrome). `release()` after 90 days is the H1(d) pairing-asset return path. |
| MockLpToken (TESTNET ONLY) | Base Sepolia 84532 TESTNET | _TBD — not deployed_ | Stand-in ERC-20 from `script/testnet/MockLpToken.sol`. Not a live pool. |
| Dead address | any EVM | `0x000000000000000000000000000000000000dEaD` | Conventional sink. Same sink at kill / T+90d / earlier. Not a project-controlled wallet. |
| initialHolder (launch batch executor) | Base Sepolia 84532 TESTNET | `0x2c3DfED863Dd422b605c9a737deBc4123C1e8cE1` | Throwaway deployer. Unfunded. Receives 100% at mint; must be 0 after the batch. Do not treat as a treasury. |
| Proposer key | Base Sepolia 84532 TESTNET | _TBD — generated off-repo; publish after deploy_ | One documented proposer for treasury dust + pairing proposals. Listing uses the same constructor pattern. Immutable; not an admin role. |
| Pairing beneficiary | Base Sepolia 84532 TESTNET | _TBD — generated off-repo; publish after deploy_ | Immutable published project wallet. After the 7-day delay, treasury pairing ETH/WETH may go here or to dead only. |
| Dust recipient set | Base Sepolia 84532 TESTNET | _TBD — one log-demo EOA generated off-repo, or empty_ | Frozen at treasury construct. |
| Listing allowlist | Base Sepolia 84532 TESTNET | empty | Frozen at listing construct. Empty is valid. |
| AMM recipient (80M) | Base Sepolia 84532 TESTNET | _TBD — generated off-repo; publish after deploy_ | **TEST stand-in, not a live pool.** 80M GRKN goes here because no AMM exists yet. |
| Canonical WETH (pairing ERC-20) | Base Sepolia 84532 TESTNET | `0x4200000000000000000000000000000000000006` | Verified 2026-09-03 via `https://sepolia.base.org` (chain id 84532): `name()=Wrapped Ether`, `symbol()=WETH`, `decimals()=18`. OP-stack predeploy, not a Groken deploy. Same preinstall exists on Base 8453; this repo still refuses 8453 and does not publish a mainnet Groken address. |

After a real deploy, replace `_TBD` with the on-chain address and the transaction hash. Do not paste placeholder 0xeee… / 0xaaa… values.
