# Quantum Taproot Wallet

A Bitcoin Taproot wallet setup tool with quantum-resistant features and time-locked recovery options.

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

## Prerequisites: Bitcoin Core v30.0

This wallet requires Bitcoin Core v30.0+ for full Taproot support. Download from the official repository:

**Official Download:** https://bitcoincore.org/bin/bitcoin-core-30.0/

### Verify Download

Download `bitcoin-30.0-x86_64-linux-gnu.tar.gz` (Linux) or your platform's binary, then validate signatures before extracting:

```bash
curl -O https://bitcoincore.org/bin/bitcoin-core-30.0/SHA256SUMS.asc
curl -O https://bitcoincore.org/bin/bitcoin-core-30.0/bitcoin-30.0-x86_64-linux-gnu.tar.gz
sha256sum --check SHA256SUMS --ignore-missing
gpg --verify SHA256SUMS.asc
```

**Note:** Requires Bitcoin Core PGP keys imported. See [Bitcoin Core verification guide](https://bitcoincore.org/en/download/).

### Signet Setup for Wallet Testing

Extract and configure for Signet (recommended for quantum-taproot-wallet testing):

```bash
tar -xzf bitcoin-30.0-x86_64-linux-gnu.tar.gz
cd bitcoin-30.0/bin
mkdir -p ~/.bitcoin && echo -e "signet=1\ndaemon=1" > ~/.bitcoin/bitcoin.conf
./bitcoind -signet
```

Wait for initial sync (~10-30 minutes), then verify:

```bash
bitcoin-cli -signet getblockchaininfo
```

### Quick Test Commands

```bash
bitcoin-cli -signet getnetworkinfo      # Confirms signet connection
bitcoin-cli -signet createwallet "test" # Create fresh test wallet
```

## Setup

Run the setup script to configure your quantum taproot wallet:

```bash
./setup.sh
```

⚠️ **NOT FINANCIAL ADVICE. Test on testnet first.**
