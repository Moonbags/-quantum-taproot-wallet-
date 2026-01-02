"""
Master Agent for Market Trend Analysis System.
Orchestrates sub-agents and manages the knowledge graph using SSSP algorithm.
"""

from typing import List, Dict, Any, Optional
import logging
from datetime import datetime

from ..utils.sssp import KnowledgeGraph
from ..config import config


logger = logging.getLogger(__name__)


class MasterAgent:
    """
    Master agent that orchestrates market trend analysis.
    
    Responsibilities:
    - Build and maintain knowledge graph
    - Use SSSP to prioritize data sources
    - Delegate tasks to sub-agents
    - Aggregate insights and make decisions
    """
    
    def __init__(self, use_grok: bool = None):
        """
        Initialize the master agent.
        
        Args:
            use_grok: Whether to use Grok API for reasoning. 
                     If None, uses config.is_grok_enabled()
        """
        self.knowledge_graph = KnowledgeGraph()
        self.use_grok = use_grok if use_grok is not None else config.is_grok_enabled()
        self.insights_cache = []
        
        logger.info("Master Agent initialized")
        if self.use_grok:
            logger.info("Grok API integration enabled")
        else:
            logger.warning("Grok API not configured - using basic reasoning")
    
    def build_knowledge_graph(self, market_data: Dict[str, Any]) -> None:
        """
        Build knowledge graph from market data.
        
        Args:
            market_data: Dictionary containing various market data sources
        """
        logger.info("Building knowledge graph from market data")
        
        # Add root node for the analysis target
        target = market_data.get('target', 'market_analysis')
        self.knowledge_graph.add_node(
            target,
            node_type='root',
            metadata={'timestamp': datetime.now().isoformat()}
        )
        
        # Add stock data nodes
        if 'stocks' in market_data:
            for stock in market_data['stocks']:
                node_id = f"stock_{stock['symbol']}"
                self.knowledge_graph.add_node(
                    node_id,
                    node_type='stock',
                    metadata=stock
                )
                # Connect to root with weight based on relevance
                weight = stock.get('weight', 1.0)
                self.knowledge_graph.add_edge(target, node_id, weight)
        
        # Add news data nodes
        if 'news' in market_data:
            for idx, news_item in enumerate(market_data['news']):
                node_id = f"news_{idx}"
                self.knowledge_graph.add_node(
                    node_id,
                    node_type='news',
                    metadata=news_item
                )
                weight = news_item.get('weight', 1.5)
                self.knowledge_graph.add_edge(target, node_id, weight)
                
                # Connect news to related stocks
                if 'related_stocks' in news_item:
                    for symbol in news_item['related_stocks']:
                        stock_node = f"stock_{symbol}"
                        if stock_node in self.knowledge_graph.graph:
                            self.knowledge_graph.add_edge(
                                node_id, 
                                stock_node, 
                                weight=0.5,
                                relationship='mentions'
                            )
        
        # Add chart/image nodes
        if 'charts' in market_data:
            for idx, chart in enumerate(market_data['charts']):
                node_id = f"chart_{idx}"
                self.knowledge_graph.add_node(
                    node_id,
                    node_type='chart',
                    metadata=chart
                )
                weight = chart.get('weight', 2.0)
                self.knowledge_graph.add_edge(target, node_id, weight)
        
        # Add video nodes
        if 'videos' in market_data:
            for idx, video in enumerate(market_data['videos']):
                node_id = f"video_{idx}"
                self.knowledge_graph.add_node(
                    node_id,
                    node_type='video',
                    metadata=video
                )
                weight = video.get('weight', 3.0)
                self.knowledge_graph.add_edge(target, node_id, weight)
        
        logger.info(f"Knowledge graph built with {self.knowledge_graph.graph.number_of_nodes()} nodes")
    
    def prioritize_data_sources(
        self, 
        source_node: str = None,
        threshold: float = None
    ) -> List[tuple]:
        """
        Use SSSP to prioritize data sources for processing.
        
        Args:
            source_node: Starting node (default: root node)
            threshold: Priority threshold (uses config if not provided)
            
        Returns:
            List of (node_id, priority_score) tuples
        """
        if source_node is None:
            # Find root node
            root_nodes = [
                n for n, data in self.knowledge_graph.node_metadata.items()
                if data.get('type') == 'root'
            ]
            source_node = root_nodes[0] if root_nodes else list(self.knowledge_graph.graph.nodes())[0]
        
        if threshold is None:
            threshold = config.SSSP_PRIORITY_THRESHOLD
        
        logger.info(f"Computing SSSP from node: {source_node}")
        priorities = self.knowledge_graph.get_priority_nodes(
            source_node,
            threshold=threshold,
            max_nodes=config.MAX_GRAPH_DEPTH * 3
        )
        
        logger.info(f"Identified {len(priorities)} high-priority nodes")
        return priorities
    
    def delegate_to_sub_agents(self, prioritized_nodes: List[tuple]) -> Dict[str, List[Any]]:
        """
        Delegate tasks to appropriate sub-agents based on node types.
        
        Args:
            prioritized_nodes: List of (node_id, priority_score) tuples
            
        Returns:
            Dictionary mapping sub-agent types to their assigned tasks
        """
        tasks = {
            'text_agent': [],
            'vision_agent': [],
            'video_agent': []
        }
        
        for node_id, priority in prioritized_nodes:
            node_info = self.knowledge_graph.get_node_info(node_id)
            node_type = node_info['type']
            
            if node_type in ['news', 'stock']:
                tasks['text_agent'].append({
                    'node_id': node_id,
                    'priority': priority,
                    'metadata': node_info['metadata']
                })
            elif node_type == 'chart':
                tasks['vision_agent'].append({
                    'node_id': node_id,
                    'priority': priority,
                    'metadata': node_info['metadata']
                })
            elif node_type == 'video':
                tasks['video_agent'].append({
                    'node_id': node_id,
                    'priority': priority,
                    'metadata': node_info['metadata']
                })
        
        logger.info(f"Delegated tasks: Text={len(tasks['text_agent'])}, "
                   f"Vision={len(tasks['vision_agent'])}, "
                   f"Video={len(tasks['video_agent'])}")
        
        return tasks
    
    def aggregate_insights(self, sub_agent_results: Dict[str, List[Dict]]) -> Dict[str, Any]:
        """
        Aggregate insights from all sub-agents.
        
        Args:
            sub_agent_results: Results from all sub-agents
            
        Returns:
            Aggregated insights and recommendations
        """
        aggregated = {
            'timestamp': datetime.now().isoformat(),
            'insights': [],
            'recommendations': [],
            'confidence_score': 0.0
        }
        
        total_insights = 0
        total_confidence = 0.0
        
        for agent_type, results in sub_agent_results.items():
            for result in results:
                if 'insights' in result:
                    aggregated['insights'].extend(result['insights'])
                    total_insights += len(result['insights'])
                
                if 'confidence' in result:
                    total_confidence += result['confidence']
        
        # Calculate average confidence
        if total_insights > 0:
            aggregated['confidence_score'] = total_confidence / total_insights
        
        # Store in cache for lifelong learning
        self.insights_cache.append(aggregated)
        
        logger.info(f"Aggregated {total_insights} insights with confidence {aggregated['confidence_score']:.2f}")
        
        return aggregated
    
    def analyze_market(self, market_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Main method to analyze market trends.
        
        Args:
            market_data: Dictionary containing market data from various sources
            
        Returns:
            Analysis results with insights and recommendations
        """
        logger.info("Starting market trend analysis")
        
        # Build knowledge graph
        self.build_knowledge_graph(market_data)
        
        # Prioritize data sources using SSSP
        priorities = self.prioritize_data_sources()
        
        # Delegate to sub-agents
        tasks = self.delegate_to_sub_agents(priorities)
        
        # For now, return the delegation structure
        # In a full implementation, this would wait for sub-agent results
        result = {
            'status': 'analysis_complete',
            'timestamp': datetime.now().isoformat(),
            'graph_stats': {
                'nodes': self.knowledge_graph.graph.number_of_nodes(),
                'edges': self.knowledge_graph.graph.number_of_edges()
            },
            'prioritized_nodes': len(priorities),
            'delegated_tasks': {k: len(v) for k, v in tasks.items()},
            'tasks': tasks
        }
        
        logger.info("Market trend analysis complete")
        return result
