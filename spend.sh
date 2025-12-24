#!/bin/bash
# Quantum Taproot Wallet - Spend Script
# Creates and signs PSBT to move funds from source to quantum address
set -euo pipefail

echo "=== QUANTUM TAPROOT SPEND ==="

# Configuration
QUANTUM_ADDR="tb1pmtcn2fl9f0sd24q22fhv0cardxwmnh9fm244m9yw04tcna2xqj0q2gjnld"
SOURCE_WALLET="quantumtest"
HOT_WALLET="hot_wallet"
COLD_WALLET="cold_wallet"

# Get network flag
read -p "Testnet? (y/N): " TESTNET
[[ "$TESTNET" == "y" ]] && NET="-testnet" || NET=""

# Check for UTXOs
echo "Checking UTXOs..."
UTXOS=$(bitcoin-cli $NET -rpcwallet=$SOURCE_WALLET listunspent)
if [ "$UTXOS" == "[]" ]; then
    echo "No UTXOs found. Node may still be syncing."
    echo "Check sync: bitcoin-cli $NET getblockchaininfo | jq '.blocks, .headers'"
    exit 1
fi

echo "Available UTXOs:"
echo "$UTXOS" | jq '.[] | {txid, vout, amount}'

# Get amount to send
BALANCE=$(echo "$UTXOS" | jq '[.[].amount] | add')
FEE=0.00001000
SEND_AMT=$(echo "$BALANCE - $FEE" | bc)

echo ""
echo "Balance: $BALANCE BTC"
echo "Fee: $FEE BTC"
echo "Sending: $SEND_AMT BTC"
echo "To: $QUANTUM_ADDR"
echo ""
read -p "Continue? (y/N): " CONFIRM
[[ "$CONFIRM" != "y" ]] && exit 0

# Create PSBT
echo "Creating PSBT..."
PSBT=$(bitcoin-cli $NET -rpcwallet=$SOURCE_WALLET walletcreatefundedpsbt \
    '[]' \
    "[{\"$QUANTUM_ADDR\": $SEND_AMT}]" \
    0 \
    '{"fee_rate": 1}' | jq -r '.psbt')

echo "PSBT created: ${PSBT:0:50}..."

# Sign with source wallet
echo "Signing with $SOURCE_WALLET..."
SIGNED1=$(bitcoin-cli $NET -rpcwallet=$SOURCE_WALLET walletprocesspsbt "$PSBT" | jq -r '.psbt')

# Analyze
echo "Analyzing PSBT..."
bitcoin-cli $NET analyzepsbt "$SIGNED1" | jq '{complete, fee}'

# Check if complete
COMPLETE=$(bitcoin-cli $NET analyzepsbt "$SIGNED1" | jq -r '.complete')
if [ "$COMPLETE" == "true" ]; then
    echo "✅ PSBT fully signed!"
    read -p "Broadcast transaction? (y/N): " BROADCAST
    if [ "$BROADCAST" == "y" ]; then
        RAWTX=$(bitcoin-cli $NET finalizepsbt "$SIGNED1" | jq -r '.hex')
        TXID=$(bitcoin-cli $NET sendrawtransaction "$RAWTX")
        echo "✅ Transaction broadcast!"
        echo "TXID: $TXID"
        echo "View: https://mempool.space/testnet/tx/$TXID"
    fi
else
    echo "PSBT needs more signatures. Saving to file..."
    echo "$SIGNED1" > psbt_partial.txt
    echo "Saved to psbt_partial.txt"
fi
