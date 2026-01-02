# Market Trend Analysis System

A sophisticated market trend analysis system inspired by the **LeanAgent framework**, featuring a master and sub-agent architecture with lifelong learning capabilities and efficient multimodal data processing.

## 🎯 Overview

This system implements an intelligent multi-agent architecture for analyzing cryptocurrency and financial market trends. It combines:

- **Master/Sub-Agent Architecture**: Hierarchical decision-making with specialized agents
- **Lifelong Learning**: Continuous improvement through experience replay and adaptive strategies
- **Multimodal Data Processing**: Efficient handling of price, volume, sentiment, and technical data
- **Pattern Recognition**: Advanced trend detection and market pattern identification

## 🏗️ Architecture

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    Master Agent                         │
│  - Coordinates sub-agents                               │
│  - Aggregates results                                   │
│  - Builds consensus                                     │
└────────────┬────────────────────────────────────────────┘
             │
             ├─────────────┬─────────────┬─────────────┐
             ▼             ▼             ▼             ▼
      ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
      │  Price   │  │  Volume  │  │Sentiment │  │Technical │
      │  Agent   │  │  Agent   │  │  Agent   │  │  Agent   │
      └──────────┘  └──────────┘  └──────────┘  └──────────┘
             │             │             │             │
             └─────────────┴─────────────┴─────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    ▼                           ▼
            ┌───────────────┐          ┌────────────────┐
            │ Data Processor│          │ Trend Analyzer │
            │  - Normalize  │          │  - Patterns    │
            │  - Validate   │          │  - Signals     │
            └───────────────┘          └────────────────┘
                                              │
                                              ▼
                                   ┌──────────────────────┐
                                   │ Learning System      │
                                   │  - Experience Replay │
                                   │  - Adaptation        │
                                   │  - Memory Management │
                                   └──────────────────────┘
```

### Inspired by LeanAgent Framework

The design follows LeanAgent principles:

1. **Hierarchical Organization**: Master agent coordinates specialized sub-agents
2. **Efficiency**: Minimal resource usage through smart memory management
3. **Continuous Learning**: Lifelong learning with experience replay
4. **Modularity**: Each component is independent and replaceable

## 📦 Installation

The system is self-contained and requires only Python 3.7+:

```bash
# No additional dependencies required
# All modules use Python standard library
```

## 🚀 Quick Start

### Basic Usage

```python
from market_analysis import (
    MasterAgent, SubAgent,
    MultimodalDataProcessor,
    LifelongLearningSystem,
    TrendAnalyzer
)

# 1. Create master agent
master = MasterAgent('master_1')

# 2. Create and register sub-agents
price_agent = SubAgent('price_agent', 'price_analysis')
volume_agent = SubAgent('volume_agent', 'volume_analysis')
sentiment_agent = SubAgent('sentiment_agent', 'sentiment_analysis')

master.register_sub_agent(price_agent)
master.register_sub_agent(volume_agent)
master.register_sub_agent(sentiment_agent)

# 3. Initialize other components
data_processor = MultimodalDataProcessor()
learning_system = LifelongLearningSystem()
trend_analyzer = TrendAnalyzer()

# 4. Prepare market data
market_data = {
    'prices': [45000, 45200, 45500, 45800, 46000],
    'volumes': [1000, 1200, 1500, 1400, 1600],
    'sentiment_scores': [0.2, 0.3, 0.5, 0.6, 0.7]
}

# 5. Process data
processed_data = data_processor.process(market_data)

# 6. Get agent analysis
agent_results = master.process(market_data)

# 7. Analyze trends
trend_results = trend_analyzer.analyze(processed_data)

# 8. Store experience for learning
experience = {
    'state': processed_data,
    'action': {'type': 'analysis'},
    'outcome': 'success',
    'reward': 1.0,
    'success': True
}
learning_system.store_experience(experience)

