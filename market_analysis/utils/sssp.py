"""
SSSP (Single-Source Shortest Path) implementation using Dijkstra's algorithm.
Inspired by LeanAgent framework (arXiv:2504.17033v2).

This module implements efficient path finding in knowledge graphs to prioritize
high-impact data for market trend analysis.
"""

import networkx as nx
from typing import Dict, List, Tuple, Any, Optional
import numpy as np


class KnowledgeGraph:
    """
    Knowledge graph for market trend analysis.
    Uses SSSP to navigate and prioritize data sources.
    """
    
    def __init__(self):
        """Initialize an empty knowledge graph."""
        self.graph = nx.DiGraph()
        self.node_metadata = {}
        
    def add_node(self, node_id: str, node_type: str, metadata: Dict[str, Any] = None):
        """
        Add a node to the knowledge graph.
        
        Args:
            node_id: Unique identifier for the node
            node_type: Type of node (e.g., 'stock', 'news', 'chart', 'video')
            metadata: Additional metadata for the node
        """
        self.graph.add_node(node_id)
        self.node_metadata[node_id] = {
            'type': node_type,
            'metadata': metadata or {}
        }
        
    def add_edge(self, source: str, target: str, weight: float, relationship: str = 'related'):
        """
        Add a weighted edge between nodes.
        
        Args:
            source: Source node ID
            target: Target node ID
            weight: Edge weight (lower is higher priority)
            relationship: Type of relationship between nodes
        """
        self.graph.add_edge(source, target, weight=weight, relationship=relationship)
        
    def compute_sssp(self, source_node: str) -> Dict[str, float]:
        """
        Compute Single-Source Shortest Path using Dijkstra's algorithm.
        
        Args:
            source_node: Starting node for SSSP computation
            
        Returns:
            Dictionary mapping node IDs to their shortest path distance from source
        """
        if source_node not in self.graph:
            raise ValueError(f"Source node '{source_node}' not found in graph")
            
        # Use NetworkX's implementation of Dijkstra's algorithm
        distances = nx.single_source_dijkstra_path_length(
            self.graph, 
            source_node,
            weight='weight'
        )
        
        return distances
        
    def get_priority_nodes(
        self, 
        source_node: str, 
        threshold: float = 0.7,
        max_nodes: Optional[int] = None
    ) -> List[Tuple[str, float]]:
        """
        Get prioritized list of nodes based on SSSP distances.
        
        Args:
            source_node: Starting node for priority computation
            threshold: Priority threshold (normalized 0-1, higher = more selective)
            max_nodes: Maximum number of nodes to return
            
        Returns:
            List of (node_id, priority_score) tuples, sorted by priority
        """
        distances = self.compute_sssp(source_node)
        
        if not distances:
            return []
        
        # Normalize distances to [0, 1] range (inverse for priority)
        max_distance = max(distances.values()) if distances else 1.0
        
        priorities = []
        for node_id, distance in distances.items():
            if node_id == source_node:
                continue
                
            # Convert distance to priority score (closer = higher priority)
            priority_score = 1.0 - (distance / max_distance) if max_distance > 0 else 1.0
            
            if priority_score >= threshold:
                priorities.append((node_id, priority_score))
        
        # Sort by priority (highest first)
        priorities.sort(key=lambda x: x[1], reverse=True)
        
        if max_nodes:
            priorities = priorities[:max_nodes]
            
        return priorities
    
    def get_node_info(self, node_id: str) -> Dict[str, Any]:
        """
        Get information about a specific node.
        
        Args:
            node_id: Node identifier
            
        Returns:
            Dictionary containing node type and metadata
        """
        if node_id not in self.node_metadata:
            raise ValueError(f"Node '{node_id}' not found")
            
        return self.node_metadata[node_id]
    
    def get_neighbors(self, node_id: str) -> List[str]:
        """
        Get all neighboring nodes.
        
        Args:
            node_id: Node identifier
            
        Returns:
            List of neighbor node IDs
        """
        if node_id not in self.graph:
            raise ValueError(f"Node '{node_id}' not found")
            
        return list(self.graph.neighbors(node_id))
    
    def visualize_graph(self, filepath: str = None) -> str:
        """
        Generate a text representation of the graph structure.
        
        Args:
            filepath: Optional path to save visualization
            
        Returns:
            String representation of the graph
        """
        output = ["Knowledge Graph Structure:"]
        output.append(f"Nodes: {self.graph.number_of_nodes()}")
        output.append(f"Edges: {self.graph.number_of_edges()}")
        output.append("\nNode Details:")
        
        for node_id in self.graph.nodes():
            node_info = self.node_metadata.get(node_id, {})
            node_type = node_info.get('type', 'unknown')
            neighbors = list(self.graph.neighbors(node_id))
            output.append(f"  - {node_id} (type: {node_type}, neighbors: {len(neighbors)})")
        
        result = "\n".join(output)
        
        if filepath:
            with open(filepath, 'w') as f:
                f.write(result)
                
        return result
