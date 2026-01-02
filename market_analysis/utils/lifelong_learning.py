"""
Lifelong Learning Module using Pinecone Vector Database.
Stores and retrieves insights for continuous improvement.
"""

import logging
from typing import List, Dict, Any, Optional
import numpy as np
from datetime import datetime

try:
    import pinecone
    PINECONE_AVAILABLE = True
except ImportError:
    PINECONE_AVAILABLE = False
    logging.warning("Pinecone client not installed. Lifelong learning will use in-memory storage.")

from ..config import config


logger = logging.getLogger(__name__)


class LifelongLearning:
    """
    Manages lifelong learning through vector database storage.
    Stores insights and enables retrieval of similar past analyses.
    """
    
    def __init__(self, use_pinecone: bool = None):
        """
        Initialize lifelong learning module.
        
        Args:
            use_pinecone: Whether to use Pinecone. If None, uses config.is_pinecone_enabled()
        """
        self.use_pinecone = use_pinecone if use_pinecone is not None else config.is_pinecone_enabled()
        self.memory_store = []  # In-memory fallback
        
        if self.use_pinecone and PINECONE_AVAILABLE:
            self._initialize_pinecone()
        else:
            logger.info("Using in-memory storage for lifelong learning")
    
    def _initialize_pinecone(self):
        """Initialize Pinecone vector database."""
        try:
            pinecone.init(
                api_key=config.PINECONE_API_KEY,
                environment=config.PINECONE_ENVIRONMENT
            )
            
            # Create index if it doesn't exist
            if config.PINECONE_INDEX_NAME not in pinecone.list_indexes():
                pinecone.create_index(
                    config.PINECONE_INDEX_NAME,
                    dimension=768,  # Standard embedding dimension
                    metric='cosine'
                )
            
            self.index = pinecone.Index(config.PINECONE_INDEX_NAME)
            logger.info(f"Pinecone index '{config.PINECONE_INDEX_NAME}' initialized")
            
        except Exception as e:
            logger.error(f"Failed to initialize Pinecone: {e}")
            logger.info("Falling back to in-memory storage")
            self.use_pinecone = False
    
    def _generate_embedding(self, text: str) -> List[float]:
        """
        Generate embedding vector for text.
        This is a placeholder - in production, would use proper embedding model.
        
        Args:
            text: Text to embed
            
        Returns:
            Embedding vector
        """
        # Simple placeholder: hash-based pseudo-embedding
        # In production, use proper embedding model (e.g., from transformers)
        np.random.seed(hash(text) % (2**32))
        embedding = np.random.randn(768).tolist()
        return embedding
    
    def store_insight(self, insight: Dict[str, Any], metadata: Dict[str, Any] = None) -> str:
        """
        Store an insight in the vector database.
        
        Args:
            insight: Insight dictionary to store
            metadata: Additional metadata
            
        Returns:
            Unique ID of stored insight
        """
        # Generate unique ID
        insight_id = f"insight_{datetime.now().timestamp()}"
        
        # Create embedding from insight summary
        summary = insight.get('summary', str(insight))
        embedding = self._generate_embedding(summary)
        
        # Prepare metadata
        store_metadata = {
            'timestamp': datetime.now().isoformat(),
            'type': insight.get('type', 'unknown'),
            'confidence': insight.get('confidence', 0.0),
            **(metadata or {})
        }
        
        if self.use_pinecone and hasattr(self, 'index'):
            try:
                # Store in Pinecone
                self.index.upsert([(insight_id, embedding, store_metadata)])
                logger.info(f"Stored insight {insight_id} in Pinecone")
            except Exception as e:
                logger.error(f"Failed to store in Pinecone: {e}")
                # Fall back to in-memory
                self._store_in_memory(insight_id, embedding, insight, store_metadata)
        else:
            # Store in memory
            self._store_in_memory(insight_id, embedding, insight, store_metadata)
        
        return insight_id
    
    def _store_in_memory(self, insight_id: str, embedding: List[float], 
                         insight: Dict[str, Any], metadata: Dict[str, Any]):
        """Store insight in in-memory storage."""
        self.memory_store.append({
            'id': insight_id,
            'embedding': embedding,
            'insight': insight,
            'metadata': metadata
        })
        logger.info(f"Stored insight {insight_id} in memory")
    
    def retrieve_similar_insights(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """
        Retrieve similar past insights.
        
        Args:
            query: Query text to find similar insights
            top_k: Number of similar insights to retrieve
            
        Returns:
            List of similar insights with similarity scores
        """
        query_embedding = self._generate_embedding(query)
        
        if self.use_pinecone and hasattr(self, 'index'):
            try:
                # Query Pinecone
                results = self.index.query(query_embedding, top_k=top_k, include_metadata=True)
                
                similar_insights = []
                for match in results.get('matches', []):
                    similar_insights.append({
                        'id': match['id'],
                        'score': match['score'],
                        'metadata': match.get('metadata', {})
                    })
                
                logger.info(f"Retrieved {len(similar_insights)} similar insights from Pinecone")
                return similar_insights
                
            except Exception as e:
                logger.error(f"Failed to query Pinecone: {e}")
        
        # Fall back to in-memory similarity search
        return self._search_in_memory(query_embedding, top_k)
    
    def _search_in_memory(self, query_embedding: List[float], top_k: int) -> List[Dict[str, Any]]:
        """Search for similar insights in in-memory storage."""
        if not self.memory_store:
            return []
        
        # Calculate cosine similarity
        similarities = []
        query_vec = np.array(query_embedding)
        
        for item in self.memory_store:
            item_vec = np.array(item['embedding'])
            similarity = np.dot(query_vec, item_vec) / (np.linalg.norm(query_vec) * np.linalg.norm(item_vec))
            similarities.append({
                'id': item['id'],
                'score': float(similarity),
                'metadata': item['metadata'],
                'insight': item['insight']
            })
        
        # Sort by similarity and return top_k
        similarities.sort(key=lambda x: x['score'], reverse=True)
        results = similarities[:top_k]
        
        logger.info(f"Retrieved {len(results)} similar insights from memory")
        return results
    
    def get_learning_stats(self) -> Dict[str, Any]:
        """
        Get statistics about stored insights.
        
        Returns:
            Dictionary with learning statistics
        """
        stats = {
            'storage_type': 'pinecone' if self.use_pinecone else 'in-memory',
            'total_insights': 0
        }
        
        if self.use_pinecone and hasattr(self, 'index'):
            try:
                index_stats = self.index.describe_index_stats()
                stats['total_insights'] = index_stats.get('total_vector_count', 0)
            except Exception as e:
                logger.error(f"Failed to get Pinecone stats: {e}")
        else:
            stats['total_insights'] = len(self.memory_store)
        
        return stats
