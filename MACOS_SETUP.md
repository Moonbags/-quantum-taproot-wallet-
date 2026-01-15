# macOS Setup

This guide covers the macOS-specific dependencies and paths for running the Quantum Taproot Wallet scripts.

## 1. Install Homebrew

If you do not already have Homebrew installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 2. Install Dependencies

```bash
brew install bitcoin jq bc openssl vim
```

Notes:
- `bitcoin-cli` and `bitcoind` come from the `bitcoin` package.
- `xxd` is provided by `vim`.
- If `bitcoin-cli` is not found after install, run `brew link bitcoin`.

## 3. Verify Tools

```bash
command -v bitcoin-cli jq bc openssl xxd
```

## 4. Configure Bitcoin Core (Testnet)

Bitcoin Core uses `~/Library/Application Support/Bitcoin` on macOS.

```bash
mkdir -p ~/Library/Application\ Support/Bitcoin
cat > ~/Library/Application\ Support/Bitcoin/bitcoin.conf << EOF
[test]
rpcuser=quantum
rpcpassword=quantum123
rpcallowip=127.0.0.1
rpcport=18332

testnet=1
daemon=1
txindex=1
EOF
```

## 5. Start Bitcoin Core

```bash
bitcoind -testnet -daemon
```

## 6. Run the Wallet Scripts

```bash
./setup.sh
./taproot_multisig_setup.sh
```

For testing, see [TESTING.md](TESTING.md).
