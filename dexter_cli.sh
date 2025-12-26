#!/bin/bash
# Dexter CLI Workflow Integration
# Runs Dexter for financial analysis queries and integrates with trading workflows
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         DEXTER FINANCIAL ANALYSIS CLI                      ║"
echo "║         Autonomous Agent for Deep Financial Research       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check for .env file
if [ ! -f .env ]; then
    echo "⚠️  No .env file found. Creating from template..."
    cp .env.example .env
    echo "✅ Created .env file. Please edit it and add your API keys:"
    echo "   - OPENAI_API_KEY"
    echo "   - FINANCIAL_DATASETS_API_KEY"
    exit 1
fi

# Source environment
source .env

# Check API keys
if [ -z "${OPENAI_API_KEY:-}" ] || [ -z "${FINANCIAL_DATASETS_API_KEY:-}" ]; then
    echo "❌ Missing API keys in .env file"
    echo "Please set:"
    echo "  - OPENAI_API_KEY"
    echo "  - FINANCIAL_DATASETS_API_KEY"
    exit 1
fi

# Check for Dexter installation
DEXTER_PATH="${DEXTER_PATH:-$HOME/dexter}"
if [ ! -d "$DEXTER_PATH" ]; then
    echo "❌ Dexter not found at: $DEXTER_PATH"
    echo ""
    echo "Install Dexter:"
    echo "  git clone https://github.com/virattt/dexter.git ~/dexter"
    echo "  cd ~/dexter && uv sync"
    echo ""
    echo "Or set DEXTER_PATH to your Dexter installation"
    exit 1
fi

echo "✅ Dexter found at: $DEXTER_PATH"

# Check for uv
if ! command -v uv &> /dev/null; then
    echo "⚠️  uv package manager not found. Install with:"
    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# Parse command line arguments
QUERY="${1:-}"
OUTPUT_FILE="${2:-}"
MODE="${3:-interactive}"

if [ -z "$QUERY" ] && [ "$MODE" != "interactive" ]; then
    echo "Usage: $0 \"<query>\" [output_file] [mode]"
    echo ""
    echo "Examples:"
    echo "  # Interactive query"
    echo "  $0 \"Tesla cash flow trends\""
    echo ""
    echo "  # Save to file for pipeline processing"
    echo "  $0 \"DRIFT protocol debt-to-equity\" analysis.json"
    echo ""
    echo "  # Crypto/DeFi queries"
    echo "  $0 \"Pendle YT decay vs yield optimization strategies\""
    echo "  $0 \"Compare Solana CLOB vs DLOB liquidity efficiency\""
    echo "  $0 \"Analyze BONK price volatility for risk management\""
    exit 1
fi

# Interactive mode
if [ -z "$QUERY" ]; then
    echo "Enter your financial analysis query:"
    echo "Examples:"
    echo "  - Tesla vs Microsoft operating margins 2023"
    echo "  - Bitcoin network hash rate impact on price"
    echo "  - Pendle yield token decay analysis"
    echo "  - DRIFT protocol revenue streams"
    echo ""
    read -rp "> " QUERY
fi

# Run Dexter
echo ""
echo "🤖 Running Dexter analysis..."
echo "Query: $QUERY"
echo ""

# Create output directory if saving to file
if [ -n "$OUTPUT_FILE" ]; then
    mkdir -p "$(dirname "$OUTPUT_FILE")"
fi

# Execute via Python wrapper
cd "$DEXTER_PATH"
if [ -n "$OUTPUT_FILE" ]; then
    OUTPUT_ARG="--output $OUTPUT_FILE"
else
    OUTPUT_ARG=""
fi

# Run with uv
export PYTHONPATH="$DEXTER_PATH:${PYTHONPATH:-}"
uv run python -c "
from dexter.agent import Agent
import json
import sys

query = '''$QUERY'''
output_file = '''$OUTPUT_FILE'''

try:
    agent = Agent(max_steps=${DEXTER_MAX_STEPS:-20})
    result = agent.run(query)
    
    print()
    print('='*60)
    print('ANALYSIS RESULTS')
    print('='*60)
    print(result)
    
    if output_file:
        data = {
            'query': query,
            'analysis': result,
            'status': 'success'
        }
        with open(output_file, 'w') as f:
            json.dump(data, f, indent=2)
        print()
        print(f'✅ Results saved to: {output_file}')
except Exception as e:
    print(f'❌ Error: {e}', file=sys.stderr)
    sys.exit(1)
"

echo ""
echo "✅ Analysis complete!"

# Suggest next steps
if [ -n "$OUTPUT_FILE" ]; then
    echo ""
    echo "Next steps:"
    echo "  - Parse results: jq '.analysis' $OUTPUT_FILE"
    echo "  - Chain with wallet: ./check_balance.sh"
    echo "  - Feed to trading script: cat $OUTPUT_FILE | your_trading_bot.py"
fi