# 9. Learn from experiences
learning_results = learning_system.learn_from_batch()
```

### Running the Example

```bash
python3 market_analysis_example.py
```

This demonstrates:
- System initialization
- Data processing
- Multi-agent coordination
- Trend analysis
- Learning from experiences
- Multiple cycle analysis

## 📊 Features

### 1. Master/Sub-Agent Architecture

**Master Agent**:
- Coordinates multiple specialized sub-agents
- Aggregates results from all agents
- Builds consensus from different perspectives
- Distributes tasks efficiently

**Sub-Agents**:
- Specialize in specific analysis areas (price, volume, sentiment)
- Develop expertise over time
- Provide confidence scores with results
- Learn from experiences in their domain

### 2. Multimodal Data Processing

Handles diverse data types:

```python
data = {
    'prices': [list of prices],           # Price data
    'volumes': [list of volumes],         # Volume data
    'sentiment_scores': [scores],         # Sentiment analysis
    'technical': {                        # Technical indicators
        'RSI': 65,
        'MACD': 150
    },
    'news': [news items]                  # News/events
}
```

Features:
- Automatic normalization
- Data validation
- Type-specific processing
- Error handling

### 3. Lifelong Learning System

**Experience Replay**:
- Stores experiences in memory
- Priority sampling for valuable experiences
- Batch learning from historical data

**Adaptive Learning**:
- Adjusts learning rate based on performance
- Pattern extraction from experiences
- Strategy updates based on outcomes

**Memory Management**:
- Configurable capacity limits
- Intelligent pruning of old experiences
- Preservation of valuable learning instances

### 4. Trend Analysis

**Capabilities**:
- Price trend detection (upward/downward/neutral)
- Volume pattern analysis
- Sentiment classification
- Pattern recognition (double bottom, consistent trends, etc.)
- Signal generation
- Actionable recommendations

**Output**:
```python
{
    'trends': {...},                    # Detected trends
    'signals': [...],                   # Trading signals
    'recommendations': [...],           # Action recommendations
    'patterns': [...],                  # Identified patterns
    'confidence': 0.85                  # Overall confidence
}
```

## 🔧 Configuration

### Default Configuration

```python
from market_analysis.config import get_config

# Use default configuration
config = get_config()
```

### Custom Configuration

```python
from market_analysis.config import get_config

custom_config = {
    'learning': {
        'memory_capacity': 5000,
        'learning_rate': 0.02
    },
    'trend_analyzer': {
        'trend_threshold': 0.03  # 3% change threshold
    }
}

config = get_config(custom_config)
```

### Predefined Configurations

```python
from market_analysis.config import (
    CONSERVATIVE_CONFIG,  # More cautious analysis
    AGGRESSIVE_CONFIG,    # More sensitive to changes
    MINIMAL_CONFIG       # Lightweight setup
)
```

## 📈 Use Cases

### 1. Bitcoin Market Analysis

```python
btc_data = {
    'prices': [65000, 65500, 66000, 65800, 66200],
    'volumes': [2000, 2200, 2500, 2300, 2600],
    'sentiment_scores': [0.6, 0.7, 0.8, 0.75, 0.85]
}

processed = data_processor.process(btc_data)
analysis = trend_analyzer.analyze(processed)

print(f"BTC Trend: {analysis['trends']['price']['direction']}")
print(f"Confidence: {analysis['confidence']:.2%}")
```

### 2. Multi-Cycle Learning

```python
# Analyze multiple market cycles
for cycle_data in historical_cycles:
    processed = data_processor.process(cycle_data)
    analysis = trend_analyzer.analyze(processed)
    
    # Store experience
    experience = {
        'state': processed,
        'action': {'prediction': analysis['trends']['price']['direction']},
        'outcome': cycle_data['actual_outcome'],
        'reward': calculate_reward(analysis, cycle_data),
        'success': was_correct(analysis, cycle_data)
    }
    learning_system.store_experience(experience)

