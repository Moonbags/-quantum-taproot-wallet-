# Quantum Taproot Wallet

A Bitcoin Taproot wallet with quantum-resistant features and time-locked recovery options.

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

## 📁 Project Structure

```
quantum-taproot-wallet/
├── README.md           # Documentation
├── setup.sh            # Interactive wallet setup
├── spend.sh            # Create & sign spending PSBTs
├── recovery.sh         # Time-locked recovery script
├── check_balance.sh    # Quick balance check via API
└── LICENSE             # MIT license
```

## 🚀 Quick Start

### 1. Install Bitcoin Core (testnet)
```bash
# Linux
cd /tmp && curl -LO https://bitcoincore.org/bin/bitcoin-core-28.0/bitcoin-28.0-x86_64-linux-gnu.tar.gz
tar -xzf bitcoin-28.0-x86_64-linux-gnu.tar.gz
sudo cp bitcoin-28.0/bin/* /usr/local/bin/

# macOS
brew install bitcoin

# Configure testnet
mkdir -p ~/.bitcoin
cat > ~/.bitcoin/bitcoin.conf << EOF
testnet=1
daemon=1
txindex=1
[test]
rpcuser=quantum
rpcpassword=quantum123
EOF

# Start
bitcoind -testnet -daemon
```

### 2. Create Wallets
```bash
# Create 3 key wallets
bitcoin-cli -testnet createwallet "hot_wallet"
bitcoin-cli -testnet createwallet "cold_wallet"
bitcoin-cli -testnet createwallet "recovery_wallet"

# Run interactive setup
./setup.sh
```

### 3. Fund & Spend
```bash
# Check balance (works without full sync)
./check_balance.sh <address>

# Create spending transaction
./spend.sh

# Emergency recovery (after 1008 blocks)
./recovery.sh
```

## 🔑 Wallets Created

| Wallet | Purpose | Access |
|--------|---------|--------|
| hot_wallet | Daily spending | Online |
| cold_wallet | Secure storage | Offline/Hardware |
| recovery_wallet | Emergency backup | Safe deposit |
| qs | Watch-only quantum wallet | Any device |

## 📋 Your Descriptor

```
tr(INTERNAL,{{pk(HOT/0/*),pk(COLD/0/*)},and_v(v:pk(RECOVERY/0/*),older(1008))})
```

### Spending Conditions:
1. **HOT** - Instant spend with hot wallet key
2. **COLD** - Instant spend with cold storage key  
3. **RECOVERY** - Spend after ~1 week (1008 blocks) if keys lost

## ⚠️ Important Notes

- **TESTNET FIRST** - Always test before mainnet
- **BACKUP DESCRIPTORS** - Without them, funds are lost
- **VERIFY CHECKSUMS** - Descriptors must match exactly
- **NOT FINANCIAL ADVICE** - Use at your own risk

## 🔗 Resources

- [Mempool.space Testnet](https://mempool.space/testnet)
- [Bitcoin Core Docs](https://bitcoincore.org/en/doc/)
- [BIP-86 (Taproot)](https://github.com/bitcoin/bips/blob/master/bip-0086.mediawiki)
- [Output Descriptors](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md)

## License

MIT
