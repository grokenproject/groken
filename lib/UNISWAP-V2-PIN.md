# Uniswap V2 vendor pin (TESTNET deploy dependency)

Official Uniswap sources copied so Base Sepolia (84532) can run a canonical
Uniswap V2 factory + Router02. This is not an official Uniswap deployment
and is not an endorsement by Uniswap or Base.

| Package | Upstream | Git SHA | Tag |
|---|---|---|---|
| v2-core | https://github.com/Uniswap/v2-core | `4dd59067c76dea4a0e8e4bfdda41877a6b16dedc` | `v1.0.1` |
| v2-periphery | https://github.com/Uniswap/v2-periphery | `a86e696931c995fb85b4ae297c24b81c3dca8e2f` | `v1.1.0-beta.0` (includes Router02) |
| solidity-lib | https://github.com/Uniswap/solidity-lib | `2e31d2c594caf01f16041cd73d8701c43b87cc16` | `v1.1.1` |

`UniswapV2Library` init-code hash is patched to
`9fa54f876cfb7b9bc307fe355e1a18c3590171a0fd0ac751a3527717896f67e8`
(`keccak256` of this repo's `UniswapV2Pair` creation bytecode, solc `0.5.16`
optimize 999999). Foundry/solc metadata differs from the Ethereum-mainnet
artifact, so the official hash would make `pairFor` miss. The patch does not
change AMM math.
