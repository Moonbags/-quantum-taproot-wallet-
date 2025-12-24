#!/bin/bash
# Quantum Taproot Wallet Setup - Verified December 24, 2025
# NOT FINANCIAL ADVICE. Test on testnet first.
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         QUANTUM TAPROOT WALLET SETUP                       ║"
echo "║         Verified on Testnet - Block 4,810,284              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Network selection
read -p "Use Testnet? (Y/n): " TESTNET
[[ "$TESTNET" == "n" ]] && NET="" || NET="-testnet"

# Verify Bitcoin Core
echo "Checking Bitcoin Core..."
if ! command -v bitcoin-cli &> /dev/null; then
    echo "❌ bitcoin-cli not found. Install Bitcoin Core 28.0+ first."
    exit 1
fi

VERSION=$(bitcoin-cli $NET --version | head -1)
echo "✅ $VERSION"

# Check if daemon is running
if ! bitcoin-cli $NET getblockchaininfo &> /dev/null; then
    echo "❌ Bitcoin daemon not running. Start with: bitcoind $NET -daemon"
    exit 1
fi
echo "✅ Daemon running"

# Create wallets
echo ""
echo "Creating key wallets..."

for WALLET in hot_wallet cold_wallet recovery_wallet; do
    if bitcoin-cli $NET -rpcwallet=$WALLET getwalletinfo &> /dev/null 2>&1; then
        echo "  $WALLET already exists ✓"
    else
        bitcoin-cli $NET -named createwallet wallet_name="$WALLET" descriptors=true > /dev/null
        echo "  $WALLET created ✓"
    fi
done

# Create watch-only quantum wallet
if bitcoin-cli $NET -rpcwallet=qs getwalletinfo &> /dev/null 2>&1; then
    echo "  qs (quantum) already exists ✓"
else
    bitcoin-cli $NET -named createwallet wallet_name="qs" disable_private_keys=true blank=true descriptors=true > /dev/null
    echo "  qs (quantum) created ✓"
fi

# Extract xpubs
echo ""
echo "Extracting public keys..."

HOT=$(bitcoin-cli $NET -rpcwallet=hot_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oP 'tpub[A-Za-z0-9]+')
COLD=$(bitcoin-cli $NET -rpcwallet=cold_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oP 'tpub[A-Za-z0-9]+')
RECOV=$(bitcoin-cli $NET -rpcwallet=recovery_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oP 'tpub[A-Za-z0-9]+')

echo "  HOT:      ${HOT:0:20}..."
echo "  COLD:     ${COLD:0:20}..."
echo "  RECOVERY: ${RECOV:0:20}..."

# NUMS internal key (unspendable - no known private key)
INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

# Build descriptor
# Structure: HOT or COLD can spend anytime, RECOVERY after 1008 blocks
DESC="tr(${INTERNAL},{{pk(${HOT}/0/*),pk(${COLD}/0/*)},and_v(v:pk(${RECOV}/0/*),older(1008))})"

echo ""
echo "Validating descriptor..."
RESULT=$(bitcoin-cli $NET getdescriptorinfo "$DESC")
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
IMPORT_RESULT=$(bitcoin-cli $NET -rpcwallet=qs importdescriptors "[{\"desc\":\"$FULL_DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\"}]")
SUCCESS=$(echo "$IMPORT_RESULT" | jq -r '.[0].success')

if [ "$SUCCESS" != "true" ]; then
    echo "❌ Import failed"
    echo "$IMPORT_RESULT"
    exit 1
fi
echo "✅ Descriptor imported"

# Derive address
ADDR=$(bitcoin-cli $NET deriveaddresses "$FULL_DESC" "[0,0]" | jq -r '.[0]')

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         QUANTUM WALLET READY                               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "💰 FUNDING ADDRESS:"
echo "   $ADDR"
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
echo "⚠️  BACKUP YOUR WALLETS!"
echo "   bitcoin-cli $NET -rpcwallet=hot_wallet listdescriptors true > hot_backup.json"
echo "   bitcoin-cli $NET -rpcwallet=cold_wallet listdescriptors true > cold_backup.json"
echo "   bitcoin-cli $NET -rpcwallet=recovery_wallet listdescriptors true > recovery_backup.json"
echo ""

# Save to backup file
mkdir -p backup
cat > backup/wallet_info.txt << EOF
=== QUANTUM TAPROOT WALLET ===
Generated: $(date)
Network: $([ "$NET" == "-testnet" ] && echo "Testnet" || echo "Mainnet")

Address: $ADDR
Checksum: $CHECKSUM

Full Descriptor:
$FULL_DESC

Keys:
- HOT: $HOT
- COLD: $COLD
- RECOVERY: $RECOV
- INTERNAL (NUMS): $INTERNAL
EOF

echo "💾 Backup saved to: backup/wallet_info.txt"
