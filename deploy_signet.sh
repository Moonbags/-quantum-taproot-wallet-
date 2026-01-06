#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Deploying Quantum Taproot Wallet to Signet"
echo "=============================================="

# Check if bitcoin-cli is available
if ! command -v bitcoin-cli &> /dev/null; then
    echo -e "${RED}❌ bitcoin-cli not found${NC}"
    echo "Please install Bitcoin Core and ensure bitcoin-cli is in your PATH"
    exit 1
fi

# Check if bitcoind is running
if ! bitcoin-cli -signet getblockchaininfo &> /dev/null; then
    echo -e "${RED}❌ Bitcoin Core (signet) is not running${NC}"
    echo "Please start bitcoind with -signet flag"
    exit 1
fi

echo -e "${GREEN}✓ Bitcoin Core (signet) is running${NC}"

# Check sync status
BLOCKCHAIN_INFO=$(bitcoin-cli -signet getblockchaininfo)
VERIFICATION=$(echo "$BLOCKCHAIN_INFO" | jq -r '.verificationprogress')

if (( $(echo "$VERIFICATION < 0.99" | bc -l) )); then
    echo ""
    echo "⚠️  Warning: Chain not fully synced yet"
    echo "   Progress: $(echo "$VERIFICATION * 100" | bc -l | cut -d. -f1)%"
    echo "   You can continue, but some operations may fail"
    echo ""
    if [ "${CI:-false}" != "true" ]; then
        read -rp "Continue anyway? (y/N): " CONTINUE
        [[ "$CONTINUE" != "y" ]] && exit 0
    else
        echo "   [CI MODE] Auto-continuing..."
    fi
fi

echo -e "${GREEN}✓ Chain sync status acceptable${NC}"

# Get wallet name
WALLET_NAME="quantum_taproot_wallet"

# Check if wallet exists
if bitcoin-cli -signet listwallets | grep -q "\"$WALLET_NAME\""; then
    echo -e "${YELLOW}⚠ Wallet '$WALLET_NAME' already exists${NC}"
else
    echo "Creating wallet '$WALLET_NAME'..."
    bitcoin-cli -signet createwallet "$WALLET_NAME" false false "" false true
    echo -e "${GREEN}✓ Wallet created${NC}"
fi

# Load wallet if not loaded
if ! bitcoin-cli -signet listwallets | grep -q "\"$WALLET_NAME\""; then
    echo "Loading wallet '$WALLET_NAME'..."
    bitcoin-cli -signet loadwallet "$WALLET_NAME"
    echo -e "${GREEN}✓ Wallet loaded${NC}"
fi

# Get a new address
ADDRESS=$(bitcoin-cli -signet -rpcwallet="$WALLET_NAME" getnewaddress)
echo ""
echo "📬 Your Signet Address:"
echo "   $ADDRESS"
echo ""

# Check balance
BALANCE=$(bitcoin-cli -signet -rpcwallet="$WALLET_NAME" getbalance)
echo "💰 Current Balance: $BALANCE BTC (Signet)"

if (( $(echo "$BALANCE == 0" | bc -l) )); then
    echo ""
    echo "To get Signet coins, use a faucet:"
    echo "   https://signetfaucet.com"
    echo "   https://alt.signetfaucet.com"
    echo ""
fi

echo ""
echo -e "${GREEN}✅ Deployment to Signet complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Fund your wallet using a Signet faucet"
echo "2. Run the quantum taproot example scripts"
echo "3. Monitor transactions on Signet explorer"
