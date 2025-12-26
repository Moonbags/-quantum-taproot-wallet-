#!/usr/bin/env python3
"""
Dexter Agent Wrapper

Provides a simplified interface to the Dexter autonomous financial analysis agent.
This wrapper assumes you have cloned the Dexter repository and set up API keys.

Prerequisites:
1. Clone Dexter: git clone https://github.com/virattt/dexter.git
2. Set up API keys in .env file (OPENAI_API_KEY, FINANCIAL_DATASETS_API_KEY)
3. Install dependencies: uv sync (from Dexter directory)

Usage:
    from dexter_integration.agent_wrapper import DexterAgent
    
    agent = DexterAgent(max_steps=20)
    result = agent.run("Analyze Bitcoin price trends for Q4 2024")
    print(result)
"""

import os
import sys
import json
from pathlib import Path
from typing import Optional, Dict, Any
from dotenv import load_dotenv


class DexterAgent:
    """
    Wrapper for Dexter autonomous financial analysis agent.
    
    This class provides a simplified interface to run financial analysis queries
    using the Dexter agent. It handles environment setup and provides both
    synchronous and asynchronous execution modes.
    """
    
    def __init__(
        self,
        dexter_path: Optional[str] = None,
        max_steps: int = 20,
        max_steps_per_task: int = 5,
        model: str = "gpt-4-turbo-preview"
    ):
        """
        Initialize the Dexter agent wrapper.
        
        Args:
            dexter_path: Path to Dexter repository. If None, looks for ../dexter
            max_steps: Maximum steps for the agent to take
            max_steps_per_task: Maximum steps per individual task (prevents loops)
            model: OpenAI model to use for analysis
        """
        # Load environment variables
        load_dotenv()
        
        # Validate API keys
        self.openai_key = os.getenv("OPENAI_API_KEY")
        self.financial_datasets_key = os.getenv("FINANCIAL_DATASETS_API_KEY")
        
        if not self.openai_key or not self.financial_datasets_key:
            raise ValueError(
                "Missing API keys. Please set OPENAI_API_KEY and "
                "FINANCIAL_DATASETS_API_KEY in .env file"
            )
        
        # Set configuration
        self.max_steps = max_steps
        self.max_steps_per_task = max_steps_per_task
        self.model = model
        
        # Determine Dexter path
        if dexter_path is None:
            # Look for Dexter in common locations
            candidates = [
                Path.home() / "dexter",
                Path("../dexter"),
                Path("../../dexter"),
            ]
            for candidate in candidates:
                if candidate.exists() and (candidate / "dexter").exists():
                    self.dexter_path = candidate
                    break
            else:
                self.dexter_path = None
        else:
            self.dexter_path = Path(dexter_path)
        
        if self.dexter_path and self.dexter_path.exists():
            # Add Dexter to Python path if found
            sys.path.insert(0, str(self.dexter_path))
    
    def run(self, query: str, output_file: Optional[str] = None) -> Dict[str, Any]:
        """
        Run a financial analysis query using Dexter.
        
        Args:
            query: The financial analysis question or task
            output_file: Optional file to save the results to
            
        Returns:
            Dict containing the analysis results
            
        Example:
            >>> agent = DexterAgent()
            >>> result = agent.run("Compare Tesla and Microsoft cash flow trends")
            >>> print(result['analysis'])
        """
        # Check if Dexter is available
        if not self.dexter_path or not self.dexter_path.exists():
            return {
                "status": "error",
                "message": (
                    "Dexter repository not found. Please clone it:\n"
                    "git clone https://github.com/virattt/dexter.git\n"
                    "Then set DEXTER_PATH environment variable or place it in ~/dexter"
                ),
                "query": query
            }
        
        try:
            # Try to import Dexter agent
            from dexter.agent import Agent
            
            # Create and run agent
            agent = Agent(max_steps=self.max_steps)
            result = agent.run(query)
            
            response = {
                "status": "success",
                "query": query,
                "analysis": result,
                "config": {
                    "max_steps": self.max_steps,
                    "max_steps_per_task": self.max_steps_per_task,
                    "model": self.model
                }
            }
            
            # Save to file if requested
            if output_file:
                with open(output_file, 'w') as f:
                    json.dump(response, f, indent=2)
            
            return response
            
        except ImportError as e:
            return {
                "status": "error",
                "message": f"Failed to import Dexter: {str(e)}. Make sure to run 'uv sync' in the Dexter directory.",
                "query": query
            }
        except Exception as e:
            return {
                "status": "error",
                "message": f"Error running Dexter: {str(e)}",
                "query": query
            }
    
    def run_batch(self, queries: list[str], output_dir: str = "dexter_output") -> list[Dict[str, Any]]:
        """
        Run multiple queries in batch mode.
        
        Args:
            queries: List of financial analysis questions
            output_dir: Directory to save individual results
            
        Returns:
            List of result dictionaries
        """
        os.makedirs(output_dir, exist_ok=True)
        results = []
        
        for i, query in enumerate(queries):
            print(f"Processing query {i+1}/{len(queries)}: {query[:50]}...")
            output_file = os.path.join(output_dir, f"analysis_{i+1}.json")
            result = self.run(query, output_file=output_file)
            results.append(result)
        
        # Save summary
        summary_file = os.path.join(output_dir, "batch_summary.json")
        with open(summary_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        return results


def main():
    """CLI interface for Dexter agent wrapper."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Dexter Financial Analysis Agent")
    parser.add_argument("query", nargs="?", help="Financial analysis query")
    parser.add_argument("--max-steps", type=int, default=20, help="Maximum agent steps")
    parser.add_argument("--output", "-o", help="Output file for results")
    parser.add_argument("--dexter-path", help="Path to Dexter repository")
    
    args = parser.parse_args()
    
    # Interactive mode if no query provided
    if not args.query:
        print("Dexter Financial Analysis Agent")
        print("Enter your query (or 'quit' to exit):")
        args.query = input("> ")
        if args.query.lower() in ['quit', 'exit', 'q']:
            return
    
    # Run analysis
    agent = DexterAgent(
        dexter_path=args.dexter_path,
        max_steps=args.max_steps
    )
    
    result = agent.run(args.query, output_file=args.output)
    
    if result["status"] == "success":
        print("\n" + "="*60)
        print("ANALYSIS RESULTS")
        print("="*60)
        print(result["analysis"])
        if args.output:
            print(f"\nResults saved to: {args.output}")
    else:
        print(f"\nError: {result['message']}")


if __name__ == "__main__":
    main()
