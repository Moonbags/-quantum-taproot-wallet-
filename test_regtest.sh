#!/bin/bash
# REGTEST - Isolated script iteration for rapid development
# Fastest way to test quantum taproot wallet changes
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         REGTEST - ISOLATED TESTING                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

NET="-regtest"
RPC_PORT=18443

# Check if regtest daemon is running
if ! bitcoin-cli "$NET" getblockchaininfo &> /dev/null; then
    echo "⚠️  Regtest daemon not running. Starting..."
    echo "   Run: bitcoind -regtest -daemon -txindex"
    echo "   Or: bitcoind -regtest -daemon -txindex -rpcport=$RPC_PORT"
    exit 1
fi

echo "✅ Regtest daemon running"

# Create test wallets
echo ""
echo "Creating test wallets..."

for WALLET in hot_wallet cold_wallet recovery_wallet; do
    if bitcoin-cli "$NET" -rpcwallet=$WALLET getwalletinfo &> /dev/null 2>&1; then
        echo "  $WALLET exists ✓"
    else
        bitcoin-cli "$NET" -named createwallet wallet_name="$WALLET" descriptors=true > /dev/null
        echo "  $WALLET created ✓"
    fi
done

# Create watch-only quantum wallet
if bitcoin-cli "$NET" -rpcwallet=qs getwalletinfo &> /dev/null 2>&1; then
    echo "  qs (quantum) exists ✓"
else
    bitcoin-cli "$NET" -named createwallet wallet_name="qs" disable_private_keys=true blank=true descriptors=true > /dev/null
    echo "  qs (quantum) created ✓"
fi

# Extract xpubs
echo ""
echo "Extracting public keys..."

HOT=$(bitcoin-cli "$NET" -rpcwallet=hot_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | sed -E 's/.*](tpub[^/]+).*/\1/')
COLD=$(bitcoin-cli "$NET" -rpcwallet=cold_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | sed -E 's/.*](tpub[^/]+).*/\1/')
RECOV=$(bitcoin-cli "$NET" -rpcwallet=recovery_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | sed -E 's/.*](tpub[^/]+).*/\1/')

echo "  HOT:      ${HOT:0:20}..."
echo "  COLD:     ${COLD:0:20}..."
echo "  RECOVERY: ${RECOV:0:20}..."

# NUMS internal key
INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

# Build descriptor
DESC="tr(${INTERNAL},{{pk(${HOT}/0/*),pk(${COLD}/0/*)},and_v(v:pk(${RECOV}/0/*),older(1008))})"

echo ""
echo "Validating descriptor..."
RESULT=$(bitcoin-cli "$NET" getdescriptorinfo "$DESC")
CHECKSUM=$(echo "$RESULT" | jq -r '.checksum')
FULL_DESC="${DESC}#${CHECKSUM}"

# Import to quantum wallet
echo "Importing descriptor..."
bitcoin-cli "$NET" -rpcwallet=qs importdescriptors "[{\"desc\":\"$FULL_DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\"}]" > /dev/null

# Derive quantum address
QUANTUM_ADDR=$(bitcoin-cli "$NET" deriveaddresses "$FULL_DESC" "[0,0]" | jq -r '.[0]')

# Generate blocks to get some coins
echo ""
echo "Generating initial blocks..."
MINER_ADDR=$(bitcoin-cli "$NET" -rpcwallet=hot_wallet getnewaddress)
bitcoin-cli "$NET" generatetoaddress 101 "$MINER_ADDR" > /dev/null
echo "✅ 101 blocks generated (mature coinbase)"

# Generate a few more blocks for fee estimation
bitcoin-cli "$NET" generatetoaddress 5 "$MINER_ADDR" > /dev/null

# Fund quantum address
echo ""
echo "Funding quantum address..."
CURRENT_BALANCE=$(bitcoin-cli "$NET" -rpcwallet=qs getbalance 2>/dev/null || echo "0")
if (( $(echo "$CURRENT_BALANCE > 0" | bc -l) )); then
    echo "✅ Quantum wallet already funded ($CURRENT_BALANCE BTC)"
else
    FUND_AMT=0.00099
    FEE_AMT=0.00001
    # Get UTXO details
    UTXO_DATA=$(bitcoin-cli "$NET" -rpcwallet=hot_wallet listunspent | jq -r '.[0]')
    if [ -n "$UTXO_DATA" ] && [ "$UTXO_DATA" != "null" ]; then
        TXID_UTXO=$(echo "$UTXO_DATA" | jq -r '.txid')
        VOUT_UTXO=$(echo "$UTXO_DATA" | jq -r '.vout')
        UTXO_AMT=$(echo "$UTXO_DATA" | jq -r '.amount')
        CHANGE_AMT=$(echo "$UTXO_AMT - $FUND_AMT - $FEE_AMT" | bc)
        CHANGE_ADDR=$(bitcoin-cli "$NET" -rpcwallet=hot_wallet getnewaddress)
        
        # Create transaction with explicit inputs, outputs, and change
        if (( $(echo "$CHANGE_AMT > 0" | bc -l) )); then
            RAW=$(bitcoin-cli "$NET" createrawtransaction \
                "[{\"txid\":\"$TXID_UTXO\",\"vout\":$VOUT_UTXO}]" \
                "[{\"$QUANTUM_ADDR\":$FUND_AMT},{\"$CHANGE_ADDR\":$CHANGE_AMT}]")
        else
            # No change, send everything minus fee
            SEND_AMT=$(echo "$UTXO_AMT - $FEE_AMT" | bc)
            RAW=$(bitcoin-cli "$NET" createrawtransaction \
                "[{\"txid\":\"$TXID_UTXO\",\"vout\":$VOUT_UTXO}]" \
                "[{\"$QUANTUM_ADDR\":$SEND_AMT}]")
        fi
        
        SIGNED=$(bitcoin-cli "$NET" -rpcwallet=hot_wallet signrawtransactionwithwallet "$RAW" | jq -r '.hex')
        TXID=$(bitcoin-cli "$NET" sendrawtransaction "$SIGNED")
        bitcoin-cli "$NET" generatetoaddress 1 "$MINER_ADDR" > /dev/null
        echo "✅ Funded to quantum address (TX: ${TXID:0:16}...)"
    else
        echo "⚠️  No UTXOs available for funding"
    fi
fi

# Check balance
BALANCE=$(bitcoin-cli "$NET" -rpcwallet=qs getbalance)
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         REGTEST WALLET READY                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "💰 QUANTUM ADDRESS:"
echo "   $QUANTUM_ADDR"
echo ""
echo "💵 BALANCE:"
echo "   $BALANCE BTC"
echo ""
echo "🔧 QUICK COMMANDS:"
echo "   Generate blocks:  bitcoin-cli $NET generatetoaddress 1 $MINER_ADDR"
echo "   Check balance:    bitcoin-cli $NET -rpcwallet=qs getbalance"
echo "   List UTXOs:       bitcoin-cli $NET -rpcwallet=qs listunspent"
echo "   Test spend:       ./spend.sh (use regtest mode)"
echo ""
echo "📝 DESCRIPTOR:"
echo "   ${FULL_DESC:0:60}..."
echo "   Checksum: $CHECKSUM"
echo ""

