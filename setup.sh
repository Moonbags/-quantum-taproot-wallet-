#!/bin/bash
# Quantum Taproot Wallet Setup - forces script-path spends via NUMS internal key.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
NUMS_INTERNAL_KEY="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }
}

need_cmd bitcoin-cli
need_cmd jq
need_cmd node

echo "=== Quantum Taproot Wallet (NUMS internal key disables key-path) ==="
read -rp "Hot xpub (m/86'/{net}'/0'/0/0): " HOT
read -rp "Cold xpub (m/86'/{net}'/0'/0/1): " COLD
read -rp "Recovery xpub (m/86'/{net}'/0'/1/0): " RECOV
read -rp "Network [signet/testnet/mainnet] (default: signet): " NET

NET=${NET:-signet}
case "$NET" in
  signet) EXTRA="--signet" ;;
  testnet) EXTRA="--testnet" ;;
  mainnet|"") EXTRA="" ;;
  *) echo "Unsupported network: $NET"; exit 1 ;;
esac

DESC=$(node "$ROOT/src/descriptors.js" --hot "$HOT" --cold "$COLD" --recovery "$RECOV" --network "$NET" --range "[0,999]" --with-checksum)

if [[ -z "$DESC" ]]; then
  echo "Descriptor generation failed"
  exit 1
fi

echo "✅ Descriptor (script-path only): $DESC"

WALLET="qs-${NET}"
bitcoin-cli $EXTRA createwallet "$WALLET" true true false true false >/dev/null || true

IMPORT_JSON=$(cat <<EOF
[{
  "desc": "$DESC",
  "active": true,
  "range": [0,999],
  "timestamp": "now",
  "internal": false
}]
EOF
)

bitcoin-cli $EXTRA -rpcwallet="$WALLET" importdescriptors "$IMPORT_JSON" >/dev/null

ADDR=$(bitcoin-cli $EXTRA -rpcwallet="$WALLET" deriveaddresses "$DESC" "[0,0]" | jq -r '.[0]')
echo "💰 Fund this address: $ADDR"
echo "📋 Save descriptor: $DESC"
echo "⏳ Recovery path: older(1008) with recovery key"
