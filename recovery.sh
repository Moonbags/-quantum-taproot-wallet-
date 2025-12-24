#!/bin/bash
# Recovery Spend - Uses time-locked recovery key after 1008 blocks (~1 week)
set -euo pipefail

echo "=== RECOVERY SPEND (TIME-LOCKED) ==="
echo "⚠️  This only works after 1008 blocks (~1 week) from funding!"
echo ""

# Configuration
RECOVERY_WALLET="recovery_wallet"
DEST_ADDR=${1:-""}

read -p "Testnet? (y/N): " TESTNET
[[ "$TESTNET" == "y" ]] && NET="-testnet" || NET=""

if [ -z "$DEST_ADDR" ]; then
    read -p "Destination address: " DEST_ADDR
fi

# Get quantum wallet UTXOs
echo "Checking quantum wallet UTXOs..."
UTXOS=$(bitcoin-cli $NET -rpcwallet=qs listunspent)

if [ "$UTXOS" == "[]" ]; then
    echo "No UTXOs in quantum wallet."
    exit 1
fi

echo "Available UTXOs:"
echo "$UTXOS" | jq '.[] | {txid, vout, amount, confirmations}'

# Check if timelock is satisfied (1008 confirmations)
MIN_CONF=$(echo "$UTXOS" | jq '[.[].confirmations] | min')
if [ "$MIN_CONF" -lt 1008 ]; then
    echo "⏳ Timelock not yet satisfied!"
    echo "   Current confirmations: $MIN_CONF"
    echo "   Required: 1008"
    echo "   Blocks remaining: $((1008 - MIN_CONF))"
    echo ""
    echo "Recovery will be available in ~$((1008 - MIN_CONF)) blocks (~$(( (1008 - MIN_CONF) * 10 / 60 )) hours)"
    exit 1
fi

echo "✅ Timelock satisfied ($MIN_CONF confirmations)"

# Create recovery PSBT
BALANCE=$(echo "$UTXOS" | jq '[.[].amount] | add')
FEE=0.00001000
SEND_AMT=$(echo "$BALANCE - $FEE" | bc)

echo "Recovering: $SEND_AMT BTC"
echo "To: $DEST_ADDR"
read -p "Continue? (y/N): " CONFIRM
[[ "$CONFIRM" != "y" ]] && exit 0

# Create PSBT from quantum wallet
PSBT=$(bitcoin-cli $NET -rpcwallet=qs walletcreatefundedpsbt \
    '[]' \
    "[{\"$DEST_ADDR\": $SEND_AMT}]" \
    0 \
    '{"fee_rate": 1}' | jq -r '.psbt')

# Sign with recovery wallet
echo "Signing with recovery key..."
SIGNED=$(bitcoin-cli $NET -rpcwallet=$RECOVERY_WALLET walletprocesspsbt "$PSBT" | jq -r '.psbt')

# Finalize and broadcast
COMPLETE=$(bitcoin-cli $NET analyzepsbt "$SIGNED" | jq -r '.complete')
if [ "$COMPLETE" == "true" ]; then
    RAWTX=$(bitcoin-cli $NET finalizepsbt "$SIGNED" | jq -r '.hex')
    TXID=$(bitcoin-cli $NET sendrawtransaction "$RAWTX")
    echo "✅ Recovery transaction broadcast!"
    echo "TXID: $TXID"
else
    echo "❌ Could not complete PSBT. Check key availability."
    bitcoin-cli $NET analyzepsbt "$SIGNED"
fi
