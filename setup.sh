#!/bin/bash
set -euo pipefail

# NUMS internal key — no private key known, forces script-path forever
INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

echo "Replace these xpubs with your real ones (include master fingerprints)"
read -p "Hot xpub (m/86'/1'/0'/0/0): " HOT
read -p "Cold xpub (m/86'/1'/0'/0/1): " COLD
read -p "Recovery xpub (m/86'/1'/0'/1/0): " RECOV

# Base descriptor: tr(internal_key, {or_d(pk_h(hot), pk_h(cold), and_v(pk_h(recov), older(1008))})
BASE_DESC="tr($INTERNAL,{or_d(pk_h($HOT),pk_h($COLD),and_v(v:pk_h($RECOV),older(1008)))})"

CHECKSUM=$(bitcoin-cli getdescriptorinfo "$BASE_DESC" | jq -r '.checksum')
DESC="${BASE_DESC}#${CHECKSUM}"

echo "✅ Final Descriptor: $DESC"

# Create & import wallet
bitcoin-cli createwallet "qs" true true false true false
bitcoin-cli -rpcwallet=qs -named importdescriptors \
  "[{\"desc\":\"$DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\",\"internal\":false}]"

# Generate first address
ADDR=$(bitcoin-cli -rpcwallet=qs -named deriveaddresses \
  descriptor="$DESC" range="[0,0]" | jq -r '.[0]')

echo "💰 Fund this Signet address: $ADDR"
echo "📋 Save this descriptor: $DESC"
echo "🌐 Use https://signetfaucet.com or https://hoodscan.com/faucet"
