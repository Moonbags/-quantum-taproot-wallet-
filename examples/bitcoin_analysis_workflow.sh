#!/bin/bash
# Example: Bitcoin Market Analysis + Wallet Check
# Demonstrates chaining Dexter analysis with wallet operations
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║    Bitcoin Market Analysis + Wallet Operations             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. Analyze Bitcoin market conditions
echo "Step 1: Analyzing Bitcoin market conditions..."
echo "================================================"

./dexter_cli.sh \
    "Bitcoin price trends, network hash rate, and optimal transaction timing for next 7 days" \
    analysis_bitcoin_market.json

if [ ! -f analysis_bitcoin_market.json ]; then
    echo "❌ Analysis failed. Exiting."
    exit 1
fi

echo ""
echo "✅ Market analysis complete!"
echo ""

# 2. Check wallet balance
echo "Step 2: Checking wallet balance..."
echo "================================================"

# Use the quantum wallet address from setup
WALLET_ADDR=${QUANTUM_ADDR:-"tb1pmtcn2fl9f0sd24q22fhv0cardxwmnh9fm244m9yw04tcna2xqj0q2gjnld"}
./check_balance.sh "$WALLET_ADDR"

echo ""

# 3. Parse analysis results for decision making
echo "Step 3: Parsing analysis for trading signals..."
echo "================================================"

ANALYSIS=$(jq -r '.analysis' analysis_bitcoin_market.json)
echo "Analysis Summary:"
echo "$ANALYSIS" | head -20
echo "..."
echo ""

# 4. Decision logic (example)
echo "Step 4: Decision Logic"
echo "================================================"

# Simple example: extract sentiment from analysis
if echo "$ANALYSIS" | grep -qi "bullish\|positive\|increase"; then
    echo "🟢 Sentiment: BULLISH"
    echo "   Consider: Hold or accumulate Bitcoin"
    echo "   Wallet action: Monitor for incoming transactions"
elif echo "$ANALYSIS" | grep -qi "bearish\|negative\|decrease"; then
    echo "🔴 Sentiment: BEARISH"
    echo "   Consider: Review portfolio allocation"
    echo "   Wallet action: Consider moving to cold storage"
else
    echo "🟡 Sentiment: NEUTRAL"
    echo "   Consider: Wait for clearer signals"
fi

echo ""
echo "Full analysis saved to: analysis_bitcoin_market.json"
echo "Next steps:"
echo "  - Review detailed analysis: cat analysis_bitcoin_market.json | jq"
echo "  - Execute wallet operations: ./spend.sh"
echo "  - Set up recovery: ./recovery.sh"
