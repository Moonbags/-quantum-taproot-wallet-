#!/usr/bin/env python3
"""
Example: DeFi Protocol Analysis with Backtesting

This example demonstrates how to use Dexter for analyzing DeFi protocols
and integrating the results into a backtesting workflow for trading decisions.

Protocols analyzed:
- DRIFT: Perpetual futures on Solana
- Pendle: Yield tokenization
- GrokSwap: AMM and vault optimization
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from dexter_backtesting import DexterBacktest
import pandas as pd


def analyze_defi_protocols():
    """Analyze multiple DeFi protocols for trading opportunities."""
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║    DeFi Protocol Analysis for Trading Strategies          ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print()
    
    # Initialize backtesting integration
    backtest = DexterBacktest(cache_dir="defi_research")
    
    # Define protocols to analyze
    protocols = {
        "DRIFT": [
            "DRIFT protocol debt-to-equity ratio and solvency metrics",
            "DRIFT perpetual futures liquidity and slippage analysis",
            "DRIFT revenue streams and fee structure"
        ],
        "Pendle": [
            "Pendle YT (Yield Token) decay patterns and optimal holding periods",
            "Pendle vs traditional DeFi yield farming returns comparison",
            "Pendle liquidity pool composition and impermanent loss"
        ],
        "GrokSwap": [
            "GrokSwap vault optimization strategies for maximum APY",
            "GrokSwap CLOB vs DLOB efficiency comparison",
            "GrokSwap fee tier analysis for different trading volumes"
        ]
    }
    
    # Run analysis for each protocol
    all_results = []
    
    for protocol, queries in protocols.items():
        print(f"\n{'='*60}")
        print(f"Analyzing {protocol}")
        print('='*60)
        
        for query in queries:
            print(f"\nQuery: {query[:70]}...")
            result = backtest.pre_trade_research(query, use_cache=True)
            
            if result['status'] == 'success':
                print("✅ Analysis complete")
                all_results.append({
                    'protocol': protocol,
                    'query': query,
                    'status': 'success',
                    'analysis_preview': result.get('analysis', '')[:200]
                })
            else:
                print(f"❌ Error: {result.get('message', 'Unknown error')}")
                all_results.append({
                    'protocol': protocol,
                    'query': query,
                    'status': 'error',
                    'error': result.get('message', '')
                })
    
    # Create summary DataFrame
    df = pd.DataFrame(all_results)
    
    print("\n" + "="*60)
    print("ANALYSIS SUMMARY")
    print("="*60)
    print(f"\nTotal queries: {len(df)}")
    print(f"Successful: {(df['status'] == 'success').sum()}")
    print(f"Failed: {(df['status'] == 'error').sum()}")
    
    # Save results
    output_file = "defi_protocol_analysis.csv"
    df.to_csv(output_file, index=False)
    print(f"\n✅ Results saved to: {output_file}")
    
    # Print protocol breakdown
    print("\nBreakdown by protocol:")
    print(df.groupby('protocol')['status'].value_counts().to_string())
    
    return df


def compare_yield_strategies():
    """Compare different yield generation strategies."""
    
    print("\n" + "="*60)
    print("Yield Strategy Comparison")
    print("="*60)
    
    backtest = DexterBacktest()
    
    strategies = [
        "Pendle YT decay vs DROC (Drift ROC) yields comparison",
        "Solana staking vs DeFi yield farming returns 2024",
        "Bitcoin Lightning Network routing fees vs traditional mining",
        "GrokSwap vault strategies: Single-sided vs LP vs leveraged"
    ]
    
    df = backtest.research_to_dataframe(strategies)
    
    print("\n✅ Yield strategy analysis complete")
    print(df[['query', 'status']].to_string(index=False))
    
    return df


def risk_analysis():
    """Analyze risk factors for volatile crypto assets."""
    
    print("\n" + "="*60)
    print("Risk Analysis for Volatile Assets")
    print("="*60)
    
    backtest = DexterBacktest()
    
    # Focus on high-volatility tokens
    risk_queries = [
        "BONK token price volatility patterns and risk metrics",
        "DRIFT protocol liquidation cascade risks and circuit breakers",
        "Solana network congestion impact on DeFi protocols",
        "Cross-protocol contagion risks in Solana DeFi ecosystem"
    ]
    
    df = backtest.research_to_dataframe(risk_queries)
    
    print("\n✅ Risk analysis complete")
    
    # Save to separate file
    output_file = "defi_risk_analysis.csv"
    df.to_csv(output_file, index=False)
    print(f"Results saved to: {output_file}")
    
    return df


def main():
    """Run all DeFi analysis examples."""
    
    print("Starting DeFi Protocol Analysis Workflow\n")
    
    # Run different analysis types
    try:
        protocol_df = analyze_defi_protocols()
        yield_df = compare_yield_strategies()
        risk_df = risk_analysis()
        
        print("\n" + "="*60)
        print("ALL ANALYSES COMPLETE")
        print("="*60)
        print("\nGenerated files:")
        print("  - defi_protocol_analysis.csv")
        print("  - defi_risk_analysis.csv")
        print("  - defi_research/ (cache directory)")
        print("\nNext steps:")
        print("  1. Review analysis results")
        print("  2. Integrate into your trading bot")
        print("  3. Set up automated research pipeline")
        print("  4. Monitor protocol changes with scheduled queries")
        
    except Exception as e:
        print(f"\n❌ Error during analysis: {e}")
        print("\nMake sure you have:")
        print("  - Dexter installed (git clone https://github.com/virattt/dexter.git)")
        print("  - API keys configured in .env file")
        print("  - uv package manager installed")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())
