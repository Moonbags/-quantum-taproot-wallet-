#!/usr/bin/env python3
"""
Dexter Backtesting Integration

Integrates Dexter financial analysis into backtesting and quantitative trading workflows.
This script demonstrates how to use Dexter for pre-trade research and embed results
into pandas DataFrames for further analysis.

Usage:
    # Direct import in your backtesting code
    from dexter_backtesting import DexterBacktest
    
    backtest = DexterBacktest()
    research = backtest.pre_trade_research("BONK price volatility patterns")
    
    # Use in pandas workflow
    df = backtest.research_to_dataframe([
        "Bitcoin hash rate trends",
        "Solana validator performance metrics"
    ])
"""

import os
import sys
import json
import pandas as pd
from datetime import datetime
from typing import List, Dict, Any, Optional
from pathlib import Path

# Add dexter_integration to path
sys.path.insert(0, str(Path(__file__).parent))

from dexter_integration.agent_wrapper import DexterAgent


class DexterBacktest:
    """
    Integration layer between Dexter and backtesting workflows.
    
    Provides methods to run financial research queries before quantitative
    simulations and store results in formats suitable for further analysis.
    """
    
    def __init__(self, cache_dir: str = "backtest_research"):
        """
        Initialize the backtesting integration.
        
        Args:
            cache_dir: Directory to cache research results
        """
        self.agent = DexterAgent(max_steps=20, max_steps_per_task=5)
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(exist_ok=True)
        self.results_cache = {}
    
    def pre_trade_research(
        self,
        query: str,
        use_cache: bool = True
    ) -> Dict[str, Any]:
        """
        Run pre-trade research query using Dexter.
        
        Args:
            query: Research question (e.g., "DRIFT airdrop roadmap")
            use_cache: Whether to use cached results if available
            
        Returns:
            Research results dictionary
        """
        # Check cache
        cache_key = self._cache_key(query)
        cache_file = self.cache_dir / f"{cache_key}.json"
        
        if use_cache and cache_file.exists():
            print(f"Loading cached research: {query[:50]}...")
            with open(cache_file, 'r') as f:
                return json.load(f)
        
        # Run fresh analysis
        print(f"Running Dexter research: {query[:50]}...")
        result = self.agent.run(query)
        
        # Cache result
        with open(cache_file, 'w') as f:
            json.dump(result, f, indent=2)
        
        self.results_cache[query] = result
        return result
    
    def research_to_dataframe(
        self,
        queries: List[str],
        include_metadata: bool = True
    ) -> pd.DataFrame:
        """
        Run multiple research queries and return results as pandas DataFrame.
        
        Args:
            queries: List of research questions
            include_metadata: Include query metadata in DataFrame
            
        Returns:
            pandas DataFrame with research results
        """
        results = []
        
        for query in queries:
            research = self.pre_trade_research(query)
            
            row = {
                'query': query,
                'timestamp': datetime.now().isoformat(),
                'status': research.get('status', 'unknown'),
                'analysis': research.get('analysis', ''),
            }
            
            if include_metadata:
                row.update({
                    'max_steps': research.get('config', {}).get('max_steps', 0),
                    'model': research.get('config', {}).get('model', ''),
                })
            
            results.append(row)
        
        return pd.DataFrame(results)
    
    def batch_crypto_analysis(
        self,
        protocols: List[str],
        metrics: List[str] = ["liquidity", "volume", "fees"]
    ) -> pd.DataFrame:
        """
        Run batch analysis for multiple crypto protocols.
        
        Args:
            protocols: List of protocol names (e.g., ["DRIFT", "Pendle", "Raydium"])
            metrics: Metrics to analyze for each protocol
            
        Returns:
            DataFrame with comparative analysis
        """
        queries = []
        for protocol in protocols:
            for metric in metrics:
                query = f"Analyze {protocol} protocol {metric} trends and performance"
                queries.append(query)
        
        return self.research_to_dataframe(queries)
    
    def airdrop_research(self, protocol: str) -> Dict[str, Any]:
        """
        Research airdrop opportunities and roadmaps.
        
        Args:
            protocol: Protocol name (e.g., "DRIFT")
            
        Returns:
            Airdrop analysis results
        """
        query = f"{protocol} airdrop roadmap, eligibility criteria, and token distribution timeline"
        return self.pre_trade_research(query)
    
    def defi_vault_optimization(
        self,
        vault_name: str,
        strategies: List[str]
    ) -> Dict[str, Any]:
        """
        Research DeFi vault optimization strategies.
        
        Args:
            vault_name: Vault or protocol name (e.g., "GrokSwap")
            strategies: List of strategies to analyze
            
        Returns:
            Optimization analysis
        """
        strategy_list = ", ".join(strategies)
        query = f"{vault_name} vault optimization comparing {strategy_list}"
        return self.pre_trade_research(query)
    
    def save_research_summary(self, output_file: str = "research_summary.csv"):
        """
        Save all cached research to a CSV file.
        
        Args:
            output_file: Output CSV file path
        """
        if not self.results_cache:
            print("No research results to save")
            return
        
        df = self.research_to_dataframe(list(self.results_cache.keys()))
        df.to_csv(output_file, index=False)
        print(f"Research summary saved to: {output_file}")
    
    def _cache_key(self, query: str) -> str:
        """Generate cache key from query."""
        import hashlib
        return hashlib.md5(query.encode()).hexdigest()


def example_usage():
    """Example usage for backtesting integration."""
    print("Dexter Backtesting Integration Example\n")
    
    # Initialize
    backtest = DexterBacktest()
    
    # Example 1: Pre-trade research
    print("1. Pre-trade Research Example:")
    print("-" * 60)
    research = backtest.pre_trade_research(
        "Bitcoin price correlation with network hash rate in 2024"
    )
    print(f"Status: {research['status']}")
    print(f"Analysis preview: {research.get('analysis', 'N/A')[:200]}...\n")
    
    # Example 2: Batch protocol analysis
    print("2. Batch Crypto Analysis Example:")
    print("-" * 60)
    df = backtest.batch_crypto_analysis(
        protocols=["Uniswap", "PancakeSwap"],
        metrics=["volume", "fees"]
    )
    print(f"Generated {len(df)} research queries")
    print(df[['query', 'status']].to_string(index=False))
    print()
    
    # Example 3: Airdrop research
    print("3. Airdrop Research Example:")
    print("-" * 60)
    airdrop_info = backtest.airdrop_research("Jupiter")
    print(f"Status: {airdrop_info['status']}")
    print()
    
    # Example 4: Save summary
    print("4. Saving Research Summary:")
    print("-" * 60)
    backtest.save_research_summary("my_research.csv")
    

def main():
    """CLI interface for backtesting integration."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Dexter Backtesting Integration"
    )
    parser.add_argument(
        "--example",
        action="store_true",
        help="Run example usage"
    )
    parser.add_argument(
        "--protocol",
        help="Analyze specific protocol"
    )
    parser.add_argument(
        "--metrics",
        nargs="+",
        default=["liquidity", "volume"],
        help="Metrics to analyze"
    )
    
    args = parser.parse_args()
    
    if args.example:
        example_usage()
    elif args.protocol:
        backtest = DexterBacktest()
        df = backtest.batch_crypto_analysis(
            protocols=[args.protocol],
            metrics=args.metrics
        )
        print(df.to_string())
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
