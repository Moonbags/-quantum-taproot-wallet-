# Dexter Integration Examples

This directory contains practical examples of how to integrate Dexter financial analysis with the Quantum Taproot Wallet and trading workflows.

## Examples Overview

### 1. Bitcoin Analysis Workflow (`bitcoin_analysis_workflow.sh`)

Complete workflow demonstrating market analysis + wallet operations.

**What it does:**
- Analyzes Bitcoin market conditions using Dexter
- Checks your wallet balance
- Provides trading signals based on analysis
- Suggests next actions

**Usage:**
```bash
./bitcoin_analysis_workflow.sh
```

**Output:**
- `analysis_bitcoin_market.json` - Full market analysis
- Trading signals (bullish/bearish/neutral)
- Recommended wallet actions

---

### 2. DeFi Protocol Analysis (`defi_analysis.py`)

Comprehensive DeFi protocol research and comparison.

**What it analyzes:**
- **DRIFT**: Perpetual futures, debt-to-equity, revenue streams
- **Pendle**: YT decay, yield comparison, LP analysis  
- **GrokSwap**: Vault optimization, CLOB vs DLOB, fee tiers

**Usage:**
```bash
# Run full analysis
python3 defi_analysis.py

# Or use specific functions
python3 -c "from examples.defi_analysis import analyze_defi_protocols; analyze_defi_protocols()"
```

**Output:**
- `defi_protocol_analysis.csv` - Protocol comparisons
- `defi_risk_analysis.csv` - Risk metrics
- `defi_research/` - Cached research results

---

## Quick Start

### Prerequisites

1. **Install Dexter:**
```bash
git clone https://github.com/virattt/dexter.git ~/dexter
cd ~/dexter && uv sync
```

2. **Configure API keys:**
```bash
# In the quantum-taproot-wallet directory
cp .env.example .env
# Edit .env and add your API keys
```

3. **Install Python dependencies:**
```bash
uv sync
```

### Run Examples

**Bitcoin Analysis:**
```bash
cd /path/to/quantum-taproot-wallet
./examples/bitcoin_analysis_workflow.sh
```

**DeFi Analysis:**
```bash
python3 examples/defi_analysis.py
```

---

## Example Queries

### Bitcoin & Cryptocurrency

```bash
# Market conditions
./dexter_cli.sh "Bitcoin price trends and network hash rate correlation"

# Transaction timing
./dexter_cli.sh "Optimal Bitcoin transaction timing based on mempool congestion"

# Network metrics
./dexter_cli.sh "Solana validator performance and network reliability"
```

### DeFi Protocols

```bash
# Protocol analysis
./dexter_cli.sh "DRIFT protocol solvency and liquidation risks"

# Yield optimization
./dexter_cli.sh "Pendle YT decay vs traditional yield farming returns"

# Liquidity analysis
./dexter_cli.sh "GrokSwap CLOB vs DLOB efficiency comparison"
```

### Trading Strategies

```bash
# Volatility
./dexter_cli.sh "BONK token price volatility patterns for risk management"

# Yield comparison
./dexter_cli.sh "Compare staking yields across Ethereum, Solana, and Cosmos"

# Risk assessment
./dexter_cli.sh "Cross-protocol contagion risks in Solana DeFi ecosystem"
```

---

## Customizing Examples

### Modify Bitcoin Analysis Workflow

Edit `bitcoin_analysis_workflow.sh`:

```bash
# Change the analysis query (line ~14)
./dexter_cli.sh \
    "YOUR CUSTOM QUERY HERE" \
    analysis_bitcoin_market.json

# Change wallet address (line ~30)
WALLET_ADDR="your-wallet-address-here"

# Modify decision logic (line ~46)
if echo "$ANALYSIS" | grep -qi "your-signal"; then
    echo "Your custom action"
fi
```

### Extend DeFi Analysis

Edit `defi_analysis.py`:

```python
# Add new protocols (line ~32)
protocols = {
    "YourProtocol": [
        "Query 1 about your protocol",
        "Query 2 about your protocol",
    ]
}

# Add custom analysis functions
def your_custom_analysis():
    backtest = DexterBacktest()
    result = backtest.pre_trade_research("Your query")
    return result
```

---

