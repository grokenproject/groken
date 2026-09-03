# WALLETS.md

Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

Template only. **Do not invent addresses.** Fill a row after that contract or wallet actually exists on Base Sepolia (84532) or, later, Base (8453). Phase 1 of this repository has not deployed anything. There is no funded wallet in this repo.

| Role | Chain | Address | Notes |
|---|---|---|---|
| Team wallet (beneficiary of the vest, **not** the vest) | — | _TBD — do not invent_ | Published team wallet. Receives `TeamVestLock.release()` only after the cliff. Holds 0 GRKN at launch. |
| TeamVestLock (the vest) | — | _TBD — do not invent_ | Holds the 10M allocation. Vest survives the 90-day experiment. |
| ListingReserve | — | _TBD — do not invent_ | Holds the 5M listing allocation. Unused to dead. |
| ExperimentTreasury | — | _TBD — do not invent_ | Holds the 5M treasury allocation. Distinct address. |
| ImmutableLPLock | — | _TBD — do not invent_ | Holds LP after the launch batch. `release()` after 90 days is the H1(d) pairing-asset return path. |
| Dead address | any EVM | `0x000000000000000000000000000000000000dEaD` | Conventional sink. Same sink at kill / T+90d / earlier. Not a project-controlled wallet. |
| initialHolder (launch batch executor) | — | _TBD — do not invent_ | Receives 100% at mint. Must be 0 after the batch. Throwaway deployer; do not fund it as a treasury. |
| Proposer key | — | _TBD — do not invent_ | One documented proposer for treasury dust + pairing proposals. Listing uses the same constructor pattern (may be the same key). Immutable; not an admin role. |
| Pairing beneficiary | — | _TBD — do not invent_ | Immutable published project wallet. After the 7-day delay, treasury pairing ETH/WETH may go here or to dead only. Not an arbitrary EOA chosen at propose-time. |
| Dust recipient set | — | _TBD — optional log-demo address, or empty_ | Frozen at treasury construct. |
| Listing allowlist | — | _TBD — may be empty_ | Frozen at listing construct. |
| AMM recipient (80M) | — | _TBD — do not invent_ | Caller-supplied pool address created out of band. Not shipped by this repo. |
| Canonical WETH (pairing ERC-20) | Base 8453 / Base Sepolia 84532 | `0x4200000000000000000000000000000000000006` | Chain preinstall. Not a Groken deploy. Passed into `ExperimentTreasury` as `weth`. |

After a real deploy, replace `_TBD` with the on-chain address and the transaction hash. Do not paste placeholder 0xeee… / 0xaaa… values.
