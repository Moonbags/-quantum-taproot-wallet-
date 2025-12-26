#!/bin/bash
# PUBLIC SIGNET - Stable PSBT finalization testing
# Uses public signet network for realistic testing
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         PUBLIC SIGNET - STABLE PSBT TESTING               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

NET="-signet"

# Check if signet daemon is running
if ! bitcoin-cli "$NET" getblockchaininfo &> /dev/null; then
    echo "⚠️  Signet daemon not running. Starting..."
    echo "   Run: bitcoind -signet -daemon -txindex"
    exit 1
fi

echo "✅ Signet daemon running"

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

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         PUBLIC SIGNET WALLET READY                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "💰 QUANTUM ADDRESS:"
echo "   $QUANTUM_ADDR"
echo ""
echo "💧 GET FUNDS:"
echo "   Visit: https://signetfaucet.com"
echo "   Or:    https://signet.bc-2.jp"
echo ""
echo "   Send funds to: $QUANTUM_ADDR"
echo ""
echo "🔧 PSBT TESTING:"
echo "   Create PSBT:     bitcoin-cli $NET -rpcwallet=qs walletcreatefundedpsbt ..."
echo "   Fund PSBT:       bitcoin-cli $NET fundrawtransaction <hex> | jq .hex"
echo "   Finalize PSBT:   bitcoin-cli $NET finalizepsbt <psbt>"
echo "   Broadcast:       bitcoin-cli $NET sendrawtransaction <hex>"
echo ""
echo "📝 DESCRIPTOR:"
echo "   ${FULL_DESC:0:60}..."
echo "   Checksum: $CHECKSUM"
echo ""
echo "🌐 EXPLORER:"
echo "   https://mempool.space/signet/address/$QUANTUM_ADDR"
echo ""

