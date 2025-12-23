#!/bin/bash
# Quantum Taproot Wallet Setup - NOT FINANCIAL ADVICE. Testnet first.
set -euo pipefail  # Exit on error, undefined vars

INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

echo "=== Replace these xpubs ==="
read -p "Hot xpub (m/86'/1'/0'/0/*): " HOT
read -p "Cold xpub (m/86'/1'/0'/0/*): " COLD
read -p "Recovery xpub (m/86'/1'/0'/1/*): " RECOV
read -p "Testnet? (y/N): " TESTNET

[[ "$TESTNET" == "y" ]] && EXTRA="--testnet" || EXTRA=""

# 1-of-3 spending: hot or cold immediately, or recovery after 1008 blocks.
BASE_DESC="tr(${INTERNAL},thresh(1,pk(${HOT}),pk(${COLD}),and_v(v:pk(${RECOV}),older(1008))))"

echo "Validating descriptor..."
bitcoin-cli $EXTRA getdescriptorinfo "$BASE_DESC" || { echo "Invalid descriptor"; exit 1; }

CHECKSUM=$(bitcoin-cli $EXTRA getdescriptorinfo "$BASE_DESC" | jq -r '.checksum')
DESC="${BASE_DESC}#${CHECKSUM}"

echo "✅ Descriptor: $DESC"

bitcoin-cli $EXTRA -named createwallet wallet_name="qs" disable_private_keys=true blank=true passphrase="" avoid_reuse=true descriptors=true
bitcoin-cli $EXTRA -rpcwallet=qs -named importdescriptors "[{\"desc\":\"$DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\",\"internal\":false}]"

ADDR=$(bitcoin-cli $EXTRA -rpcwallet=qs -named deriveaddresses descriptor="$DESC" range="[0,0]" | jq -r '.[0]')
echo "💰 Fund this address: $ADDR"
echo "📋 Save descriptor: $DESC"
