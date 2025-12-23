#!/bin/bash
# Testnet Descriptor Test Suite for Signet
# Tests Taproot descriptors with post-quantum script paths

set -euo pipefail

echo "=== Quantum Taproot Wallet - Signet Test Suite ==="
echo ""

# Configuration
NETWORK="signet"
WALLET_NAME="quantum_test_$$"
INTERNAL_KEY="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

# Test keys (NEVER use in production)
HOT_KEY="02a5c7d8e9f0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7"
COLD_KEY="03b6d8e9f0a1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8"
RECOVERY_KEY="04c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8"
TIMELOCK_BLOCKS=144 # ~1 day on signet

echo "Test Configuration:"
echo "  Network: $NETWORK"
echo "  Wallet: $WALLET_NAME"
echo "  Timelock: $TIMELOCK_BLOCKS blocks"
echo ""

# Check if Bitcoin Core is available
if ! command -v bitcoin-cli &> /dev/null; then
    echo "❌ bitcoin-cli not found. Please install Bitcoin Core."
    exit 1
fi

echo "✓ Bitcoin Core found"

# Test 1: Simple Taproot descriptor
echo ""
echo "Test 1: Simple Taproot Descriptor"
echo "=================================="

SIMPLE_DESC="tr(${INTERNAL_KEY})"
echo "Descriptor: $SIMPLE_DESC"

if bitcoin-cli -signet getdescriptorinfo "$SIMPLE_DESC" > /dev/null 2>&1; then
    CHECKSUM=$(bitcoin-cli -signet getdescriptorinfo "$SIMPLE_DESC" | jq -r '.checksum')
    echo "✓ Valid descriptor with checksum: $CHECKSUM"
else
    echo "❌ Invalid descriptor"
    exit 1
fi

# Test 2: Taproot with single script path
echo ""
echo "Test 2: Taproot with Script Path"
echo "================================="

SCRIPT_DESC="tr(${INTERNAL_KEY},{pk(${HOT_KEY})})"
echo "Descriptor: $SCRIPT_DESC"

if bitcoin-cli -signet getdescriptorinfo "$SCRIPT_DESC" > /dev/null 2>&1; then
    CHECKSUM=$(bitcoin-cli -signet getdescriptorinfo "$SCRIPT_DESC" | jq -r '.checksum')
    echo "✓ Valid script path descriptor: $CHECKSUM"
else
    echo "❌ Invalid script descriptor"
    exit 1
fi

# Test 3: Multi-path descriptor (hot/cold/recovery)
echo ""
echo "Test 3: Multi-Path Descriptor (Hot/Cold/Recovery)"
echo "=================================================="

MULTI_DESC="tr(${INTERNAL_KEY},{pk(${HOT_KEY}),pk(${COLD_KEY}),and_v(v:pk(${RECOVERY_KEY}),older(${TIMELOCK_BLOCKS}))})"
echo "Descriptor: $MULTI_DESC"

if bitcoin-cli -signet getdescriptorinfo "$MULTI_DESC" > /dev/null 2>&1; then
    INFO=$(bitcoin-cli -signet getdescriptorinfo "$MULTI_DESC")
    CHECKSUM=$(echo "$INFO" | jq -r '.checksum')
    echo "✓ Valid multi-path descriptor"
    echo "  Checksum: $CHECKSUM"
    echo "$INFO" | jq '.'
else
    echo "❌ Invalid multi-path descriptor"
    exit 1
fi

# Test 4: Create and import descriptor wallet
echo ""
echo "Test 4: Wallet Creation and Import"
echo "==================================="

# Create watch-only wallet
if bitcoin-cli -signet createwallet "$WALLET_NAME" true true "" false false > /dev/null 2>&1; then
    echo "✓ Wallet created: $WALLET_NAME"
else
    echo "⚠ Wallet may already exist, continuing..."
fi

# Import descriptor
FINAL_DESC="${MULTI_DESC}#${CHECKSUM}"
IMPORT_JSON="[{\"desc\":\"${FINAL_DESC}\",\"active\":true,\"range\":[0,100],\"timestamp\":\"now\",\"internal\":false}]"

if bitcoin-cli -signet -rpcwallet="$WALLET_NAME" importdescriptors "$IMPORT_JSON" > /dev/null 2>&1; then
    echo "✓ Descriptor imported successfully"
else
    echo "❌ Failed to import descriptor"
    exit 1
fi

# Test 5: Derive addresses
echo ""
echo "Test 5: Address Derivation"
echo "==========================="

ADDR_RESULT=$(bitcoin-cli -signet -rpcwallet="$WALLET_NAME" -named deriveaddresses descriptor="$FINAL_DESC" range="[0,4]")
echo "Derived addresses:"
echo "$ADDR_RESULT" | jq -r '.[]' | nl

FIRST_ADDR=$(echo "$ADDR_RESULT" | jq -r '.[0]')
echo ""
echo "First address: $FIRST_ADDR"

# Validate address
if bitcoin-cli -signet validateaddress "$FIRST_ADDR" | jq -r '.isvalid' | grep -q "true"; then
    echo "✓ Address is valid"
    ADDR_INFO=$(bitcoin-cli -signet validateaddress "$FIRST_ADDR")
    echo "$ADDR_INFO" | jq '.'
else
    echo "❌ Invalid address"
    exit 1
fi

# Test 6: Check wallet info
echo ""
echo "Test 6: Wallet Information"
echo "=========================="

WALLET_INFO=$(bitcoin-cli -signet -rpcwallet="$WALLET_NAME" getwalletinfo)
echo "$WALLET_INFO" | jq '.'

echo ""
echo "✓ Wallet balance: $(echo "$WALLET_INFO" | jq -r '.balance') BTC"

# Test 7: Descriptor analysis
echo ""
echo "Test 7: Descriptor Analysis"
echo "============================"

DESC_INFO=$(bitcoin-cli -signet getdescriptorinfo "$MULTI_DESC")
echo "Descriptor analysis:"
echo "$DESC_INFO" | jq '.'

# Cleanup
echo ""
echo "Cleanup"
echo "======="

read -p "Unload test wallet? (y/N): " CLEANUP
if [[ "$CLEANUP" == "y" ]]; then
    bitcoin-cli -signet unloadwallet "$WALLET_NAME" > /dev/null 2>&1 && echo "✓ Wallet unloaded"
else
    echo "⚠ Wallet kept loaded: $WALLET_NAME"
    echo "  To fund: bitcoin-cli -signet -rpcwallet=$WALLET_NAME getnewaddress"
fi

echo ""
echo "=== Test Suite Complete ==="
echo "Summary:"
echo "  ✓ Descriptor validation"
echo "  ✓ Wallet creation"
echo "  ✓ Descriptor import"
echo "  ✓ Address derivation"
echo "  ✓ Address validation"
echo ""
echo "Next steps:"
echo "  1. Fund address: $FIRST_ADDR"
echo "  2. Use signet faucet: https://signetfaucet.com"
echo "  3. Monitor: bitcoin-cli -signet -rpcwallet=$WALLET_NAME listtransactions"