# Learn from all cycles
learning_results = learning_system.learn_from_batch()
```

### 3. Real-time Monitoring

```python
import time

while True:
    # Get live market data
    market_data = fetch_live_data()
    
    # Process and analyze
    processed = data_processor.process(market_data)
    agent_results = master.process(market_data)
    trend_results = trend_analyzer.analyze(processed)
    
    # Act on recommendations
    for rec in trend_results['recommendations']:
        if rec['confidence'] > 0.7:
            handle_recommendation(rec)
    
    time.sleep(60)  # Check every minute
```

## 🧪 Testing

The system includes comprehensive testing capabilities:

```bash
# Run the example script
python3 market_analysis_example.py
```

The example demonstrates:
1. Single analysis cycle
2. Multi-cycle learning
3. Performance metrics
4. System status monitoring

## 📚 API Reference

### MasterAgent

```python
MasterAgent(agent_id: str, config: Dict = None)
```

**Methods**:
- `register_sub_agent(sub_agent)`: Register a sub-agent
- `process(data)`: Coordinate analysis across all sub-agents
- `learn(experience)`: Propagate learning to sub-agents
- `get_system_status()`: Get status of all agents

### SubAgent

```python
SubAgent(agent_id: str, specialty: str, config: Dict = None)
```

**Methods**:
- `process(data)`: Process data according to specialty
- `learn(experience)`: Learn from experience
- `get_state()`: Get agent state

### MultimodalDataProcessor

```python
MultimodalDataProcessor(config: Dict = None)
```

**Methods**:
- `process(raw_data)`: Process multimodal market data
- `batch_process(data_batch)`: Process multiple items
- `get_statistics()`: Get processing statistics

### LifelongLearningSystem

```python
LifelongLearningSystem(config: Dict = None)
```

**Methods**:
- `store_experience(experience)`: Store new experience
- `experience_replay(batch_size)`: Retrieve experience batch
- `learn_from_batch(batch)`: Learn from experiences
- `get_insights()`: Get learning insights
- `export_knowledge()`: Export learned knowledge
- `import_knowledge(knowledge)`: Import knowledge

### TrendAnalyzer

```python
TrendAnalyzer(config: Dict = None)
```

**Methods**:
- `analyze(processed_data)`: Analyze trends
- `get_summary(num_recent)`: Get analysis summary

## 🔒 Integration with Quantum Taproot Wallet

This market analysis system can be used alongside the quantum taproot wallet for:

1. **Optimal Timing**: Determine best times for transactions
2. **Fee Optimization**: Analyze network conditions for fee estimation
3. **Risk Assessment**: Evaluate market volatility before large transfers
4. **Strategic Planning**: Long-term holding vs spending decisions

Example integration:

```python
# Analyze market before executing wallet transaction
market_data = get_current_market_data()
processed = data_processor.process(market_data)
analysis = trend_analyzer.analyze(processed)

# Only execute high-value transaction if conditions are favorable
if analysis['trends']['price']['volatility'] == 'low':
    execute_wallet_transaction()
else:
    print("High volatility - consider waiting")
```

## 🤝 Contributing

This system is designed to be extensible. To add new capabilities:

1. **New Sub-Agent Types**: Create specialized agents for new analysis areas
2. **Additional Data Sources**: Extend MultimodalDataProcessor
3. **Custom Learning Strategies**: Modify LifelongLearningSystem
4. **New Pattern Detectors**: Add to TrendAnalyzer

## 📄 License

Same as the parent project (see LICENSE file).

## 🔗 References

- **LeanAgent Framework**: Inspiration for the architecture
- **Multi-Agent Systems**: Hierarchical decision-making patterns
- **Reinforcement Learning**: Experience replay and lifelong learning concepts
- **Technical Analysis**: Traditional market analysis techniques

## 📞 Support

For questions or issues related to the Market Trend Analysis System, please refer to the main project documentation or open an issue in the repository.
