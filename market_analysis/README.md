# Market Trend Analysis System

A lightweight AI system for analyzing market trends using a master and sub-agent architecture, inspired by the LeanAgent framework's SSSP (Single-Source Shortest Path) approach (arXiv:2504.17033v2). Powered by Grok from xAI, it processes multimodal data (text, images, videos) to deliver insights efficiently.

## Overview

The Market Trend Analysis System uses an innovative agent-based architecture to analyze financial markets. It combines:

- **SSSP Algorithm**: Dijkstra's algorithm to navigate knowledge graphs and prioritize high-impact data
- **Master-Sub Agent Pattern**: Orchestration through specialized agents
- **Lifelong Learning**: Vector database storage for continuous improvement
- **Multimodal Processing**: Text, image, and video analysis capabilities

## Architecture

### Master Agent
- Builds knowledge graph from market data
- Runs SSSP (Dijkstra's algorithm) to prioritize data sources
- Delegates tasks to specialized sub-agents
- Aggregates insights and generates recommendations
- Uses Grok API for advanced reasoning (optional)

### Sub-Agents

1. **Text Agent**: Processes news articles and text reports
   - Fetches news via NewsAPI
   - Performs sentiment analysis
   - Extracts key insights from text

2. **Vision Agent**: Analyzes charts and images
   - Processes price charts
   - Detects patterns and trends
   - Analyzes visual market indicators

3. **Video Agent**: Processes video content
   - Analyzes earnings calls
   - Extracts key moments from presentations
   - Processes video transcripts

### Lifelong Learning Module
- Stores insights in Pinecone vector database
- Enables retrieval of similar past analyses
- Supports continuous improvement over time
- Falls back to in-memory storage if Pinecone not configured

## Prerequisites

- **Python**: 3.8 or higher
- **Libraries**: See `requirements.txt`
- **API Keys** (optional but recommended):
  - [Alpha Vantage](https://www.alphavantage.co/support/#api-key) - Stock market data
  - [NewsAPI](https://newsapi.org/register) - News articles
  - [xAI Grok API](https://x.ai/) - Advanced reasoning (contact xAI for access)
  - [Pinecone](https://www.pinecone.io/) - Vector database for lifelong learning

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Moonbags/-quantum-taproot-wallet-.git
cd -quantum-taproot-wallet-
```

### 2. Install Dependencies

```bash
cd market_analysis
pip install -r requirements.txt
```

### 3. Configure API Keys

Copy the example environment file and add your API keys:

```bash
cp .env.example .env
```

Edit `.env` and add your API keys:

```env
ALPHA_VANTAGE_API_KEY=your_api_key_here
NEWS_API_KEY=your_api_key_here
GROK_API_KEY=your_api_key_here
PINECONE_API_KEY=your_api_key_here
PINECONE_ENVIRONMENT=your_environment_here
```

**Note**: The system works with sample data if API keys are not configured, making it easy to test without requiring immediate API access.

## Quick Start

### Basic Usage

Run the example script to see the system in action:

```bash
python market_analysis_example.py
```

This demonstrates:
- Building a knowledge graph from market data
- Using SSSP to prioritize data sources
- Delegating tasks to sub-agents
- Aggregating insights
- Storing results for lifelong learning

### Using in Your Code

```python
from market_analysis import (
    MasterAgent,
    MarketDataProcessor,
    TextAgent,
    VisionAgent,
    VideoAgent
)

# Initialize components
master_agent = MasterAgent()
data_processor = MarketDataProcessor()

# Fetch market data
market_data = data_processor.aggregate_market_data(
    symbols=['AAPL', 'MSFT'],
    news_query='technology stocks'
)

# Run analysis
result = master_agent.analyze_market(market_data)

# Process with sub-agents
text_agent = TextAgent()
vision_agent = VisionAgent()

# Execute tasks
text_results = text_agent.process_tasks(result['tasks']['text_agent'])
vision_results = vision_agent.process_tasks(result['tasks']['vision_agent'])

# Aggregate insights
insights = master_agent.aggregate_insights({
    'text_agent': text_results,
    'vision_agent': vision_results
})
```

## Features

### 1. SSSP-Based Prioritization

The system uses Dijkstra's Single-Source Shortest Path algorithm to navigate the knowledge graph and identify the most relevant data sources:

```python
# Build knowledge graph
master_agent.build_knowledge_graph(market_data)

# Get prioritized nodes
priorities = master_agent.prioritize_data_sources(threshold=0.7)

# Higher priority = more relevant to analysis
for node_id, priority_score in priorities:
    print(f"{node_id}: {priority_score:.2f}")
```

### 2. Knowledge Graph

The knowledge graph connects different data sources based on relationships:

- Stock data → News articles → Charts → Videos
- Weighted edges represent relevance
- SSSP finds optimal paths through the graph

```python
from market_analysis.utils import KnowledgeGraph

graph = KnowledgeGraph()
graph.add_node('stock_AAPL', 'stock', {'price': 150.0})
graph.add_node('news_1', 'news', {'title': 'Apple earnings...'})
graph.add_edge('stock_AAPL', 'news_1', weight=0.5)

# Compute shortest paths
distances = graph.compute_sssp('stock_AAPL')
```

### 3. Lifelong Learning

Store and retrieve insights for continuous improvement:

```python
from market_analysis.utils import LifelongLearning

learning = LifelongLearning()

# Store insight
insight_id = learning.store_insight({
    'type': 'sentiment',
    'summary': 'Positive market sentiment detected',
    'confidence': 0.85
})

# Retrieve similar insights
similar = learning.retrieve_similar_insights(
    'market sentiment analysis',
    top_k=5
)
```

### 4. Multimodal Data Processing

Process different types of market data:

```python
# Text processing
text_agent = TextAgent()
news_articles = text_agent.fetch_news('AAPL stock')

# Vision processing
vision_agent = VisionAgent()
chart_analysis = vision_agent.analyze_chart(chart_data)

# Video processing
video_agent = VideoAgent()
video_insights = video_agent.analyze_video(earnings_call)
```

## Configuration

### Environment Variables

The system is configured via environment variables in `.env`:

| Variable | Description | Required |
|----------|-------------|----------|
| `ALPHA_VANTAGE_API_KEY` | Stock data API key | Optional* |
| `NEWS_API_KEY` | News articles API key | Optional* |
| `GROK_API_KEY` | xAI Grok API key | Optional |
| `PINECONE_API_KEY` | Vector database API key | Optional |
| `MAX_GRAPH_DEPTH` | Maximum graph traversal depth | No (default: 5) |
| `SSSP_PRIORITY_THRESHOLD` | Priority threshold (0-1) | No (default: 0.7) |

\* System works with sample data if not provided

### Algorithm Parameters

Adjust SSSP and analysis parameters:

```python
from market_analysis import config

# Modify in .env file or programmatically
config.MAX_GRAPH_DEPTH = 10
config.SSSP_PRIORITY_THRESHOLD = 0.8
```

## Project Structure

```
market_analysis/
├── __init__.py                 # Main package exports
├── config.py                   # Configuration management
├── requirements.txt            # Python dependencies
├── .env.example               # Environment template
│
├── agents/                    # Agent modules
│   ├── __init__.py
│   ├── master_agent.py       # Master orchestrator
│   ├── text_agent.py         # Text processing
│   ├── vision_agent.py       # Image/chart processing
│   └── video_agent.py        # Video processing
│
├── utils/                     # Utility modules
│   ├── __init__.py
│   ├── sssp.py               # SSSP algorithm & knowledge graph
│   └── lifelong_learning.py  # Vector database integration
│
└── data_processing/           # Data fetching modules
    ├── __init__.py
    └── market_data.py        # Market data aggregation
```

## API Integration

### Alpha Vantage (Stock Data)

```python
from market_analysis.data_processing import MarketDataProcessor

processor = MarketDataProcessor()
stock_data = processor.fetch_stock_data('AAPL')
print(f"Price: ${stock_data['price']}")
```

### NewsAPI (News Articles)

```python
from market_analysis.agents import TextAgent

text_agent = TextAgent()
articles = text_agent.fetch_news('Tesla stock', max_results=5)
```

### Grok API (Advanced Reasoning)

When configured, the master agent uses Grok for enhanced analysis:

```python
master_agent = MasterAgent(use_grok=True)
# Grok will be used for advanced reasoning tasks
```

### Pinecone (Vector Database)

Store insights persistently:

```python
learning = LifelongLearning(use_pinecone=True)
learning.store_insight(insight)
```

## Examples

### Example 1: Single Stock Analysis

```python
from market_analysis import MasterAgent, MarketDataProcessor

# Analyze Apple stock
processor = MarketDataProcessor()
data = processor.aggregate_market_data(['AAPL'])

master = MasterAgent()
result = master.analyze_market(data)
print(f"Analysis complete: {result['status']}")
```

### Example 2: Sector Analysis

```python
# Analyze tech sector
tech_stocks = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META']
data = processor.aggregate_market_data(
    symbols=tech_stocks,
    news_query='technology sector trends'
)

result = master.analyze_market(data)
```

### Example 3: Custom Priority Threshold

```python
# Use higher threshold for more selective analysis
master = MasterAgent()
master.build_knowledge_graph(data)
priorities = master.prioritize_data_sources(threshold=0.9)
```

## Troubleshooting

### Common Issues

**1. Import errors**
```bash
# Ensure you're in the correct directory
cd /path/to/-quantum-taproot-wallet-
python market_analysis_example.py
```

**2. API rate limits**
- Alpha Vantage: 5 requests/minute (free tier)
- NewsAPI: 100 requests/day (free tier)
- Solution: Use sample data mode or upgrade API tier

**3. Pinecone connection issues**
- Check API key and environment in `.env`
- System automatically falls back to in-memory storage

## Advanced Usage

### Custom Sub-Agents

Create specialized agents for your needs:

```python
from market_analysis.agents.text_agent import TextAgent

class CustomTextAgent(TextAgent):
    def analyze_sentiment(self, text):
        # Your custom sentiment analysis
        return custom_analysis(text)
```

### Custom Data Sources

Extend the market data processor:

```python
from market_analysis.data_processing import MarketDataProcessor

class CustomDataProcessor(MarketDataProcessor):
    def fetch_custom_data(self, params):
        # Fetch from your custom API
        return custom_data
```

## Contributing

This is part of the Quantum Taproot Wallet project. Contributions are welcome!

## License

See the main repository LICENSE file.

## References

- LeanAgent Framework: arXiv:2504.17033v2
- Dijkstra's Algorithm: Single-Source Shortest Path
- xAI Grok: https://x.ai/

## Support

For issues specific to the Market Trend Analysis System, please check:
1. Ensure all dependencies are installed
2. Verify API keys in `.env` file
3. Check logs for detailed error messages
4. Try sample data mode first

For general repository issues, see the main README.
