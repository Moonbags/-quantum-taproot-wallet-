#!/bin/bash
# CUSTOM SIGNET - Edge case testing with custom signet
# Requires: docker run -it --name custom-signet -p 38332:38332 nbd-wtf/signet:custom
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         CUSTOM SIGNET - EDGE CASE TESTING                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if custom signet docker is running
if ! docker ps | grep -q custom-signet; then
    echo "⚠️  Custom signet docker not running!"
    echo ""
    echo "Start it with:"
    echo "  docker run -it --name custom-signet -p 38332:38332 nbd-wtf/signet:custom"
    echo ""
    echo "Or if already created:"
    echo "  docker start custom-signet"
    exit 1
fi

echo "✅ Custom signet docker running"

# Custom signet configuration
SIGNET_NAME="custom"
RPC_PORT=38332
NET="-signet=$SIGNET_NAME"

# Check if daemon is accessible
if ! bitcoin-cli "$NET" -rpcport=$RPC_PORT getblockchaininfo &> /dev/null; then
    echo "❌ Cannot connect to custom signet daemon"
    echo "   Check docker logs: docker logs custom-signet"
    exit 1
fi

echo "✅ Connected to custom signet"

# Create test wallets
echo ""
echo "Creating test wallets..."

for WALLET in hot_wallet cold_wallet recovery_wallet; do
    if bitcoin-cli "$NET" -rpcport=$RPC_PORT -rpcwallet=$WALLET getwalletinfo &> /dev/null 2>&1; then
        echo "  $WALLET exists ✓"
    else
        bitcoin-cli "$NET" -rpcport=$RPC_PORT -named createwallet wallet_name="$WALLET" descriptors=true > /dev/null
        echo "  $WALLET created ✓"
    fi
done

# Create watch-only quantum wallet
if bitcoin-cli "$NET" -rpcport=$RPC_PORT -rpcwallet=qs getwalletinfo &> /dev/null 2>&1; then
    echo "  qs (quantum) exists ✓"
else
    bitcoin-cli "$NET" -rpcport=$RPC_PORT -named createwallet wallet_name="qs" disable_private_keys=true blank=true descriptors=true > /dev/null
    echo "  qs (quantum) created ✓"
fi

# Extract xpubs
echo ""
echo "Extracting public keys..."

HOT=$(bitcoin-cli "$NET" -rpcport=$RPC_PORT -rpcwallet=hot_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+')
COLD=$(bitcoin-cli "$NET" -rpcport=$RPC_PORT -rpcwallet=cold_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+')
RECOV=$(bitcoin-cli "$NET" -rpcport=$RPC_PORT -rpcwallet=recovery_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+')

echo "  HOT:      ${HOT:0:20}..."
echo "  COLD:     ${COLD:0:20}..."
echo "  RECOVERY: ${RECOV:0:20}..."

# NUMS internal key
INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

# Build descriptor
DESC="tr(${INTERNAL},{{pk(${HOT}/0/*),pk(${COLD}/0/*)},and_v(v:pk(${RECOV}/0/*),older(1008))})"

echo ""
echo "Validating descriptor..."
RESULT=$(bitcoin-cli "$NET" -rpcport=$RPC_PORT getdescriptorinfo "$DESC")
CHECKSUM=$(echo "$RESULT" | jq -r '.checksum')
FULL_DESC="${DESC}#${CHECKSUM}"

# Import to quantum wallet
echo "Importing descriptor..."
bitcoin-cli "$NET" -rpcport=$RPC_PORT -rpcwallet=qs importdescriptors "[{\"desc\":\"$FULL_DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\"}]" > /dev/null

# Derive quantum address
QUANTUM_ADDR=$(bitcoin-cli "$NET" -rpcport=$RPC_PORT deriveaddresses "$FULL_DESC" "[0,0]" | jq -r '.[0]')

# Generate blocks for testing
echo ""
echo "Generating blocks for testing..."
MINER_ADDR=$(bitcoin-cli "$NET" -rpcport=$RPC_PORT -rpcwallet=hot_wallet getnewaddress)
bitcoin-cli "$NET" -rpcport=$RPC_PORT generatetoaddress 110 "$MINER_ADDR" > /dev/null
echo "✅ 110 blocks generated (spam flood + timelock test)"

# Fund quantum address
echo ""
echo "Funding quantum address..."
FUND_AMT=0.001
bitcoin-cli "$NET" -rpcport=$RPC_PORT -rpcwallet=hot_wallet sendtoaddress "$QUANTUM_ADDR" "$FUND_AMT" > /dev/null
bitcoin-cli "$NET" -rpcport=$RPC_PORT generatetoaddress 1 "$MINER_ADDR" > /dev/null
echo "✅ Funded $FUND_AMT BTC to quantum address"

# Check balance
BALANCE=$(bitcoin-cli "$NET" -rpcport=$RPC_PORT -rpcwallet=qs getbalance)

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         CUSTOM SIGNET WALLET READY                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "💰 QUANTUM ADDRESS:"
echo "   $QUANTUM_ADDR"
echo ""
echo "💵 BALANCE:"
echo "   $BALANCE BTC"
echo ""
echo "🔧 EDGE CASE TESTING:"
echo "   Spam flood test:    bitcoin-cli $NET -rpcport=$RPC_PORT generatetoaddress 100 $MINER_ADDR"
echo "   Timelock test:      Wait 1008 blocks, then test recovery"
echo "   Mempool test:       Create many small transactions"
echo "   Low fee test:       fundrawtransaction with fee_rate < 1"
echo ""
echo "📝 DESCRIPTOR:"
echo "   ${FULL_DESC:0:60}..."
echo "   Checksum: $CHECKSUM"
echo ""