## Integration Patterns

### 1. Pre-Trade Research

```python
from dexter_backtesting import DexterBacktest

backtest = DexterBacktest()

# Research before trading
research = backtest.pre_trade_research(
    "Protocol X revenue streams and sustainability"
)

# Use in trading logic
if "positive revenue growth" in research['analysis'].lower():
    execute_trade()
```

### 2. Batch Analysis

```python
# Analyze multiple assets
protocols = ["Uniswap", "PancakeSwap", "Raydium"]
df = backtest.batch_crypto_analysis(
    protocols=protocols,
    metrics=["liquidity", "volume", "fees"]
)

# Export for further analysis
df.to_csv('protocol_comparison.csv')
```

### 3. Scheduled Analysis

```bash
# Cron job for daily Bitcoin analysis
0 9 * * * cd /path/to/quantum-wallet && ./dexter_cli.sh "Bitcoin daily market analysis" daily_analysis_$(date +\%Y\%m\%d).json
```

### 4. Pipeline Integration

```bash
#!/bin/bash
# trading_pipeline.sh

# 1. Market analysis
./dexter_cli.sh "Market conditions" market.json

# 2. Parse results
SENTIMENT=$(jq -r '.analysis' market.json | analyze_sentiment.py)

# 3. Execute trades based on sentiment
if [ "$SENTIMENT" == "bullish" ]; then
    ./your_trading_bot.py --action buy
fi
```

---

## Output Formats

### JSON Output

```json
{
  "status": "success",
  "query": "Bitcoin price trends",
  "analysis": "Detailed analysis text...",
  "config": {
    "max_steps": 20,
    "model": "gpt-4-turbo-preview"
  }
}
```

### CSV Output (from defi_analysis.py)

```csv
protocol,query,status,analysis_preview
DRIFT,DRIFT protocol debt-to-equity,success,"Analysis shows..."
Pendle,Pendle YT decay patterns,success,"Research indicates..."
```

---

## Advanced Usage

### Custom Agent Configuration

```python
from dexter_integration.agent_wrapper import DexterAgent

agent = DexterAgent(
    max_steps=15,              # Reduce for faster results
    max_steps_per_task=3,      # Prevent loops
    model="gpt-4-turbo-preview"
)

result = agent.run("Custom query")
```

### Caching Results

```python
backtest = DexterBacktest(cache_dir="my_research")

# First call: fetches from Dexter
result1 = backtest.pre_trade_research("Query", use_cache=True)

# Second call: uses cached result
result2 = backtest.pre_trade_research("Query", use_cache=True)
```

### Error Handling

```python
result = agent.run(query)

if result['status'] == 'success':
    # Process analysis
    analysis = result['analysis']
else:
    # Handle error
    print(f"Error: {result['message']}")
    # Fallback to alternative data source
```

---

## Troubleshooting

### "Dexter not found"

```bash
# Make sure Dexter is installed
ls ~/dexter

# If not, install it
git clone https://github.com/virattt/dexter.git ~/dexter
cd ~/dexter && uv sync
```

### "Missing API keys"

```bash
# Check .env file
cat .env | grep API_KEY

# Make sure both keys are set
OPENAI_API_KEY=sk-...
FINANCIAL_DATASETS_API_KEY=...
```

### "Analysis takes too long"

```python
# Reduce max_steps
agent = DexterAgent(max_steps=10, max_steps_per_task=3)
```

---

## Tips & Best Practices

1. **Cache Results**: Use `use_cache=True` to avoid redundant API calls
2. **Batch Queries**: Process multiple queries together for efficiency
3. **Monitor Costs**: Check OpenAI dashboard for API usage
4. **Validate Results**: Always check `status` field before using analysis
5. **Version Control**: Keep analysis results in separate directory (`.gitignore`)

---

## Next Steps

1. **Run the examples** to see Dexter in action
2. **Customize queries** for your specific needs
3. **Integrate with your trading bots**
4. **Set up automated analysis** with cron jobs
5. **Extend functionality** with custom tools

---

## Resources

- [Dexter GitHub](https://github.com/virattt/dexter)
- [Full Integration Guide](../DEXTER_INTEGRATION.md)
- [Main README](../README.md)

---

*Happy trading! 🚀*
