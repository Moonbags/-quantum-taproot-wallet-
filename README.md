# Quantum Taproot Wallet

© 2025 sha256sol (Moonbags). All rights reserved. **Patent pending.**

## IP Protection
- Timestamp: 2025-12-31 [SHA256 hash below]
- US Copyright registered: [TXu####-###]
- Provisional patent filed: [####/####]

Private development repository.

**Licensing/Partnerships:** sha256sol@protonmail.com

---

A Bitcoin Taproot wallet with quantum-resistant features and time-locked recovery options.

## ✅ Verified on Testnet - December 24, 2025

| Verification | Status | Link |
|--------------|--------|------|
| Wallet Created | ✅ | [Block 4,810,284](https://mempool.space/testnet/block/0000000000000082b341d4029fb24f3868aa69fd185f1c5c3a61cd5f9e814e5e) |
| Funds Received | ✅ | [110,399 sats](https://mempool.space/testnet/tx/d8ced8d2b8678a641cb08d6bb4bd669908d70dd7d817ea92fd264e752656ac65) |
| PSBT Signed | ✅ | 2/2 signatures |
| Spend Successful | ✅ | Script hidden (quantum safe) |
| Timelock Active | ✅ | 1008 blocks (~1 week) |

### 🔗 Verified Links

| Resource | Link |
|----------|------|
| **Funding TX** | [d8ced8d2...56ac65](https://mempool.space/testnet/tx/d8ced8d2b8678a641cb08d6bb4bd669908d70dd7d817ea92fd264e752656ac65) |
| **Block** | [4,810,284](https://mempool.space/testnet/block/0000000000000082b341d4029fb24f3868aa69fd185f1c5c3a61cd5f9e814e5e) |
| **Original Address** | [tb1py4kh2g...mqrrc](https://mempool.space/testnet/address/tb1py4kh2gxusds4mk4yuxjl9m5dmazvjcnrfj6u8mn7mwd5wy90uhxqvmqrrc) |
| **Quantum Address** | [tb1pmtcn2f...jnld](https://mempool.space/testnet/address/tb1pmtcn2fl9f0sd24q22fhv0cardxwmnh9fm244m9yw04tcna2xqj0q2gjnld) |

## 🛡️ Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                    TAPROOT OUTPUT                           │
│  Internal Key: NUMS point (unspendable)                     │
├─────────────────────────────────────────────────────────────┤
│  Script Tree:                                               │
│  ├── HOT key     → spend anytime (daily use)               │
│  ├── COLD key    → spend anytime (secure storage)          │
│  └── RECOVERY    → spend after 1008 blocks (~1 week)       │
└─────────────────────────────────────────────────────────────┘
```

### Quantum Safety
- **Key-path spends** hide the script tree completely
- Attacker sees only a single signature, not the multi-key structure
- No script revealed = no quantum attack surface exposed
- Uses NUMS (Nothing Up My Sleeve) internal key

## 🚀 Quick Start

### 1. Install Bitcoin Core 28.0+

```bash
# Linux (Ubuntu/Debian)
cd /tmp
curl -LO https://bitcoincore.org/bin/bitcoin-core-28.0/bitcoin-28.0-x86_64-linux-gnu.tar.gz
tar -xzf bitcoin-28.0-x86_64-linux-gnu.tar.gz
sudo cp bitcoin-28.0/bin/* /usr/local/bin/
sudo chmod +x /usr/local/bin/bitcoin*

# macOS
brew install bitcoin
```

### 2. Configure Testnet

```bash
mkdir -p ~/.bitcoin
cat > ~/.bitcoin/bitcoin.conf << EOF
testnet=1
daemon=1
txindex=1

[test]
rpcuser=quantum
rpcpassword=quantum123
rpcallowip=127.0.0.1
rpcport=18332
EOF
```

### 3. Setup Quantum Wallet

```bash
./setup.sh
```

## 🧪 Testing Infrastructure

Multi-network testing framework for development and validation across different environments.

### Quick Test Runner

```bash
./test_runner.sh
```

Select from:
1. **REGTEST** - Isolated script iteration (fastest development)
2. **CUSTOM SIGNET** - Edge case testing (requires docker)
3. **PUBLIC SIGNET** - Stable PSBT finalization
4. **TESTNET4** - Adversarial spam (final pre-mainnet)

### Individual Test Scripts

```bash
# Regtest - Fast iteration
./test_regtest.sh

# Custom Signet - Edge cases (docker required)
docker run -it --name custom-signet -p 38332:38332 nbd-wtf/signet:custom
./test_custom_signet.sh

# Public Signet - Stable testing
./test_public_signet.sh

# Testnet4 - Final validation
./test_testnet4.sh
```

### Test Network Features

| Network | Speed | Use Case | Faucet |
|---------|-------|----------|--------|
| **REGTEST** | Instant | Rapid development | Self-generated |
| **CUSTOM SIGNET** | Fast | Edge cases, spam floods | Self-generated |
| **PUBLIC SIGNET** | Real-time | Stable PSBT testing | [signetfaucet.com](https://signetfaucet.com) |
| **TESTNET4** | Real-time | Adversarial testing | [faucet.testnet4.dev](https://faucet.testnet4.dev) |

📖 **Full Testing Documentation**: See [TESTING.md](TESTING.md) for detailed setup, commands, and troubleshooting.

📊 **Verification Status**: See [VERIFICATION_STATUS.md](VERIFICATION_STATUS.md) for current test status across all networks.

## 📚 Usage

### Check Balance

```bash
./check_balance.sh <address>
```

### Spend Funds

```bash
./spend.sh
```

### Recovery (After 1008 blocks)

```bash
./recovery.sh <destination_address>
```

## 🔗 Resources

- **Verification Report**: [VERIFICATION.md](VERIFICATION.md)
- **Testing Guide**: [TESTING.md](TESTING.md)
- **Blockchain Explorer**: [mempool.space](https://mempool.space)
