#!/bin/bash
# Quantum Taproot Wallet Setup - NOT FINANCIAL ADVICE. Testnet first.
set -euo pipefail  # Exit on error, undefined vars

INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

echo "=== Replace these xpubs ==="
read -p "Hot xpub (m/86'/1'/0'/0/0): " HOT
read -p "Cold xpub (m/86'/1'/0'/0/1): " COLD  
read -p "Recovery xpub (m/86'/1'/0'/1/0): " RECOV
read -p "Testnet? (y/N): " TESTNET

[[ "$TESTNET" == "y" ]] && EXTRA="--testnet" || EXTRA=""

BASE_DESC="tr(${INTERNAL},{or_d(pk_h(${HOT}),pk_h(${COLD}),and_v(v:pk_h(${RECOV}),older(1008)))})"

echo "Validating descriptor..."
bitcoin-cli $EXTRA getdescriptorinfo "$BASE_DESC" || { echo "Invalid descriptor"; exit 1; }

CHECKSUM=$(bitcoin-cli $EXTRA getdescriptorinfo "$BASE_DESC" | jq -r '.checksum')
DESC="${BASE_DESC}#${CHECKSUM}"

echo "✅ Descriptor: $DESC"

bitcoin-cli $EXTRA createwallet "qs" true true false true false
bitcoin-cli $EXTRA -rpcwallet=qs -named importdescriptors "[{\"desc\":\"$DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\",\"internal\":false}]"

ADDR=$(bitcoin-cli $EXTRA -rpcwallet=qs -named deriveaddresses descriptor="$DESC" range="[0,0]" | jq -r '.[0]')
echo "💰 Fund this address: $ADDR"
echo "📋 Save descriptor: $DESC"
