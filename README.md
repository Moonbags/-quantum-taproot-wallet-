# Quantum Taproot Wallet

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

### 3. Create Wallet

```bash
./setup.sh
```

## 🤖 Dexter Financial Analysis Integration

This wallet now integrates **Dexter** - an autonomous AI agent for deep financial research - to complement your Bitcoin operations with market analysis, DeFi insights, and trading intelligence.

### Quick Start with Dexter

```bash
# 1. Install prerequisites
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Clone and setup Dexter
git clone https://github.com/virattt/dexter.git ~/dexter
cd ~/dexter && uv sync

# 3. Configure API keys
cp .env.example .env
# Edit .env and add:
#   OPENAI_API_KEY=sk-your-key-here
#   FINANCIAL_DATASETS_API_KEY=your-key-here

# 4. Run financial analysis
cd /path/to/quantum-taproot-wallet
./dexter_cli.sh "Bitcoin price trends and optimal transaction timing"
```

### Use Cases

**Market Analysis + Wallet Operations:**
```bash
# Analyze market conditions before wallet operations
./examples/bitcoin_analysis_workflow.sh
```

**DeFi Protocol Research:**
```bash
# Research DRIFT, Pendle, GrokSwap protocols
python3 examples/defi_analysis.py
```

**Programmatic Integration:**
```python
from dexter_backtesting import DexterBacktest

backtest = DexterBacktest()
research = backtest.pre_trade_research("Bitcoin hash rate trends")
print(research['analysis'])
```

**CLI Queries:**
```bash
# Crypto analysis
./dexter_cli.sh "Solana network congestion impact on transaction fees"

# DeFi analysis  
./dexter_cli.sh "DRIFT protocol debt-to-equity ratio and solvency"

# Market timing
./dexter_cli.sh "Optimal Bitcoin transaction timing based on mempool"
```

📚 **[Complete Dexter Integration Guide →](DEXTER_INTEGRATION.md)**

---

## 📁 Project Structure

```
.
├── setup.sh                    # Wallet creation script
├── spend.sh                    # Spend from wallet
├── recovery.sh                 # Time-locked recovery
├── check_balance.sh            # Check balance via API
├── dexter_cli.sh              # Dexter CLI interface
├── dexter_backtesting.py      # Backtesting integration
├── dexter_integration/        # Python module
│   ├── agent_wrapper.py       # Dexter agent wrapper
│   └── __init__.py
├── examples/                  # Example workflows
│   ├── bitcoin_analysis_workflow.sh
│   └── defi_analysis.py
├── DEXTER_INTEGRATION.md      # Full integration guide
└── README.md                  # This file
```

## 🔧 Wallet Usage

### Check Balance

```bash
./check_balance.sh tb1p...
```

### Spend Funds

```bash
./spend.sh
```

### Recovery (after timelock)

```bash
./recovery.sh <destination_address>
```

## 📚 Documentation

- **[Dexter Integration Guide](DEXTER_INTEGRATION.md)** - Complete guide for financial analysis integration
- **[Verification Report](VERIFICATION.md)** - Testnet verification details

## ⚠️ Important Notes

- **NOT FINANCIAL ADVICE** - Test on testnet first
- **Backup your wallets** - Store descriptors securely
- **API costs** - Dexter uses OpenAI and Financial Datasets APIs (paid)
- **Security** - Never commit `.env` file or private keys

## 🔗 Resources

- [Bitcoin Core](https://bitcoincore.org/)
- [Taproot](https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki)
- [Dexter Agent](https://github.com/virattt/dexter)
- [Financial Datasets](https://financialdatasets.ai)

## 📜 License

MIT License - See [LICENSE](LICENSE) file

---

**Built with ❤️ for the Bitcoin and DeFi communities**
