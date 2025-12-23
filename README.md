# Quantum Taproot Wallet

A Bitcoin Taproot wallet setup tool with quantum-resistant features and time-locked recovery options.

## Features

- **NUMS internal key** (0250929...) - no private key exists, forces script-path spends only
- **2-of-2 multisig** - requires both hot AND cold keys for normal spending
- **Time-locked recovery** - alternative recovery path using single recovery key after 1008 blocks (~1 week)
- **Production-ready** for Bitcoin Core 25.0+ on Signet/Mainnet

## Project Structure

```
quantum-taproot-wallet/
├── README.md          # Main docs + setup
├── setup.sh           # Executable script
├── LICENSE            # MIT license
├── .gitignore         # Bytecode protection
└── test/              # (Optional) testnet examples
    ├── test-descriptor.sh
    └── verify.sh
```

## Setup

### Prerequisites

- Bitcoin Core 25.0+ with Signet enabled
- Ensure `signet=1` in your `bitcoin.conf`
- Synced Signet node

### Local Test Steps

1. Ensure Bitcoin Core is running on Signet:
   ```bash
   bitcoin-cli -signet getblockchaininfo
   ```

2. Make the script executable and run it:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. Fund the generated address using a Signet faucet:
   - https://signetfaucet.com
   - https://hoodscan.com/faucet

4. Verify balance:
   ```bash
   bitcoin-cli -signet -rpcwallet=qs getbalance
   ```

## Security

- Taproot-compatible with quantum-resistant NUMS internal key
- Key-path spending is impossible (no private key for internal key)
- All spends reveal script-path with proper signatures
- Time-locked recovery mechanism for emergency access

⚠️ **NOT FINANCIAL ADVICE. Test on Signet first.**
