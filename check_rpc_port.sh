#!/bin/bash
# Copyright (c) 2025 Moonbags
# Distributed under the MIT software license, see the accompanying
# file LICENSE or http://www.opensource.org/licenses/mit-license.php.
# Check RPC port configuration for testnet
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         TESTNET RPC PORT CHECK                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Default testnet RPC port
DEFAULT_TESTNET_RPC=18332

echo "Default testnet RPC port: $DEFAULT_TESTNET_RPC"
echo ""

# Check if daemon is running on default port
if bitcoin-cli -testnet getblockchaininfo &> /dev/null; then
    echo "✅ Daemon is accessible on default port ($DEFAULT_TESTNET_RPC)"
    echo ""
    echo "Test connection:"
    bitcoin-cli -testnet getblockchaininfo | jq '{chain, blocks, headers}' 2>/dev/null || echo "Connection failed"
else
    echo "❌ Cannot connect on default port"
    echo ""
    echo "Trying alternative ports..."
    
    # Try common alternative ports
    for PORT in 18332 18333 8332; do
        if bitcoin-cli -testnet -rpcport=$PORT getblockchaininfo &> /dev/null; then
            echo "✅ Found daemon on port $PORT"
            break
        fi
    done
fi

echo ""
echo "To specify a custom RPC port, use:"
echo "  bitcoin-cli -testnet -rpcport=YOUR_PORT <command>"
echo ""
echo "Or add to ~/.bitcoin/bitcoin.conf:"
echo "  [test]"
echo "  rpcport=18332"
echo "  rpcuser=your_username"
echo "  rpcpassword=your_password"
echo ""

