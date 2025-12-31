#!/bin/bash
# Copyright (c) 2025 Moonbags
# Distributed under the MIT software license, see the accompanying
# file LICENSE or http://www.opensource.org/licenses/mit-license.php.
# Fix testnet sync issues
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         FIXING TESTNET SYNC                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

NET="-testnet"

# Check if daemon is running
if ! bitcoin-cli "$NET" getblockchaininfo &> /dev/null; then
    echo "❌ Testnet daemon not running!"
    echo "   Start it with: bitcoind -testnet -daemon -txindex"
    exit 1
fi

echo "✅ Daemon is running"
echo ""

# Check current status
BLOCKS=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.blocks')
HEADERS=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.headers')
CONNECTIONS=$(bitcoin-cli "$NET" getnetworkinfo | jq -r '.connections')

echo "Current status:"
echo "  Blocks: $BLOCKS"
echo "  Headers: $HEADERS"
echo "  Connections: $CONNECTIONS"
echo ""

# Add more seed nodes
echo "Adding testnet seed nodes..."
bitcoin-cli "$NET" addnode "testnet-seed.bitcoin.sprovoost.nl" "onetry" > /dev/null 2>&1
bitcoin-cli "$NET" addnode "seed.tbtc.petertodd.org" "onetry" > /dev/null 2>&1
bitcoin-cli "$NET" addnode "testnet-seed.bluematt.me" "onetry" > /dev/null 2>&1
echo "✅ Seed nodes added"
echo ""

# Check if we need to clear ban list
echo "Checking for banned peers..."
BANNED=$(bitcoin-cli "$NET" listbanned | jq 'length')
if [ "$BANNED" -gt 0 ]; then
    echo "  Found $BANNED banned peers, clearing..."
    bitcoin-cli "$NET" setban "" "remove" > /dev/null 2>&1 || true
    echo "✅ Banned peers cleared"
else
    echo "✅ No banned peers"
fi
echo ""

# Force reconnection
echo "Forcing peer reconnection..."
bitcoin-cli "$NET" setnetworkactive false > /dev/null 2>&1
sleep 2
bitcoin-cli "$NET" setnetworkactive true > /dev/null 2>&1
echo "✅ Network restarted"
echo ""

# Wait a moment and check again
sleep 3
NEW_CONNECTIONS=$(bitcoin-cli "$NET" getnetworkinfo | jq -r '.connections')
NEW_BLOCKS=$(bitcoin-cli "$NET" getblockchaininfo | jq -r '.blocks')

echo "After fixes:"
echo "  Connections: $NEW_CONNECTIONS"
echo "  Blocks: $NEW_BLOCKS"
echo ""

if [ "$NEW_BLOCKS" -gt "$BLOCKS" ]; then
    echo "✅ Sync is progressing! Blocks increased from $BLOCKS to $NEW_BLOCKS"
else
    echo "⚠️  Still at block $NEW_BLOCKS"
    echo ""
    echo "If sync still isn't working, try:"
    echo "  1. Restart the daemon:"
    echo "     bitcoin-cli -testnet stop"
    echo "     bitcoind -testnet -daemon -txindex"
    echo ""
    echo "  2. Check your firewall/network settings"
    echo ""
    echo "  3. Check disk space:"
    echo "     df -h ~/.bitcoin/testnet3/"
    echo ""
    echo "  4. Check logs for errors:"
    echo "     tail -f ~/.bitcoin/testnet3/debug.log"
fi

echo ""


