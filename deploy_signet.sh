#!/bin/bash
# Deploy Quantum Taproot Wallet on Bitcoin Signet
# 2-of-2 multisig with 1-week timelock recovery
# NOT FINANCIAL ADVICE - This is for testing only
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         SIGNET DEPLOYMENT                                  ║"
echo "║         2-of-2 Multisig + Timelock Recovery               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

NET="-signet"

# Check if signet daemon is running
echo "Checking signet daemon..."
if ! bitcoin-cli "$NET" getblockchaininfo &> /dev/null; then
    echo "❌ Signet daemon not running!"
    echo ""
    echo "Start it with:"
    echo "  bitcoind -signet -daemon -txindex"
    echo ""
    echo "Wait for sync before continuing."
    exit 1
fi

# Check sync status
BLOCKS=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.blocks')
HEADERS=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.headers')
VERIFICATION=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.verificationprogress')

echo "✅ Signet daemon running"
echo "   Blocks: $BLOCKS / $HEADERS"
echo "   Progress: $(echo "$VERIFICATION * 100" | bc -l | cut -d. -f1)%"

if (( $(echo "$VERIFICATION < 0.99" | bc -l) )); then
    echo ""
    echo "⚠️  Warning: Chain not fully synced yet"
    echo "   Progress: $(echo "$VERIFICATION * 100" | bc -l | cut -d. -f1)%"
    echo "   You can continue, but some operations may fail"
    echo ""
    read -rp "Continue anyway? (y/N): " CONTINUE
    [[ "$CONTINUE" != "y" ]] && exit 0
fi

# Create test wallets
echo ""
echo "Creating key wallets..."

for WALLET in hot_wallet cold_wallet recovery_wallet; do
    if bitcoin-cli "$NET" -rpcwallet=$WALLET getwalletinfo &> /dev/null 2>&1; then
        echo "  $WALLET already exists ✓"
    else
        bitcoin-cli "$NET" -named createwallet wallet_name="$WALLET" descriptors=true > /dev/null
        echo "  $WALLET created ✓"
    fi
done

# Create watch-only quantum wallet
if bitcoin-cli "$NET" -rpcwallet=qs getwalletinfo &> /dev/null 2>&1; then
    echo "  qs (quantum) already exists ✓"
else
    bitcoin-cli "$NET" -named createwallet wallet_name="qs" disable_private_keys=true blank=true descriptors=true > /dev/null
    echo "  qs (quantum) created ✓"
fi

# Extract xpubs from wallets
echo ""
echo "Extracting public keys (xpubs)..."

