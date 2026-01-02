#!/usr/bin/env python3
"""
Market Trend Analysis System - Example Usage
Demonstrates the LeanAgent-inspired architecture for market analysis
"""

import json
from datetime import datetime
from market_analysis import (
    MasterAgent, SubAgent, 
    MultimodalDataProcessor,
    LifelongLearningSystem,
    TrendAnalyzer
)
from market_analysis.config import get_config, DEFAULT_CONFIG


def create_sample_market_data():
    """Create sample market data for demonstration"""
    return {
        'prices': [45000, 45200, 45500, 45800, 46000],
        'volumes': [1000, 1200, 1500, 1400, 1600],
        'sentiment_scores': [0.2, 0.3, 0.5, 0.6, 0.7],
        'technical': {
            'RSI': 65,
            'MACD': 150,
            'SMA_20': 45400
        },
        'news': [
            {
                'headline': 'Positive market outlook',
                'impact': 'high',
                'sentiment': 0.8
            }
        ]
    }


def setup_system(config=None):
    """
    Setup the complete market analysis system
    
    Args:
        config: Optional configuration dictionary
        
    Returns:
        Tuple of (master_agent, data_processor, learning_system, trend_analyzer)
    """
    # Get configuration
    system_config = get_config(config)
    
    # Initialize components
    print("Initializing Market Trend Analysis System...")
    print("=" * 60)
    
    # Create master agent
    master = MasterAgent('master_agent_1', system_config.get('agents', {}))
    print(f"✓ Created Master Agent: {master.agent_id}")
    
    # Create and register sub-agents
    agent_configs = system_config.get('agents', {}).get('sub_agents', [])
    for agent_config in agent_configs:
        if agent_config.get('enabled', True):
            sub_agent = SubAgent(
                agent_config['id'],
                agent_config['specialty'],
                agent_config
            )
            master.register_sub_agent(sub_agent)
            print(f"✓ Registered Sub-Agent: {sub_agent.agent_id} ({sub_agent.specialty})")
    
    # Create data processor
    data_processor = MultimodalDataProcessor(system_config.get('data_processor', {}))
    print(f"✓ Initialized Data Processor")
    
    # Create learning system
    learning_system = LifelongLearningSystem(system_config.get('learning', {}))
    print(f"✓ Initialized Lifelong Learning System")
    
    # Create trend analyzer
    trend_analyzer = TrendAnalyzer(system_config.get('trend_analyzer', {}))
    print(f"✓ Initialized Trend Analyzer")
    
    print("=" * 60)
    print("System initialization complete!\n")
    
    return master, data_processor, learning_system, trend_analyzer


def run_analysis_example():
    """Run a complete analysis example"""
    print("\n" + "=" * 60)
    print("MARKET TREND ANALYSIS SYSTEM - DEMONSTRATION")
    print("=" * 60 + "\n")
    
    # Setup system
    master, data_processor, learning_system, trend_analyzer = setup_system()
    
    # Generate sample market data
    print("\n1. Processing Market Data")
    print("-" * 60)
    raw_data = create_sample_market_data()
    print(f"Raw data includes: {', '.join(raw_data.keys())}")
    
    # Process data
    processed_data = data_processor.process(raw_data)
    print(f"✓ Processed {len(processed_data['data_types_present'])} data types")
    print(f"  Data types: {', '.join(processed_data['data_types_present'])}")
    print(f"  Validation: {processed_data['validation']['is_valid']}")
    
    # Master agent coordinates analysis
    print("\n2. Master Agent Coordination")
    print("-" * 60)
    agent_results = master.process(raw_data)
    print(f"✓ Coordinated {agent_results['sub_agent_count']} sub-agents")
    print(f"  Overall trend: {agent_results['consensus']['overall_trend']}")
    print(f"  Consensus confidence: {agent_results['consensus']['confidence']:.2%}")
    
    # Analyze trends
    print("\n3. Trend Analysis")
    print("-" * 60)
    trend_results = trend_analyzer.analyze(processed_data)
    print(f"✓ Analyzed trends from {len(trend_results['trends'])} data sources")
    print(f"  Overall confidence: {trend_results['confidence']:.2%}")
    
    if trend_results['signals']:
        print(f"\n  Signals detected:")
        for signal in trend_results['signals']:
            print(f"    - {signal['type']}: {signal['direction']} (strength: {signal['strength']:.2f})")
    
    if trend_results['recommendations']:
        print(f"\n  Recommendations:")
        for rec in trend_results['recommendations']:
            print(f"    - {rec['action']}: {rec['reason']}")
            print(f"      Confidence: {rec['confidence']:.2%}")
    
    if trend_results['patterns']:
        print(f"\n  Patterns detected:")
        for pattern in trend_results['patterns']:
            print(f"    - {pattern['type']}: {pattern['description']}")
    
    # Store learning experience
    print("\n4. Lifelong Learning")
    print("-" * 60)
    experience = {
        'state': processed_data,
        'action': {
            'type': 'trend_analysis',
            'recommendations': trend_results['recommendations']
        },
        'outcome': 'simulated_success',
        'reward': 1.0,
        'success': True
    }
    learning_system.store_experience(experience)
    print(f"✓ Stored experience in learning system")
    print(f"  Total experiences: {learning_system.performance_metrics['total_experiences']}")
    print(f"  Current accuracy: {learning_system.performance_metrics['accuracy']:.2%}")
    
    # Perform learning
    learning_results = learning_system.learn_from_batch()
    print(f"✓ Performed learning from {learning_results['batch_size']} experiences")
    print(f"  Learning updates made: {learning_results['learning_updates']}")
    
    # Get insights
    print("\n5. System Insights")
    print("-" * 60)
    insights = learning_system.get_insights()
    print(f"Learning rate: {insights['learning_rate']:.4f}")
    print(f"Adaptation factor: {insights['adaptation_factor']:.2f}")
    print(f"Memory usage: {insights['memory_usage']}/{insights['memory_capacity']}")
    
    # System status
    print("\n6. System Status")
    print("-" * 60)
    status = master.get_system_status()
    print(f"Master agent state: {status['master_agent']['state']}")
    print(f"Active sub-agents: {len(status['sub_agents'])}")
    for agent_id, agent_state in status['sub_agents'].items():
        print(f"  - {agent_id}: {agent_state['state']} (memory: {agent_state['memory_size']})")
    
    # Display final summary
    print("\n" + "=" * 60)
    print("ANALYSIS COMPLETE")
    print("=" * 60)
    print("\nKey Findings:")
    print(f"  • Overall market trend: {agent_results['consensus']['overall_trend']}")
    print(f"  • Analysis confidence: {trend_results['confidence']:.2%}")
    print(f"  • Signals detected: {len(trend_results['signals'])}")
    print(f"  • Recommendations: {len(trend_results['recommendations'])}")
    print(f"  • System learning accuracy: {learning_system.performance_metrics['accuracy']:.2%}")
    print()


