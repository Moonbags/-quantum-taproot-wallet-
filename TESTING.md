# Testing Infrastructure

Multi-network testing framework for quantum taproot wallet development and validation.

## 🧪 Test Networks

### 1. REGTEST - Isolated Script Iteration

**Purpose**: Fastest development cycle, instant block generation

**Setup**:
```bash
# Start regtest daemon
bitcoin-cli -regtest -daemon -txindex

# Run test
./test_regtest.sh
```

**Features**:
- ✅ Instant block generation
- ✅ No network sync required
- ✅ Perfect for rapid iteration
- ✅ Isolated from other networks

**Quick Commands**:
```bash
# Generate blocks
bitcoin-cli -regtest generatetoaddress 1 $(bitcoin-cli -regtest getnewaddress)

# Check balance
bitcoin-cli -regtest -rpcwallet=qs getbalance

# List UTXOs
bitcoin-cli -regtest -rpcwallet=qs listunspent

# Create and fund PSBT
bitcoin-cli -regtest -rpcwallet=qs walletcreatefundedpsbt \
  '[]' '[{"tb1p...": 0.0001}]' 0 '{"fee_rate": 1}'
```

---

### 2. CUSTOM SIGNET - Edge Case Testing

**Purpose**: Test edge cases, spam floods, timelock scenarios

**Setup**:
```bash
# Start custom signet docker
docker run -it --name custom-signet -p 38332:38332 nbd-wtf/signet:custom

# Or if already created
docker start custom-signet

# Run test
./test_custom_signet.sh
```

**Features**:
- ✅ Full control over block generation
- ✅ Test spam floods (100+ blocks)
- ✅ Timelock edge cases
- ✅ Mempool pressure testing
- ✅ Low fee transaction testing

**Quick Commands**:
```bash
# Generate many blocks (spam flood test)
bitcoin-cli -signet=custom -rpcport=38332 generatetoaddress 110 $(bitcoin-cli -signet=custom -rpcport=38332 getnewaddress)

# Test timelock
bitcoin-cli -signet=custom -rpcport=38332 generatetoaddress 1008 $(bitcoin-cli -signet=custom -rpcport=38332 getnewaddress)

# Create low fee transaction
bitcoin-cli -signet=custom -rpcport=38332 fundrawtransaction <hex> '{"fee_rate": 0.1}'
```

---

### 3. PUBLIC SIGNET - Stable PSBT Finalization

**Purpose**: Realistic network conditions, stable PSBT testing

**Setup**:
```bash
# Start signet daemon
bitcoin-cli -signet -daemon -txindex

# Wait for sync
bitcoin-cli -signet getblockchaininfo

# Run test
./test_public_signet.sh
```

**Features**:
- ✅ Real network conditions
- ✅ Stable PSBT finalization
- ✅ Public faucets available
- ✅ Realistic fee markets

**Get Funds**:
- https://signetfaucet.com
- https://signet.bc-2.jp

**Quick Commands**:
```bash
# Create PSBT
bitcoin-cli -signet -rpcwallet=qs walletcreatefundedpsbt \
  '[]' '[{"tb1p...": 0.0001}]' 0 '{"fee_rate": 1}' | jq .psbt

# Fund raw transaction
bitcoin-cli -signet fundrawtransaction <hex> | jq .hex

# Finalize and broadcast
bitcoin-cli -signet finalizepsbt <psbt> | jq .hex | xargs bitcoin-cli -signet sendrawtransaction
```

**Explorer**: https://mempool.space/signet

---

### 4. TESTNET4 - Adversarial Spam Testing

**Purpose**: Final pre-mainnet validation, adversarial conditions

**Setup**:
```bash
# Start testnet4 daemon
bitcoin-cli -testnet4 -daemon -txindex

# Wait for sync
bitcoin-cli -testnet4 getblockchaininfo

# Run test
./test_testnet4.sh
```

**Features**:
- ✅ Most realistic testnet
- ✅ Adversarial spam testing
- ✅ Mempool pressure
- ✅ Final validation before mainnet

**Get Funds**:
- https://faucet.testnet4.dev
- https://testnet4.bitcoindevkit.org/faucet

**Quick Commands**:
```bash
# Create spam transactions
for i in {1..10}; do
  bitcoin-cli -testnet4 -rpcwallet=qs walletcreatefundedpsbt \
    '[]' "[{\"$(bitcoin-cli -testnet4 getnewaddress)\": 0.00001}]" \
    0 '{"fee_rate": 1}' | jq -r .psbt | \
    xargs bitcoin-cli -testnet4 -rpcwallet=hot_wallet walletprocesspsbt | \
    jq -r .hex | xargs bitcoin-cli -testnet4 finalizepsbt | \
    jq -r .hex | xargs bitcoin-cli -testnet4 sendrawtransaction
done

# Test timelock at exactly 1008 blocks
bitcoin-cli -testnet4 -rpcwallet=qs listunspent | jq '.[] | select(.confirmations == 1008)'
```