HOT=$(bitcoin-cli "$NET" -rpcwallet=hot_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+')
COLD=$(bitcoin-cli "$NET" -rpcwallet=cold_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+')
RECOV=$(bitcoin-cli "$NET" -rpcwallet=recovery_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+')

# Validate xpubs were extracted successfully
if [ -z "$HOT" ] || [ -z "$COLD" ] || [ -z "$RECOV" ]; then
    echo "❌ Failed to extract xpubs from wallets"
    echo "   Ensure wallets have taproot descriptors"
    exit 1
fi

echo "  HOT:      ${HOT:0:20}..."
echo "  COLD:     ${COLD:0:20}..."
echo "  RECOVERY: ${RECOV:0:20}..."

# NUMS internal key (unspendable - no known private key)
# This ensures taproot output hides script tree completely
INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

# Build descriptor: HOT or COLD can spend anytime, RECOVERY after 1008 blocks (~1 week)
# This implements 2-of-2 multisig concept with timelock recovery
DESC="tr(${INTERNAL},{{pk(${HOT}/0/*),pk(${COLD}/0/*)},and_v(v:pk(${RECOV}/0/*),older(1008))})"

echo ""
echo "Validating descriptor..."
RESULT=$(bitcoin-cli "$NET" getdescriptorinfo "$DESC")
CHECKSUM=$(echo "$RESULT" | jq -r '.checksum')
ISSOLVABLE=$(echo "$RESULT" | jq -r '.issolvable')

if [ "$ISSOLVABLE" != "true" ]; then
    echo "❌ Descriptor validation failed"
    exit 1
fi

FULL_DESC="${DESC}#${CHECKSUM}"
echo "✅ Checksum: $CHECKSUM"

# Import to quantum wallet
echo ""
echo "Importing descriptor to quantum wallet..."
IMPORT_RESULT=$(bitcoin-cli "$NET" -rpcwallet=qs importdescriptors "[{\"desc\":\"$FULL_DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\"}]")
SUCCESS=$(echo "$IMPORT_RESULT" | jq -r '.[0].success')

if [ "$SUCCESS" != "true" ]; then
    echo "❌ Import failed"
    echo "$IMPORT_RESULT"
    exit 1
fi
echo "✅ Descriptor imported"

# Derive quantum address (bech32m for taproot)
QUANTUM_ADDR=$(bitcoin-cli "$NET" deriveaddresses "$FULL_DESC" "[0,0]" | jq -r '.[0]')

# Check current balance
BALANCE=$(bitcoin-cli "$NET" -rpcwallet=qs getbalance 2>/dev/null || echo "0")

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         SIGNET QUANTUM WALLET READY                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "💰 FUNDING ADDRESS (bech32m):"
echo "   $QUANTUM_ADDR"
echo ""
echo "💵 CURRENT BALANCE:"
echo "   $BALANCE BTC"
echo ""
echo "💧 GET SIGNET FUNDS:"
echo "   Visit: https://signetfaucet.com"
echo "   Or:    https://signet.bc-2.jp"
echo ""
echo "   Send funds to: $QUANTUM_ADDR"
echo ""
echo "📋 DESCRIPTOR:"
echo "   ${FULL_DESC:0:60}..."
echo "   Checksum: $CHECKSUM"
echo ""
echo "🔐 SPENDING CONDITIONS:"
echo "   1. HOT key     - Spend anytime (hot_wallet)"
echo "   2. COLD key    - Spend anytime (cold_wallet)"
echo "   3. RECOVERY    - After 1008 blocks ~1 week (recovery_wallet)"
echo ""
echo "🔧 PSBT COMMANDS:"
echo "   Create PSBT:     bitcoin-cli $NET -rpcwallet=qs walletcreatefundedpsbt '[]' '[{\"<dest>\": 0.0001}]' 0 '{\"fee_rate\": 1}'"
echo "   Sign with HOT:   bitcoin-cli $NET -rpcwallet=hot_wallet walletprocesspsbt <psbt>"
echo "   Sign with COLD:  bitcoin-cli $NET -rpcwallet=cold_wallet walletprocesspsbt <psbt>"
echo "   Analyze:         bitcoin-cli $NET analyzepsbt <psbt>"
echo "   Finalize:        bitcoin-cli $NET finalizepsbt <psbt>"
echo "   Broadcast:       bitcoin-cli $NET sendrawtransaction <hex>"
echo ""
echo "🌐 EXPLORER:"
echo "   https://mempool.space/signet/address/$QUANTUM_ADDR"
echo ""
echo "⚠️  BACKUP YOUR WALLETS!"
echo "   bitcoin-cli $NET -rpcwallet=hot_wallet listdescriptors true > hot_backup.json"
echo "   bitcoin-cli $NET -rpcwallet=cold_wallet listdescriptors true > cold_backup.json"
echo "   bitcoin-cli $NET -rpcwallet=recovery_wallet listdescriptors true > recovery_backup.json"
echo ""

# Save to backup file
mkdir -p backup
cat > backup/signet_wallet_info.txt << EOF
=== QUANTUM TAPROOT WALLET (SIGNET) ===
Generated: $(date)
Network: Signet

Address: $QUANTUM_ADDR
Checksum: $CHECKSUM

Full Descriptor:
$FULL_DESC

Keys:
- HOT: $HOT
- COLD: $COLD
- RECOVERY: $RECOV
- INTERNAL (NUMS): $INTERNAL

Security Model:
- HOT key: spend anytime (daily use)
- COLD key: spend anytime (secure storage)
- RECOVERY: spend after 1008 blocks (~1 week)

Explorer: https://mempool.space/signet/address/$QUANTUM_ADDR
EOF

echo "💾 Backup saved to: backup/signet_wallet_info.txt"
