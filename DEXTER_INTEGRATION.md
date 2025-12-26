# Dexter Integration Guide

Dexter integrates seamlessly into the Quantum Taproot Wallet project as a CLI tool and Python module for autonomous financial analysis. This integration complements your Bitcoin operations with deep market research, DeFi analysis, and trading insights.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [CLI Workflow Integration](#cli-workflow-integration)
4. [Programmatic Embedding](#programmatic-embedding)
5. [Advanced Use Cases](#advanced-use-cases)
6. [Examples](#examples)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

- **Python 3.10+**: Check with `python3 --version`
- **uv package manager**: Fast Python package installer
- **Git**: For cloning Dexter repository

### API Keys

You need two API keys:

1. **OpenAI API Key**: For the AI agent
   - Get from: https://platform.openai.com/api-keys
   - Starts with `sk-`

2. **Financial Datasets API Key**: For financial data access
   - Get from: https://financialdatasets.ai
   - Sign up and get your API key

---

## Installation

### Step 1: Install uv Package Manager

```bash
# Linux/macOS
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or via pip
pip install uv
```

### Step 2: Clone Dexter Repository

```bash
cd ~
git clone https://github.com/virattt/dexter.git
cd dexter
uv sync
```

This installs Dexter and all its dependencies in an isolated environment.

### Step 3: Configure API Keys

In your Quantum Taproot Wallet directory:

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env and add your API keys
nano .env
```

Add your keys:
```bash
OPENAI_API_KEY=sk-your-openai-api-key-here
FINANCIAL_DATASETS_API_KEY=your-financial-datasets-api-key-here
```

### Step 4: Install Python Dependencies

```bash
# From the quantum wallet directory
uv sync
```

---

## CLI Workflow Integration

### Quick Start

Run financial analysis queries directly from the command line:

```bash
./dexter_cli.sh "Tesla cash flow trends Q4 2024"
```

### Saving Results to File

Pipe output to files for use in trading scripts:

```bash
./dexter_cli.sh "Bitcoin network hash rate impact on price" btc_analysis.json
```

### Example Queries

#### Traditional Finance
```bash
# Corporate analysis
./dexter_cli.sh "Compare Microsoft and Google operating margins 2023"

# Cash flow analysis
./dexter_cli.sh "Tesla cash flow trends and profitability metrics"
```

#### Cryptocurrency
```bash
# Bitcoin analysis
./dexter_cli.sh "Bitcoin price correlation with network hash rate"

# Network metrics
./dexter_cli.sh "Solana validator performance and network congestion patterns"
```

#### DeFi Protocols
```bash
# Protocol analysis
./dexter_cli.sh "DRIFT protocol debt-to-equity ratio and solvency"

# Yield comparison
./dexter_cli.sh "Pendle YT decay vs DROC yields comparison"

# Liquidity analysis
./dexter_cli.sh "GrokSwap vault optimization strategies for maximum APY"
```

#### Trading Signals
```bash
# Volatility analysis
./dexter_cli.sh "BONK token price volatility patterns for risk management"

# Market timing
./dexter_cli.sh "Optimal Bitcoin transaction timing based on mempool and fees"
```

### Chaining with Wallet Operations

Integrate analysis with your wallet operations:

```bash
# 1. Get market analysis
./dexter_cli.sh "Bitcoin market conditions next 7 days" market.json

# 2. Check wallet balance
./check_balance.sh tb1p...

# 3. Make informed decision
if grep -q "bullish" market.json; then
    echo "Market is bullish, holding BTC"
else
    echo "Consider moving to cold storage"
fi
```

See `examples/bitcoin_analysis_workflow.sh` for a complete workflow.

---

## Programmatic Embedding

### Python Module Usage

Import Dexter into your Python scripts:

```python
from dexter_integration.agent_wrapper import DexterAgent

# Initialize agent
agent = DexterAgent(max_steps=20)

# Run analysis
result = agent.run("Analyze Bitcoin price trends")

# Access results
if result['status'] == 'success':
    print(result['analysis'])
```

### Backtesting Integration

Use Dexter for pre-trade research:

```python
from dexter_backtesting import DexterBacktest

# Initialize
backtest = DexterBacktest()

# Pre-trade research
research = backtest.pre_trade_research(
    "DRIFT protocol revenue streams and fee structure"
)

# Use in your trading logic
if "positive" in research['analysis'].lower():
    # Execute trade
    pass
```

### Batch Analysis with Pandas

Analyze multiple assets and get results as DataFrame:

```python
from dexter_backtesting import DexterBacktest
import pandas as pd

backtest = DexterBacktest()

# Define queries
queries = [
    "Bitcoin hash rate trends Q4 2024",
    "Ethereum gas fees optimization strategies",
    "Solana network congestion patterns"
]

# Get results as DataFrame
df = backtest.research_to_dataframe(queries)

# Save to CSV
df.to_csv('crypto_analysis.csv', index=False)

# Use in pandas workflow
for _, row in df.iterrows():
    if row['status'] == 'success':
        print(f"Query: {row['query']}")
        print(f"Result: {row['analysis'][:200]}...")
```

### Jupyter Notebook Integration

Perfect for interactive research:

```python
# In Jupyter notebook
from dexter_integration.agent_wrapper import DexterAgent
import pandas as pd

agent = DexterAgent(max_steps=20)

# Interactive analysis
result = agent.run("Compare top 5 DeFi protocols by TVL")

# Display results
from IPython.display import display, Markdown
display(Markdown(result['analysis']))
```

---

## Advanced Use Cases

### 1. Airdrop Research

Research upcoming airdrops before participating:

```python
from dexter_backtesting import DexterBacktest

backtest = DexterBacktest()

# Research airdrop
info = backtest.airdrop_research("Jupiter")

print(info['analysis'])
# Shows: eligibility criteria, timeline, token distribution
```

### 2. DeFi Vault Optimization

Optimize yield strategies:

```python
vault_analysis = backtest.defi_vault_optimization(
    vault_name="GrokSwap",
    strategies=["single-sided", "LP", "leveraged"]
)

# Compare APY, risk, and impermanent loss
print(vault_analysis['analysis'])
```

### 3. Batch Protocol Analysis

Compare multiple protocols:

```python
df = backtest.batch_crypto_analysis(
    protocols=["DRIFT", "Pendle", "Raydium"],
    metrics=["liquidity", "volume", "fees"]
)

# Get comparative insights
print(df.to_string())
```

### 4. Custom Tool Integration

Extend Dexter with your own data sources:

```python
# Future enhancement: Add Helius/Drift APIs
# Modify dexter/tools.py to include:
# - Solana RPC queries
# - On-chain analytics
# - Custom DeFi metrics
```

### 5. Rate Limiting for High Volatility

Prevent infinite loops in volatile markets:

```python
agent = DexterAgent(
    max_steps=20,
    max_steps_per_task=5  # Limits steps per subtask
)

# Safe for BONK/DRIFT analysis
result = agent.run("BONK price swings and trading volume")
```

---

## Examples

### Example 1: Bitcoin Market Analysis Workflow

Complete workflow combining analysis and wallet operations:

```bash
./examples/bitcoin_analysis_workflow.sh
```

This script:
1. Analyzes Bitcoin market conditions
2. Checks your wallet balance
3. Provides trading signals based on analysis
4. Suggests next actions

### Example 2: DeFi Protocol Analysis

Comprehensive DeFi protocol research:

```bash
python3 examples/defi_analysis.py
```

Analyzes:
- DRIFT (perpetual futures)
- Pendle (yield tokenization)
- GrokSwap (AMM optimization)

Outputs:
- `defi_protocol_analysis.csv`
- `defi_risk_analysis.csv`

### Example 3: Yield Strategy Comparison

```python
from dexter_backtesting import DexterBacktest

backtest = DexterBacktest()

strategies = [
    "Pendle YT vs staking yields",
    "Lightning routing fees vs mining",
    "DeFi farming vs CEX lending"
]

results = backtest.research_to_dataframe(strategies)
results.to_csv('yield_comparison.csv')
```

---

## Integration with Existing Tools

### TradingView Pine Script

Feed Dexter analysis into your TradingView indicators:

```bash
# Get analysis
./dexter_cli.sh "Bitcoin RSI and MACD signals" signals.json

# Parse for Pine Script
jq '.analysis' signals.json | your_pine_script_generator.py
```

### Solana RPC Integration

Combine on-chain data with fundamental analysis:

```bash
# 1. Get on-chain metrics via Solana RPC
solana balance <address>

# 2. Get fundamental analysis via Dexter
./dexter_cli.sh "Solana ecosystem growth metrics"

# 3. Combine for trading decision
```

### Backtesting Framework

Integrate into your backtesting loop:

```python
# Pseudo-code for backtesting integration
def backtest_strategy(dates, signals):
    for date in dates:
        # Get Dexter research for that period
        research = dexter.pre_trade_research(
            f"Market conditions on {date}"
        )
        
        # Use research to inform strategy
        if should_trade(research):
            signals.append(generate_signal(research))
    
    return evaluate_performance(signals)
```

---

## Configuration

### Environment Variables

Create `.env` file with:

```bash
# Required
OPENAI_API_KEY=sk-...
FINANCIAL_DATASETS_API_KEY=...

# Optional
OPENAI_MODEL=gpt-4-turbo-preview
DEXTER_MAX_STEPS=20
DEXTER_MAX_STEPS_PER_TASK=5
DEXTER_PATH=/path/to/dexter  # Auto-detected if in ~/dexter
```

### Python Configuration

Customize agent behavior:

```python
agent = DexterAgent(
    dexter_path="~/dexter",           # Custom Dexter location
    max_steps=20,                      # Total steps
    max_steps_per_task=5,             # Per-task limit
    model="gpt-4-turbo-preview"       # OpenAI model
)
```

---

## Troubleshooting

### Issue: "Dexter not found"

```bash
# Install Dexter
git clone https://github.com/virattt/dexter.git ~/dexter
cd ~/dexter && uv sync

# Or set DEXTER_PATH
export DEXTER_PATH=/path/to/your/dexter
```

### Issue: "Missing API keys"

```bash
# Check .env file exists
ls -la .env

# Verify keys are set
cat .env | grep API_KEY

# Make sure keys are not empty
source .env
echo $OPENAI_API_KEY
```

### Issue: "ModuleNotFoundError"

```bash
# Install dependencies
uv sync

# Or via pip
pip install -r requirements.txt
```

### Issue: "Rate limit exceeded"

```python
# Reduce request frequency
agent = DexterAgent(max_steps_per_task=3)

# Add delays between queries
import time
for query in queries:
    result = agent.run(query)
    time.sleep(2)  # 2 second delay
```

### Issue: Analysis takes too long

```python
# Reduce max steps
agent = DexterAgent(
    max_steps=10,           # Reduced from 20
    max_steps_per_task=3    # Reduced from 5
)
```

---

## Best Practices

### 1. Cache Results

```python
backtest = DexterBacktest(cache_dir="research_cache")
result = backtest.pre_trade_research(query, use_cache=True)
```

### 2. Batch Queries

```python
# More efficient than individual calls
queries = ["query1", "query2", "query3"]
df = backtest.research_to_dataframe(queries)
```

### 3. Version Control

```bash
# Fork Dexter for custom modifications
cd ~/dexter
git remote add fork https://github.com/yourusername/dexter.git

# Make changes
# Commit and PR improvements
```

### 4. Monitor Costs

```python
# Track API usage
import logging
logging.basicConfig(level=logging.INFO)

# Review OpenAI dashboard for costs
# https://platform.openai.com/usage
```

### 5. Validate Results

```python
result = agent.run(query)

if result['status'] == 'success':
    # Use analysis
    analysis = result['analysis']
else:
    # Handle error
    print(f"Error: {result['message']}")
```

---

## Next Steps

1. **Explore Examples**: Run the example scripts to see Dexter in action
2. **Customize Queries**: Tailor queries to your specific trading strategy
3. **Automate Research**: Set up cron jobs for scheduled analysis
4. **Extend Functionality**: Add custom tools to Dexter for your data sources
5. **Integrate with Bots**: Feed Dexter insights to your trading bots

---

## Resources

- **Dexter GitHub**: https://github.com/virattt/dexter
- **Financial Datasets**: https://financialdatasets.ai
- **OpenAI API**: https://platform.openai.com/docs
- **This Repository**: Examples and integration code

---

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review example scripts in `examples/`
3. Open an issue on GitHub
4. Consult the Dexter documentation

---

*Happy analyzing! 🚀*
