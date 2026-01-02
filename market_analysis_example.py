#!/usr/bin/env python3
"""
Example usage of the Market Trend Analysis System.

This script demonstrates how to use the master and sub-agent architecture
to analyze market trends using SSSP algorithm for prioritization.
"""

import logging
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from market_analysis import (
    MasterAgent,
    TextAgent,
    VisionAgent,
    VideoAgent,
    MarketDataProcessor,
    LifelongLearning,
    config
)


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def main():
    """Run market trend analysis example."""
    
    print("=" * 70)
    print("Market Trend Analysis System - Example")
    print("Inspired by LeanAgent Framework (arXiv:2504.17033v2)")
    print("=" * 70)
    print()
    
    # Check configuration
    print("Checking configuration...")
    print(f"  - Grok API: {'Enabled' if config.is_grok_enabled() else 'Disabled (using basic reasoning)'}")
    print(f"  - Pinecone: {'Enabled' if config.is_pinecone_enabled() else 'Disabled (using in-memory storage)'}")
    print()
    
    # Define stocks to analyze
    symbols = ['AAPL', 'MSFT', 'GOOGL']
    print(f"Analyzing stocks: {', '.join(symbols)}")
    print()
    
    # Step 1: Fetch market data
    print("Step 1: Fetching market data...")
    data_processor = MarketDataProcessor()
    
    # Use sample data for demonstration (set to False to use real APIs)
    market_data = data_processor.aggregate_market_data(
        symbols=symbols,
        news_query='technology stocks',
        use_sample=True  # Set to False to use real API data
    )
    
    print(f"  - Collected {len(market_data['stocks'])} stock data points")
    print(f"  - Collected {len(market_data['news'])} news articles")
    print(f"  - Collected {len(market_data['charts'])} charts")
    print(f"  - Collected {len(market_data['videos'])} videos")
    print()
    
    # Step 2: Initialize master agent
    print("Step 2: Initializing Master Agent...")
    master_agent = MasterAgent()
    print()
    
    # Step 3: Build knowledge graph and run analysis
    print("Step 3: Running market analysis with SSSP prioritization...")
    analysis_result = master_agent.analyze_market(market_data)
    
    print(f"  - Knowledge graph: {analysis_result['graph_stats']['nodes']} nodes, "
          f"{analysis_result['graph_stats']['edges']} edges")
    print(f"  - Prioritized nodes: {analysis_result['prioritized_nodes']}")
    print()
    
    # Step 4: Display task delegation
    print("Step 4: Task delegation to sub-agents:")
    delegated = analysis_result['delegated_tasks']
    print(f"  - Text Agent: {delegated['text_agent']} tasks")
    print(f"  - Vision Agent: {delegated['vision_agent']} tasks")
    print(f"  - Video Agent: {delegated['video_agent']} tasks")
    print()
    
    # Step 5: Execute sub-agents
    print("Step 5: Executing sub-agents...")
    
    text_agent = TextAgent()
    vision_agent = VisionAgent()
    video_agent = VideoAgent()
    
    results = {}
    
    if analysis_result['tasks']['text_agent']:
        results['text_agent'] = text_agent.process_tasks(
            analysis_result['tasks']['text_agent']
        )
        print(f"  - Text Agent processed {len(results['text_agent'])} tasks")
    
    if analysis_result['tasks']['vision_agent']:
        results['vision_agent'] = vision_agent.process_tasks(
            analysis_result['tasks']['vision_agent']
        )
        print(f"  - Vision Agent processed {len(results['vision_agent'])} tasks")
    
    if analysis_result['tasks']['video_agent']:
        results['video_agent'] = video_agent.process_tasks(
            analysis_result['tasks']['video_agent']
        )
        print(f"  - Video Agent processed {len(results['video_agent'])} tasks")
    
    print()
    
    # Step 6: Aggregate insights
    print("Step 6: Aggregating insights...")
    aggregated = master_agent.aggregate_insights(results)
    print(f"  - Total insights: {len(aggregated['insights'])}")
    print(f"  - Confidence score: {aggregated['confidence_score']:.2f}")
    print()
    
    # Step 7: Display insights
    print("Step 7: Analysis Insights:")
    for i, insight in enumerate(aggregated['insights'][:5], 1):  # Show first 5
        print(f"  {i}. [{insight['type']}] {insight['summary']}")
    
    if len(aggregated['insights']) > 5:
        print(f"  ... and {len(aggregated['insights']) - 5} more insights")
    print()
    
    # Step 8: Lifelong learning
    print("Step 8: Storing insights for lifelong learning...")
    learning = LifelongLearning()
    
    for insight in aggregated['insights']:
        learning.store_insight(insight)
    
    stats = learning.get_learning_stats()
    print(f"  - Storage type: {stats['storage_type']}")
    print(f"  - Total stored insights: {stats['total_insights']}")
    print()
    
    # Step 9: Knowledge graph visualization
    print("Step 9: Knowledge Graph Structure:")
    print(master_agent.knowledge_graph.visualize_graph())
    print()
    
    print("=" * 70)
    print("Analysis Complete!")
    print("=" * 70)
    print()
    print("Next steps:")
    print("  1. Configure API keys in .env file for real data")
    print("  2. Enable Grok API for advanced reasoning")
    print("  3. Set up Pinecone for persistent lifelong learning")
    print("  4. Customize agents for your specific use case")
    print()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nAnalysis interrupted by user.")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Error running analysis: {e}", exc_info=True)
        sys.exit(1)
