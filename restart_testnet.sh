#!/bin/bash
# Restart testnet with proper configuration
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         RESTART TESTNET DAEMON                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Stop if running
if bitcoin-cli -testnet getblockchaininfo &> /dev/null; then
    echo "Stopping testnet daemon..."
    bitcoin-cli -testnet stop > /dev/null 2>&1 || true
    sleep 3
    echo "✅ Stopped"
fi

echo ""
echo "Starting testnet daemon with recommended settings..."
echo ""

# Start with proper flags
bitcoind -testnet \
    -daemon \
    -txindex \
    -maxconnections=32 \
    -dbcache=1000 \
    -peerbloomfilters=1

echo "✅ Testnet daemon started"
echo ""
echo "Waiting 5 seconds for initialization..."
sleep 5

# Check status
if bitcoin-cli -testnet getblockchaininfo &> /dev/null; then
    BLOCKS=$(bitcoin-cli -testnet getblockchaininfo | jq -r '.blocks')
    HEADERS=$(bitcoin-cli -testnet getblockchaininfo | jq -r '.headers')
    CONNECTIONS=$(bitcoin-cli -testnet getnetworkinfo | jq -r '.connections')
    
    echo "Status:"
    echo "  Blocks: $BLOCKS"
    echo "  Headers: $HEADERS"
    echo "  Connections: $CONNECTIONS"
    echo ""
    echo "Monitor sync progress with:"
    echo "  watch -n 5 'bitcoin-cli -testnet getblockchaininfo | jq \"{blocks, headers, verificationprogress}\"'"
    echo ""
    echo "Or check logs:"
    echo "  tail -f ~/.bitcoin/testnet3/debug.log | grep -i \"update tip\|progress\""
else
    echo "❌ Failed to start or connect to daemon"
    echo "Check logs: tail -f ~/.bitcoin/testnet3/debug.log"
fi


