#!/bin/bash
# Copyright (c) 2025 sha256sol (Moonbags). All rights reserved.
# Patent pending. Private repository. IP timestamp: 2025-12-31
# Deploy Quantum Taproot Wallet on Bitcoin Testnet
# NOT FINANCIAL ADVICE - This is for testing only
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         TESTNET DEPLOYMENT                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

NET="-testnet"

# Check if testnet daemon is running
echo "Checking testnet daemon..."
if ! bitcoin-cli "$NET" getblockchaininfo &> /dev/null; then
    echo "❌ Testnet daemon not running!"
    echo ""
    echo "Start it with:"
    echo "  bitcoind -testnet -daemon -txindex"
    echo ""
    echo "Or if you have a config file:"
    echo "  bitcoind -testnet -daemon"
    echo ""
    echo "Wait for sync before continuing."
    exit 1
fi

# Check sync status
BLOCKS=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.blocks')
HEADERS=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.headers')
VERIFICATION=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.verificationprogress')

echo "✅ Testnet daemon running"
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

echo ""
echo "Running quantum taproot wallet setup..."
echo ""

# Run the setup script with testnet
./setup.sh <<< "Y"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         TESTNET DEPLOYMENT COMPLETE                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📝 Next steps:"
echo "   1. Get testnet coins from a faucet:"
echo "      https://bitcoinfaucet.uo1.net"
echo "      https://testnet-faucet.mempool.co"
echo ""
echo "   2. Send coins to your quantum address (shown above)"
echo ""
echo "   3. Test spending with: ./spend.sh"
echo ""
echo "   4. Test recovery after 1008 blocks with: ./recovery.sh"
echo ""