**Explorer**: https://mempool.space/testnet4

---

## 🚀 Quick Start

### Interactive Test Runner

```bash
./test_runner.sh
```

Select from menu:
1. REGTEST - Fast iteration
2. CUSTOM SIGNET - Edge cases
3. PUBLIC SIGNET - Stable testing
4. TESTNET4 - Final validation

### Direct Network Testing

```bash
# Regtest
./test_regtest.sh

# Custom Signet (requires docker)
./test_custom_signet.sh

# Public Signet
./test_public_signet.sh

# Testnet4
./test_testnet4.sh
```

---

## 📋 Test Checklist

### REGTEST
- [ ] Wallet creation
- [ ] Descriptor validation
- [ ] Address derivation
- [ ] Funding transaction
- [ ] PSBT creation
- [ ] Multi-signature signing
- [ ] Script-path spending
- [ ] Timelock recovery

### CUSTOM SIGNET
- [ ] Spam flood (100+ blocks)
- [ ] Timelock edge cases
- [ ] Low fee transactions
- [ ] Mempool pressure
- [ ] Recovery path at exactly 1008 blocks

### PUBLIC SIGNET
- [ ] Real network sync
- [ ] Faucet funding
- [ ] PSBT finalization
- [ ] Transaction broadcasting
- [ ] Block confirmation

### TESTNET4
- [ ] Adversarial spam
- [ ] High fee rate testing
- [ ] Mempool congestion
- [ ] Timelock precision
- [ ] Multi-signature flows

---

## 🔧 Network Configuration

### Bitcoin Core Config

Add to `~/.bitcoin/bitcoin.conf`:

```conf
# Regtest
[regtest]
rpcuser=quantum
rpcpassword=quantum123
rpcallowip=127.0.0.1
rpcport=18443
txindex=1

# Signet
[signet]
rpcuser=quantum
rpcpassword=quantum123
rpcallowip=127.0.0.1
rpcport=38332
txindex=1

# Testnet4
[testnet4]
rpcuser=quantum
rpcpassword=quantum123
rpcallowip=127.0.0.1
rpcport=18334
txindex=1
```

### Docker Setup (Custom Signet)

```bash
# Pull image
docker pull nbd-wtf/signet:custom

# Run container
docker run -it --name custom-signet \
  -p 38332:38332 \
  nbd-wtf/signet:custom

# Check logs
docker logs custom-signet

# Stop container
docker stop custom-signet

# Remove container
docker rm custom-signet
```

---

## 🐛 Troubleshooting

### Regtest: "Daemon not running"
```bash
bitcoind -regtest -daemon -txindex
```

### Custom Signet: "Cannot connect"
```bash
# Check docker is running
docker ps | grep custom-signet

# Check port
netstat -an | grep 38332

# View logs
docker logs custom-signet
```

### Public Signet/Testnet4: "Not synced"
```bash
# Check sync status
bitcoin-cli -signet getblockchaininfo | jq '{blocks, headers, verificationprogress}'

# Wait for sync
watch -n 5 'bitcoin-cli -signet getblockchaininfo | jq .verificationprogress'
```

### PSBT: "Insufficient funds"
```bash
# Check balance
bitcoin-cli -regtest -rpcwallet=qs getbalance

# Generate more blocks (regtest only)
bitcoin-cli -regtest generatetoaddress 101 $(bitcoin-cli -regtest getnewaddress)

# Use faucet (signet/testnet4)
# Visit faucet URLs from test scripts
```

---

## 📊 Test Results

Track test results across networks:

| Network | Wallet Creation | Funding | PSBT | Script-Path | Timelock |
|---------|----------------|---------|------|-------------|----------|
| REGTEST | ✅ | ✅ | ✅ | ✅ | ✅ |
| CUSTOM SIGNET | ✅ | ✅ | ✅ | ✅ | ✅ |
| PUBLIC SIGNET | ✅ | ✅ | ✅ | ✅ | ✅ |
| TESTNET4 | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 🔗 Resources

- **Bitcoin Core Docs**: https://bitcoincore.org/en/doc/
- **Taproot BIP**: https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki
- **Signet Faucet**: https://signetfaucet.com
- **Testnet4 Faucet**: https://faucet.testnet4.dev
- **Mempool Explorer**: https://mempool.space