def run_multiple_cycles_example():
    """Demonstrate multiple analysis cycles with learning"""
    print("\n" + "=" * 60)
    print("MULTIPLE CYCLE DEMONSTRATION")
    print("=" * 60 + "\n")
    
    # Setup system
    master, data_processor, learning_system, trend_analyzer = setup_system()
    
    # Simulate multiple market cycles
    cycles = [
        {
            'name': 'Bullish Cycle',
            'data': {
                'prices': [45000, 46000, 47000, 48000, 49000],
                'volumes': [1000, 1200, 1500, 1800, 2000],
                'sentiment_scores': [0.5, 0.6, 0.7, 0.8, 0.9]
            },
            'expected_outcome': 'bullish'
        },
        {
            'name': 'Bearish Cycle',
            'data': {
                'prices': [49000, 48000, 47000, 46000, 45000],
                'volumes': [2000, 1800, 1500, 1200, 1000],
                'sentiment_scores': [-0.5, -0.6, -0.7, -0.8, -0.9]
            },
            'expected_outcome': 'bearish'
        },
        {
            'name': 'Neutral Cycle',
            'data': {
                'prices': [45000, 45100, 45000, 45050, 45000],
                'volumes': [1000, 1000, 1000, 1000, 1000],
                'sentiment_scores': [0.0, 0.1, -0.1, 0.0, 0.0]
            },
            'expected_outcome': 'neutral'
        }
    ]
    
    for i, cycle in enumerate(cycles, 1):
        print(f"\nCycle {i}: {cycle['name']}")
        print("-" * 60)
        
        # Process data
        processed = data_processor.process(cycle['data'])
        
        # Get agent analysis
        agent_results = master.process(cycle['data'])
        trend = agent_results['consensus']['overall_trend']
        
        # Analyze
        analysis = trend_analyzer.analyze(processed)
        
        # Determine if prediction was correct
        success = trend == cycle['expected_outcome']
        reward = 1.0 if success else -0.5
        
        # Store experience
        experience = {
            'state': processed,
            'action': {'type': 'prediction', 'predicted': trend},
            'outcome': cycle['expected_outcome'],
            'reward': reward,
            'success': success
        }
        learning_system.store_experience(experience)
        
        print(f"  Predicted: {trend}")
        print(f"  Expected: {cycle['expected_outcome']}")
        print(f"  Result: {'✓ Correct' if success else '✗ Incorrect'}")
        print(f"  Reward: {reward}")
    
    # Perform learning
    print("\nLearning from experiences...")
    print("-" * 60)
    learning_results = learning_system.learn_from_batch()
    
    print(f"Batch size: {learning_results['batch_size']}")
    print(f"Learning updates: {learning_results['learning_updates']}")
    
    # Show insights
    insights = learning_system.get_insights()
    print(f"\nFinal Performance:")
    print(f"  Total experiences: {insights['performance_metrics']['total_experiences']}")
    print(f"  Successful: {insights['performance_metrics']['successful_predictions']}")
    print(f"  Failed: {insights['performance_metrics']['failed_predictions']}")
    print(f"  Accuracy: {insights['performance_metrics']['accuracy']:.2%}")
    
    print("\n" + "=" * 60 + "\n")


if __name__ == '__main__':
    # Run basic example
    run_analysis_example()
    
    # Run multiple cycles example
    run_multiple_cycles_example()
    
    print("All demonstrations complete!")
