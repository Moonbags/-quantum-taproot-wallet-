#!/bin/bash
# REGTEST - Isolated script iteration for rapid development
# Fastest way to test quantum taproot wallet changes
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         REGTEST - ISOLATED TESTING                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

NET="-regtest"
RPC_PORT=18443

# Check if regtest daemon is running
if ! bitcoin-cli "$NET" getblockchaininfo &> /dev/null; then
    echo "⚠️  Regtest daemon not running. Starting..."
    echo "   Run: bitcoind -regtest -daemon -txindex"
    echo "   Or: bitcoind -regtest -daemon -txindex -rpcport=$RPC_PORT"
    exit 1
fi

echo "✅ Regtest daemon running"

# Create test wallets
echo ""
echo "Creating test wallets..."

for WALLET in hot_wallet cold_wallet recovery_wallet; do
    if bitcoin-cli "$NET" -rpcwallet=$WALLET getwalletinfo &> /dev/null 2>&1; then
        echo "  $WALLET exists ✓"
    else
        bitcoin-cli "$NET" -named createwallet wallet_name="$WALLET" descriptors=true > /dev/null
        echo "  $WALLET created ✓"
    fi
done

# Create watch-only quantum wallet
if bitcoin-cli "$NET" -rpcwallet=qs getwalletinfo &> /dev/null 2>&1; then
    echo "  qs (quantum) exists ✓"
else
    bitcoin-cli "$NET" -named createwallet wallet_name="qs" disable_private_keys=true blank=true descriptors=true > /dev/null
    echo "  qs (quantum) created ✓"
fi

# Extract xpubs
echo ""
echo "Extracting public keys..."

HOT=$(bitcoin-cli "$NET" -rpcwallet=hot_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oP 'tpub[A-Za-z0-9]+')
COLD=$(bitcoin-cli "$NET" -rpcwallet=cold_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oP 'tpub[A-Za-z0-9]+')
RECOV=$(bitcoin-cli "$NET" -rpcwallet=recovery_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oP 'tpub[A-Za-z0-9]+')

echo "  HOT:      ${HOT:0:20}..."
echo "  COLD:     ${COLD:0:20}..."
echo "  RECOVERY: ${RECOV:0:20}..."

# NUMS internal key
INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

# Build descriptor
DESC="tr(${INTERNAL},{{pk(${HOT}/0/*),pk(${COLD}/0/*)},and_v(v:pk(${RECOV}/0/*),older(1008))})"

echo ""
echo "Validating descriptor..."
RESULT=$(bitcoin-cli "$NET" getdescriptorinfo "$DESC")
CHECKSUM=$(echo "$RESULT" | jq -r '.checksum')
FULL_DESC="${DESC}#${CHECKSUM}"

# Import to quantum wallet
echo "Importing descriptor..."
bitcoin-cli "$NET" -rpcwallet=qs importdescriptors "[{\"desc\":\"$FULL_DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\"}]" > /dev/null

# Derive quantum address
QUANTUM_ADDR=$(bitcoin-cli "$NET" deriveaddresses "$FULL_DESC" "[0,0]" | jq -r '.[0]')

# Generate blocks to get some coins
echo ""
echo "Generating initial blocks..."
MINER_ADDR=$(bitcoin-cli "$NET" -rpcwallet=hot_wallet getnewaddress)
bitcoin-cli "$NET" generatetoaddress 101 "$MINER_ADDR" > /dev/null
echo "✅ 101 blocks generated (mature coinbase)"

# Fund quantum address
echo ""
echo "Funding quantum address..."
FUND_AMT=0.001
bitcoin-cli "$NET" -rpcwallet=hot_wallet sendtoaddress "$QUANTUM_ADDR" "$FUND_AMT" > /dev/null
bitcoin-cli "$NET" generatetoaddress 1 "$MINER_ADDR" > /dev/null
echo "✅ Funded $FUND_AMT BTC to quantum address"

# Check balance
BALANCE=$(bitcoin-cli "$NET" -rpcwallet=qs getbalance)
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         REGTEST WALLET READY                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "💰 QUANTUM ADDRESS:"
echo "   $QUANTUM_ADDR"
echo ""
echo "💵 BALANCE:"
echo "   $BALANCE BTC"
echo ""
echo "🔧 QUICK COMMANDS:"
echo "   Generate blocks:  bitcoin-cli $NET generatetoaddress 1 $MINER_ADDR"
echo "   Check balance:    bitcoin-cli $NET -rpcwallet=qs getbalance"
echo "   List UTXOs:       bitcoin-cli $NET -rpcwallet=qs listunspent"
echo "   Test spend:       ./spend.sh (use regtest mode)"
echo ""
echo "📝 DESCRIPTOR:"
echo "   ${FULL_DESC:0:60}..."
echo "   Checksum: $CHECKSUM"
echo ""

