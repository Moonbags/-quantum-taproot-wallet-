# Dexter Integration - Quick Start

Get started with Dexter financial analysis in 5 minutes!

## Prerequisites

- Python 3.10+
- Git
- OpenAI API Key ([get one here](https://platform.openai.com/api-keys))
- Financial Datasets API Key ([sign up here](https://financialdatasets.ai))

## Installation (5 Steps)

### 1. Install uv Package Manager

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 2. Clone and Setup Dexter

```bash
cd ~
git clone https://github.com/virattt/dexter.git
cd dexter
uv sync
```

This installs Dexter and all dependencies.

### 3. Configure API Keys

In the quantum-taproot-wallet directory:

```bash
cd /path/to/quantum-taproot-wallet
cp .env.example .env
```

Edit `.env` and add your keys:

```bash
OPENAI_API_KEY=sk-your-openai-key-here
FINANCIAL_DATASETS_API_KEY=your-financial-datasets-key-here
```

### 4. Install Python Dependencies

```bash
uv sync
```

### 5. Test the Integration

```bash
./dexter_cli.sh "What are Bitcoin price trends for Q4 2024?"
```

## Quick Examples

### Example 1: Bitcoin Market Analysis

```bash
./dexter_cli.sh "Bitcoin network hash rate and price correlation"
```

### Example 2: DeFi Protocol Analysis

```bash
./dexter_cli.sh "DRIFT protocol solvency and liquidation risks"
```

### Example 3: Save Results to File

```bash
./dexter_cli.sh "Solana network performance metrics" solana_analysis.json
cat solana_analysis.json | jq '.analysis'
```

### Example 4: Full Workflow

```bash
# Run the complete Bitcoin + wallet workflow
./examples/bitcoin_analysis_workflow.sh
```

### Example 5: DeFi Batch Analysis

```bash
# Analyze multiple DeFi protocols
python3 examples/defi_analysis.py
```

## Common Queries

### Cryptocurrency

```bash
# Bitcoin
./dexter_cli.sh "Optimal Bitcoin transaction timing based on mempool"

# Solana
./dexter_cli.sh "Solana validator performance and uptime statistics"

# Volatility
./dexter_cli.sh "BONK token volatility patterns for risk management"
```

### DeFi Protocols

```bash
# DRIFT
./dexter_cli.sh "DRIFT protocol debt-to-equity and revenue analysis"

# Pendle
./dexter_cli.sh "Pendle YT decay vs traditional yield farming"

# GrokSwap
./dexter_cli.sh "GrokSwap vault optimization strategies"
```

### Trading Signals

```bash
# Market timing
./dexter_cli.sh "Best time to transact Bitcoin based on fees and congestion"

# Yield comparison
./dexter_cli.sh "Compare staking yields: Ethereum vs Solana vs Cosmos"

# Risk assessment
./dexter_cli.sh "Cross-protocol risks in Solana DeFi ecosystem"
```

## Programmatic Usage

### Python Script

```python
from dexter_integration.agent_wrapper import DexterAgent

# Initialize
agent = DexterAgent(max_steps=20)

# Run query
result = agent.run("Analyze Bitcoin trends")

# Use results
if result['status'] == 'success':
    print(result['analysis'])
```

### Jupyter Notebook

```python
from dexter_backtesting import DexterBacktest
import pandas as pd

# Initialize
backtest = DexterBacktest()

# Research
research = backtest.pre_trade_research("Bitcoin hash rate trends")

# Display
from IPython.display import display, Markdown
display(Markdown(research['analysis']))
```

### Batch Analysis

```python
from dexter_backtesting import DexterBacktest

backtest = DexterBacktest()

# Multiple queries
queries = [
    "Bitcoin price trends Q4 2024",
    "Ethereum gas fees optimization",
    "Solana network congestion"
]

# Get DataFrame
df = backtest.research_to_dataframe(queries)
df.to_csv('crypto_research.csv')
```

## Integration with Wallet

### Analyze Then Transact

```bash
# 1. Get market analysis
./dexter_cli.sh "Bitcoin market conditions next 7 days" market.json

# 2. Check wallet
./check_balance.sh tb1p...

# 3. Decide based on analysis
if grep -q "bullish" market.json; then
    echo "Holding position"
else
    echo "Consider moving to cold storage"
fi
```

## Troubleshooting

### "Dexter not found"

```bash
# Make sure Dexter is in ~/dexter
ls ~/dexter

# Or set custom path
export DEXTER_PATH=/your/path/to/dexter
```

### "Missing API keys"

```bash
# Verify .env file
cat .env | grep API_KEY

# Make sure both keys are set
source .env
echo $OPENAI_API_KEY
echo $FINANCIAL_DATASETS_API_KEY
```

### "Module not found"

```bash
# Install dependencies
uv sync

# Or with pip
pip install python-dotenv pandas requests
```

## Next Steps

1. ✅ **Read the full guide**: [DEXTER_INTEGRATION.md](DEXTER_INTEGRATION.md)
2. ✅ **Explore examples**: Check `examples/` directory
3. ✅ **Customize queries**: Tailor to your trading strategy
4. ✅ **Automate**: Set up cron jobs for scheduled analysis
5. ✅ **Integrate**: Feed into your trading bots

## Resources

- **Full Documentation**: [DEXTER_INTEGRATION.md](DEXTER_INTEGRATION.md)
- **Examples**: [examples/README.md](examples/README.md)
- **Dexter GitHub**: https://github.com/virattt/dexter
- **Financial Datasets**: https://financialdatasets.ai

## Cost Considerations

- OpenAI API charges per token used
- Financial Datasets may have usage limits
- Cache results to reduce API calls (`use_cache=True`)
- Monitor usage in OpenAI dashboard

## Tips

1. **Start small**: Test with simple queries first
2. **Use cache**: Enable caching for repeated queries
3. **Batch queries**: More efficient than one-by-one
4. **Monitor costs**: Check OpenAI usage dashboard regularly
5. **Validate results**: Always check `status` field

---

**Ready to analyze! 🚀**

For detailed documentation, see [DEXTER_INTEGRATION.md](DEXTER_INTEGRATION.md)
