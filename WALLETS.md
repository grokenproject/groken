# WALLETS.md

Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.

**TESTNET only. Chain 84532 (Base Sepolia).** This table is filled from on-chain state after the 2026-09-03 launch batch. Every Groken address below is labeled TESTNET. This repository refuses chain id 8453. No mainnet addresses are published. Private keys are not in this repository.

Explorer: `https://sepolia.basescan.org`. RPC used: `https://sepolia.base.org` (confirmed `eth_chainId` = 84532).

TESTNET Uniswap V2 (this repo’s factory/router, official source pin) now holds the 80M GRKN with a disclosed seed ETH amount. Seed is **not a valuation**. The original mock locker is unchanged until its `unlockTime`. `AMM_RECIPIENT` was a **test stand-in** and now holds 0 GRKN.

| Role | Chain | Address | Tx | Notes |
|---|---|---|---|---|
| GrokenToken | Base Sepolia 84532 TESTNET | [`0xDB162864150859787158F7C9Aa092c61479A2F34`](https://sepolia.basescan.org/address/0xDB162864150859787158F7C9Aa092c61479A2F34) | [`0xbb8d8a51c3cfbdd5e6ead92c3f9b6778384197fd1418cbad2fca90bbc386b76f`](https://sepolia.basescan.org/tx/0xbb8d8a51c3cfbdd5e6ead92c3f9b6778384197fd1418cbad2fca90bbc386b76f) | Constructor: `initialHolder = 0x2c3DfED863Dd422b605c9a737deBc4123C1e8cE1`. Name `Groken`, symbol `GRKN`, supply 100,000,000e18. |
| TeamVestLock (the vest) | Base Sepolia 84532 TESTNET | [`0x0925e8107184cEbD026D111c07037068c2584034`](https://sepolia.basescan.org/address/0x0925e8107184cEbD026D111c07037068c2584034) | [`0xbb3a795d068c1144e276285c70bec7ffdf053846c4a1af9d01571ee08f83ae59`](https://sepolia.basescan.org/tx/0xbb3a795d068c1144e276285c70bec7ffdf053846c4a1af9d01571ee08f83ae59) | Constructor: `token = GrokenToken`, `beneficiary = TEAM_WALLET`. Holds 10,000,000 GRKN. Vest survives the 90-day experiment. |
| ExperimentTreasury | Base Sepolia 84532 TESTNET | [`0x01bB8E28b943caCD4ad0fDFC42416fc4eC091B59`](https://sepolia.basescan.org/address/0x01bB8E28b943caCD4ad0fDFC42416fc4eC091B59) | [`0x008d9808e01ec601029012413087fd300ea1aa875ab8871d7f6b30133da470ca`](https://sepolia.basescan.org/tx/0x008d9808e01ec601029012413087fd300ea1aa875ab8871d7f6b30133da470ca) | Constructor: `grkn`, `weth = 0x4200000000000000000000000000000000000006`, `dead`, `proposer`, `pairingBeneficiary`, `dustRecipients = [log-demo]`. Holds 5,000,000 GRKN. Distinct address. |
| ListingReserve | Base Sepolia 84532 TESTNET | [`0xc37E4597A38E2256D7bCF5C7C51DB0Ac95EfF288`](https://sepolia.basescan.org/address/0xc37E4597A38E2256D7bCF5C7C51DB0Ac95EfF288) | [`0x324f73dbed0d87cb056b4c6d1367fdf343514e574d477368da44aa373a5f32ce`](https://sepolia.basescan.org/tx/0x324f73dbed0d87cb056b4c6d1367fdf343514e574d477368da44aa373a5f32ce) | Constructor: `token`, `dead`, `proposer`, `allowlist = []`, `projectAddresses = [token, vest, treasury, team wallet, AMM stand-in, locker]`. Holds 5,000,000 GRKN. Unused to dead. |
| ImmutableLPLock (mock LP, original) | Base Sepolia 84532 TESTNET | [`0x2441F5b6aa67A4bFE732E08C3ac5152EA3C20A24`](https://sepolia.basescan.org/address/0x2441F5b6aa67A4bFE732E08C3ac5152EA3C20A24) | [`0xf61db4184a9b9d7ab63d9affd066481d30636637ef7e98df7546859b9dd356fa`](https://sepolia.basescan.org/tx/0xf61db4184a9b9d7ab63d9affd066481d30636637ef7e98df7546859b9dd356fa) | Unchanged. Constructor: `lpToken = MockLpToken`, `beneficiary = PAIRING_BENEFICIARY`, `amount = 1e18`. Still holds the **mock LP**, not the real pair. `unlockTime = 1796203326` (2026-12-02 09:22:06 UTC). |
| ImmutableLPLock (real pair LP) | Base Sepolia 84532 TESTNET | [`0x2FC84c4e547F11FeA043fF54108714cE75412F22`](https://sepolia.basescan.org/address/0x2FC84c4e547F11FeA043fF54108714cE75412F22) | [`0x865f09adc68b202ecc9ac49adf12e887aee52c3be39fab03becb31d84c1534db`](https://sepolia.basescan.org/tx/0x865f09adc68b202ecc9ac49adf12e887aee52c3be39fab03becb31d84c1534db) | Constructor: `lpToken = GRKN/WETH pair`, `beneficiary = 0x3F133aD764bbF185d3ab431880273EfDeeaD69e3`, `amount = 102643616117514097422`. `unlockTime = 1796285286` (2026-12-03 08:08:06 UTC). H1(d) pairing-asset return path. |
| MockLpToken (TESTNET ONLY) | Base Sepolia 84532 TESTNET | [`0x09274C5b39605cB70e2aF03eaF369D78d9cEfCF0`](https://sepolia.basescan.org/address/0x09274C5b39605cB70e2aF03eaF369D78d9cEfCF0) | [`0x29c9edd75842223e39b773ee818a6c9e94ccb4f1eb0d40429f4a82ec9abfc160`](https://sepolia.basescan.org/tx/0x29c9edd75842223e39b773ee818a6c9e94ccb4f1eb0d40429f4a82ec9abfc160) | Still locked in the **original** mock locker. Name `Groken Mock LP (TESTNET ONLY)`. Not the Uniswap pair. |
| UniswapV2Factory (TESTNET) | Base Sepolia 84532 TESTNET | [`0xD20F566FBCF95A9BD5127Afd749bd49c670fDe99`](https://sepolia.basescan.org/address/0xD20F566FBCF95A9BD5127Afd749bd49c670fDe99) | [`0x1f9b8145517d733ed0e00e4cccde1065de66a2c07e61782efcc6dbe231f1b494`](https://sepolia.basescan.org/tx/0x1f9b8145517d733ed0e00e4cccde1065de66a2c07e61782efcc6dbe231f1b494) | Official Uniswap v2-core `v1.0.1`. Constructor `feeToSetter = dead`. `feeTo = 0`. Protocol fees cannot be turned on. Not an official Uniswap deployment. |
| UniswapV2Router02 (TESTNET) | Base Sepolia 84532 TESTNET | [`0x2E0733bb08F1CA5199D775Fdd310A90515c34344`](https://sepolia.basescan.org/address/0x2E0733bb08F1CA5199D775Fdd310A90515c34344) | [`0xbbc1d3aa36d67f3fd7940401b93b1e6b34c16417e1762ad4755feac7bb14c014`](https://sepolia.basescan.org/tx/0xbbc1d3aa36d67f3fd7940401b93b1e6b34c16417e1762ad4755feac7bb14c014) | Official Uniswap v2-periphery `v1.1.0-beta.0`. Constructor `(factory, WETH = 0x4200000000000000000000000000000000000006)`. |
| GRKN/WETH pair (TESTNET) | Base Sepolia 84532 TESTNET | [`0x228bDEB0235A6A8d6663399A08eD07545b9Df735`](https://sepolia.basescan.org/address/0x228bDEB0235A6A8d6663399A08eD07545b9Df735) | [`0x780a31104540c356b4f4de5e32566667619e6e01db856f125dc6c44ff1bf5d7c`](https://sepolia.basescan.org/tx/0x780a31104540c356b4f4de5e32566667619e6e01db856f125dc6c44ff1bf5d7c) | `factory.createPair(GRKN, WETH)`. Reserves: 80,000,000e18 GRKN and **131696399120995 wei WETH** (seed ETH; not a valuation). |
| Team wallet (beneficiary of the vest, **not** the vest) | Base Sepolia 84532 TESTNET | `0xC4137793697Eb95fa41454f22525C065D6E4CE02` | — | Throwaway TESTNET EOA. Receives `TeamVestLock.release()` only after the cliff. Holds 0 GRKN at launch (verified). |
| initialHolder (launch batch executor) | Base Sepolia 84532 TESTNET | `0x2c3DfED863Dd422b605c9a737deBc4123C1e8cE1` | — | Throwaway deployer / broadcast signer. Received 100% at mint. **GRKN balance after batch: 0** (verified). Do not treat as a treasury. |
| Proposer key | Base Sepolia 84532 TESTNET | `0x5a0C7B91FD38e9E046C7Bf2d8994A54a38481960` | — | Throwaway TESTNET EOA. Immutable proposer for treasury dust + pairing and listing. Not an admin role. |
| Pairing beneficiary / locker beneficiary | Base Sepolia 84532 TESTNET | `0x3F133aD764bbF185d3ab431880273EfDeeaD69e3` | — | Throwaway TESTNET EOA. After the 7-day delay, treasury pairing ETH/WETH may go here or to dead only. Also `ImmutableLPLock.beneficiary`. |
| Dust recipient (log-demo) | Base Sepolia 84532 TESTNET | `0x8cFC6078ED04c966037bF0c43FF9664D24834F6F` | — | One constructor-frozen log-demo address. Not a treasury. |
| Listing allowlist | Base Sepolia 84532 TESTNET | empty | — | Frozen at listing construct. Empty is valid. |
| AMM stand-in (was 80M) | Base Sepolia 84532 TESTNET | `0xDEFb9e5aF851D04F0ad4FB8357A00a47aCa0e6C1` | transfer [`0x57b378259f9cac320c7453dc95c2eeaa2cb3272b6436c39d0c288a6ca88286e6`](https://sepolia.basescan.org/tx/0x57b378259f9cac320c7453dc95c2eeaa2cb3272b6436c39d0c288a6ca88286e6) | **Emptied.** Was a test stand-in, not a pool. GRKN = 0 after moving 80M into the pair. Residual ETH `4715253500393` wei (gas leftover). Still on the listing project-blocklist. |
| Dead address | any EVM | `0x000000000000000000000000000000000000dEaD` | — | Conventional sink. Same sink at kill / T+90d / earlier. Not a project-controlled wallet. |
| Canonical WETH (pairing ERC-20) | Base Sepolia 84532 TESTNET | `0x4200000000000000000000000000000000000006` | — | Verified on 84532: `name()=Wrapped Ether`, `symbol()=WETH`, `decimals()=18`. OP-stack predeploy, not a Groken deploy. This repo still refuses 8453. |

## Distribution txs (TESTNET)

| Step | Tx |
|---|---|
| Mock LP approve for locker | [`0x8363b208e33d2f100e71b1b00286b1bc510d811854903fbdbf6863286a0a79a9`](https://sepolia.basescan.org/tx/0x8363b208e33d2f100e71b1b00286b1bc510d811854903fbdbf6863286a0a79a9) |
| 10M GRKN → TeamVestLock | [`0x0f92d1bdc69775d92214c396e6cd95ee49b8484359aac28ed837415c0e5aa295`](https://sepolia.basescan.org/tx/0x0f92d1bdc69775d92214c396e6cd95ee49b8484359aac28ed837415c0e5aa295) |
| 5M GRKN → ExperimentTreasury | [`0x8c958ae755425519b6cd3a9adf5fddb758a7cc96e885d0b6f9139e86cbbb9be0`](https://sepolia.basescan.org/tx/0x8c958ae755425519b6cd3a9adf5fddb758a7cc96e885d0b6f9139e86cbbb9be0) |
| 5M GRKN → ListingReserve | [`0xb779017a77843f6bc3337b5a159ecbaecc2b264f66ba729dac8f6b59f0d04091`](https://sepolia.basescan.org/tx/0xb779017a77843f6bc3337b5a159ecbaecc2b264f66ba729dac8f6b59f0d04091) |
| 80M GRKN → AMM stand-in | [`0x8f6cb5184d076db6e84513ef9e998585481dc39a4399f61c1a4f5dddb90b9947`](https://sepolia.basescan.org/tx/0x8f6cb5184d076db6e84513ef9e998585481dc39a4399f61c1a4f5dddb90b9947) |

## Clocks (TESTNET)

Read on-chain via `https://sepolia.base.org` (`eth_chainId` = 84532) on 2026-09-04 (block `46369317`). Per-contract clocks; they differ by a few seconds. Vest years are 365-day years. This table is TESTNET only. It does not prove an AMM path.

| Contract | Getter | Unix | UTC |
|---|---|---|---|
| TeamVestLock | `start` | `1788427320` | 2026-09-03 09:22:00 UTC |
| TeamVestLock | `cliffEnd` (`start + 365d`) | `1819963320` | 2027-09-03 09:22:00 UTC |
| TeamVestLock | `vestEnd` (`start + 4*365d`) | `1914571320` | 2030-09-02 09:22:00 UTC |
| ImmutableLPLock | `unlockTime` (`LOCK_DURATION` = 90d) | `1796203326` | 2026-12-02 09:22:06 UTC |
| ExperimentTreasury | `start` | `1788427322` | 2026-09-03 09:22:02 UTC |
| ExperimentTreasury | `experimentEnd` (`start + 90d`) | `1796203322` | 2026-12-02 09:22:02 UTC |
| ListingReserve | `start` | `1788427328` | 2026-09-03 09:22:08 UTC |
| ListingReserve | `experimentEnd` (`start + 90d`) | `1796203328` | 2026-12-02 09:22:08 UTC |

`TeamVestLock.releasable()` = 0; `released` = 0; beneficiary is the team wallet, not a hot wallet. Locker `release()` after `unlockTime` is the H1(d) pairing-asset return of **mock LP** to `PAIRING_BENEFICIARY` — still not a real pool. Until each `experimentEnd`, listing `sendToDead` and treasury `sendGrknToDead` are proposer-only.

## AMM liquidity txs (TESTNET, 2026-09-04)

| Step | Tx |
|---|---|
| Factory create | [`0x1f9b8145517d733ed0e00e4cccde1065de66a2c07e61782efcc6dbe231f1b494`](https://sepolia.basescan.org/tx/0x1f9b8145517d733ed0e00e4cccde1065de66a2c07e61782efcc6dbe231f1b494) |
| Router02 create | [`0xbbc1d3aa36d67f3fd7940401b93b1e6b34c16417e1762ad4755feac7bb14c014`](https://sepolia.basescan.org/tx/0xbbc1d3aa36d67f3fd7940401b93b1e6b34c16417e1762ad4755feac7bb14c014) |
| createPair(GRKN, WETH) | [`0x780a31104540c356b4f4de5e32566667619e6e01db856f125dc6c44ff1bf5d7c`](https://sepolia.basescan.org/tx/0x780a31104540c356b4f4de5e32566667619e6e01db856f125dc6c44ff1bf5d7c) |
| Deployer → stand-in gas (5e12 wei) | [`0x99584754a15b33552f36b083396777f21e927a7ae4533cd3aa1f6b506abe65c3`](https://sepolia.basescan.org/tx/0x99584754a15b33552f36b083396777f21e927a7ae4533cd3aa1f6b506abe65c3) |
| Stand-in → deployer 80M GRKN | [`0x57b378259f9cac320c7453dc95c2eeaa2cb3272b6436c39d0c288a6ca88286e6`](https://sepolia.basescan.org/tx/0x57b378259f9cac320c7453dc95c2eeaa2cb3272b6436c39d0c288a6ca88286e6) |
| approve GRKN for router | [`0x1904cc60f3a71eff56eeea91bdde202c128f1e5ba766454fe2b9375224cfd03d`](https://sepolia.basescan.org/tx/0x1904cc60f3a71eff56eeea91bdde202c128f1e5ba766454fe2b9375224cfd03d) |
| addLiquidityETH seed **131696399120995 wei** | [`0xcea27322b17a28374ef761a14b6d2ea0811f6e281b965c16ebd963c29981354c`](https://sepolia.basescan.org/tx/0xcea27322b17a28374ef761a14b6d2ea0811f6e281b965c16ebd963c29981354c) |
| approve pair LP for new locker | [`0xa1b6b551fe4d63f2b924645dca10a32245361eb339e0866bd4c6f433102314c5`](https://sepolia.basescan.org/tx/0xa1b6b551fe4d63f2b924645dca10a32245361eb339e0866bd4c6f433102314c5) |
| New ImmutableLPLock (real pair) | [`0x865f09adc68b202ecc9ac49adf12e887aee52c3be39fab03becb31d84c1534db`](https://sepolia.basescan.org/tx/0x865f09adc68b202ecc9ac49adf12e887aee52c3be39fab03becb31d84c1534db) |

Seed ETH is leftover deployer ETH after factory/router/pair/gas, not a valuation. No price / FDV / market-cap language. ListingReserve still blocklists the stand-in EOA, not the new pair (blocklist is immutable). Howey flags stay. Do not invent mainnet rows.
