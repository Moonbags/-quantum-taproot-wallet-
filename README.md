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

## macOS Dependencies

Install required dependencies using Homebrew:

```bash
# Update Homebrew and install dependencies
brew update
brew install \
  bitcoin \
  jq \
  bc \
  xxd  # already included in macOS but ensuring availability

# Verify installations
bitcoin-cli -testnet getblockchaininfo  # should connect
jq --version
echo "10 * 2" | bc  # math for CSV blocks
```

**That's it.** No Python, no rust-bitcoin, no extra libs. Pure bitcoin-cli + macOS builtins.

### Potential macOS RPC Connection Fixes

If `bitcoin-cli` fails to connect, try these steps:

```bash
# Restart Bitcoin service
brew services restart bitcoin

# Configure ~/.bitcoin/bitcoin.conf
echo "testnet=1
rpcuser=user
rpcpassword=pass
rpcallowip=127.0.0.1
rpcport=18332" > ~/.bitcoin/bitcoin.conf

# Restart Bitcoin service again
brew services restart bitcoin

# Test RPC connection
bitcoin-cli -testnet -rpcuser=user -rpcpassword=pass getblockchaininfo
```

## Setup

Run the setup script to configure your quantum taproot wallet:

```bash
./setup.sh
```

The script will automatically check for required dependencies before proceeding.

⚠️ **NOT FINANCIAL ADVICE. Test on testnet first.**
