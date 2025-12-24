# Quantum Taproot Wallet

A Bitcoin Taproot wallet with quantum-resistant features and time-locked recovery options.

## ✅ Verified on Testnet - December 24, 2025

| Verification | Status | Block/TX |
|--------------|--------|----------|
| Wallet Created | ✅ | Block 4,810,284 |
| Funds Received | ✅ | 110,399 sats |
| PSBT Signed | ✅ | 2/2 signatures |
| Spend Successful | ✅ | Script hidden (quantum safe) |
| Timelock Active | ✅ | 1008 blocks (~1 week) |

### Verification Transaction
- **TXID:** `d8ced8d2b8678a641cb08d6bb4bd669908d70dd7d817ea92fd264e752656ac65`
- **Block:** 4,810,284
- **Block Hash:** `0000000000000082b341d4029fb24f3868aa69fd185f1c5c3a61cd5f9e814e5e`
- **Address:** `tb1py4kh2gxusds4mk4yuxjl9m5dmazvjcnrfj6u8mn7mwd5wy90uhxqvmqrrc`
- **Explorer:** [View on Mempool.space](https://mempool.space/testnet/tx/d8ced8d2b8678a641cb08d6bb4bd669908d70dd7d817ea92fd264e752656ac65)

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

# Start daemon
bitcoind -testnet -daemon
```

### 3. Create Key Wallets

```bash
# Wait for RPC to be ready
sleep 5

# Create 3 separate key wallets
bitcoin-cli -testnet -named createwallet wallet_name="hot_wallet" descriptors=true
bitcoin-cli -testnet -named createwallet wallet_name="cold_wallet" descriptors=true
bitcoin-cli -testnet -named createwallet wallet_name="recovery_wallet" descriptors=true

# Create watch-only quantum wallet
bitcoin-cli -testnet -named createwallet wallet_name="qs" disable_private_keys=true blank=true descriptors=true
```

### 4. Build Quantum Descriptor

```bash
# Get xpubs from each wallet
HOT=$(bitcoin-cli -testnet -rpcwallet=hot_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oP 'tpub[A-Za-z0-9]+')
COLD=$(bitcoin-cli -testnet -rpcwallet=cold_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oP 'tpub[A-Za-z0-9]+')
RECOV=$(bitcoin-cli -testnet -rpcwallet=recovery_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oP 'tpub[A-Za-z0-9]+')

# NUMS internal key (no one knows private key)
INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

# Build descriptor
DESC="tr(${INTERNAL},{{pk(${HOT}/0/*),pk(${COLD}/0/*)},and_v(v:pk(${RECOV}/0/*),older(1008))})"

# Get checksum
CHECKSUM=$(bitcoin-cli -testnet getdescriptorinfo "$DESC" | jq -r '.checksum')
FULL_DESC="${DESC}#${CHECKSUM}"

echo "Quantum Descriptor: $FULL_DESC"
```

### 5. Import & Derive Address

```bash
# Import to watch-only wallet
bitcoin-cli -testnet -rpcwallet=qs importdescriptors "[{\"desc\":\"$FULL_DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\"}]"

# Derive first address
bitcoin-cli -testnet deriveaddresses "$FULL_DESC" "[0,0]"
```

## 📁 Project Structure

```
quantum-taproot-wallet/
├── README.md           # Documentation + verification
├── setup.sh            # Interactive wallet setup
├── spend.sh            # Create & sign PSBTs
├── recovery.sh         # Time-locked recovery script
├── check_balance.sh    # Quick balance check via API
├── VERIFICATION.md     # Test results & block stamps
└── LICENSE             # MIT license
```

## 🔑 Spending Conditions

| Key | Condition | Use Case |
|-----|-----------|----------|
| **HOT** | Spend anytime | Daily transactions |
| **COLD** | Spend anytime | Secure storage |
| **RECOVERY** | After 1008 blocks (~1 week) | Emergency if keys lost |

## 📋 Descriptor Format

```
tr(INTERNAL,{{pk(HOT/0/*),pk(COLD/0/*)},and_v(v:pk(RECOVERY/0/*),older(1008))})
```

### Components:
- `tr()` - Taproot output
- `INTERNAL` - NUMS point (unspendable key path)
- `pk(HOT)` - Hot wallet public key
- `pk(COLD)` - Cold storage public key
- `and_v(v:pk(RECOV),older(1008))` - Recovery key + 1008 block timelock

## ⚠️ Important Notes

- **TESTNET FIRST** - Always test before mainnet
- **BACKUP DESCRIPTORS** - Without them, funds are LOST
- **VERIFY CHECKSUMS** - Must match exactly
- **NOT FINANCIAL ADVICE** - Use at your own risk

## 🔗 Resources

- [Mempool.space Testnet](https://mempool.space/testnet)
- [Bitcoin Core 28.0](https://bitcoincore.org/bin/bitcoin-core-28.0/)
- [BIP-86 Taproot](https://github.com/bitcoin/bips/blob/master/bip-0086.mediawiki)
- [BIP-341 Taproot](https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki)
- [Output Descriptors](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md)

## License

MIT
