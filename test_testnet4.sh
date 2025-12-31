#!/bin/bash
# Copyright (c) 2025 Moonbags
# Distributed under the MIT software license, see the accompanying
# file LICENSE or http://www.opensource.org/licenses/mit-license.php.
# TESTNET4 - Adversarial spam testing (final pre-mainnet)
# Most realistic testnet environment
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         TESTNET4 - ADVERSARIAL SPAM TESTING               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

NET="-testnet4"

# Check if testnet4 daemon is running
if ! bitcoin-cli "$NET" getblockchaininfo &> /dev/null; then
    echo "⚠️  Testnet4 daemon not running. Starting..."
    echo "   Run: bitcoind -testnet4 -daemon -txindex"
    exit 1
fi

echo "✅ Testnet4 daemon running"

# Check sync status
BLOCKS=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.blocks')
HEADERS=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.headers')
if [ "$BLOCKS" -lt "$HEADERS" ]; then
    echo "⏳ Syncing... ($BLOCKS/$HEADERS blocks)"
    echo "   Wait for sync to complete"
fi

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

HOT=$(bitcoin-cli "$NET" -rpcwallet=hot_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+')
COLD=$(bitcoin-cli "$NET" -rpcwallet=cold_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+')
RECOV=$(bitcoin-cli "$NET" -rpcwallet=recovery_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+')

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

# Check balance
BALANCE=$(bitcoin-cli "$NET" -rpcwallet=qs getbalance 2>/dev/null || echo "0")

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         TESTNET4 WALLET READY                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "💰 QUANTUM ADDRESS:"
echo "   $QUANTUM_ADDR"
echo ""
echo "💵 BALANCE:"
echo "   $BALANCE BTC"
echo ""
echo "💧 GET FUNDS:"
echo "   Visit: https://faucet.testnet4.dev"
echo "   Or:    https://testnet4.bitcoindevkit.org/faucet"
echo ""
echo "   Send funds to: $QUANTUM_ADDR"
echo ""
echo "🔧 ADVERSARIAL TESTING:"
echo "   Spam transactions: Create many small transactions"
echo "   Mempool pressure:  Test with high fee rates"
echo "   Timelock edge:     Test recovery at exactly 1008 blocks"
echo "   PSBT finalization: Test multi-signature flows"
echo ""
echo "📝 DESCRIPTOR:"
echo "   ${FULL_DESC:0:60}..."
echo "   Checksum: $CHECKSUM"
echo ""
echo "🌐 EXPLORER:"
echo "   https://mempool.space/testnet4/address/$QUANTUM_ADDR"
echo ""

