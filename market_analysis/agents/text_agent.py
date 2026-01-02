"""
Text Sub-Agent for processing news articles and text-based reports.
"""

import logging
from typing import List, Dict, Any
import requests

from ..config import config


logger = logging.getLogger(__name__)


class TextAgent:
    """
    Sub-agent specialized in processing text data (news, reports).
    """
    
    def __init__(self):
        """Initialize the text agent."""
        self.api_key = config.NEWS_API_KEY
        logger.info("Text Agent initialized")
    
    def fetch_news(self, query: str, max_results: int = 10) -> List[Dict[str, Any]]:
        """
        Fetch news articles using NewsAPI.
        
        Args:
            query: Search query for news articles
            max_results: Maximum number of results to return
            
        Returns:
            List of news article dictionaries
        """
        if not self.api_key:
            logger.warning("NewsAPI key not configured")
            return []
        
        url = f"{config.NEWS_API_BASE_URL}/everything"
        params = {
            'q': query,
            'apiKey': self.api_key,
            'pageSize': max_results,
            'sortBy': 'publishedAt'
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            articles = data.get('articles', [])
            logger.info(f"Fetched {len(articles)} news articles for query: {query}")
            return articles
            
        except requests.RequestException as e:
            logger.error(f"Error fetching news: {e}")
            return []
    
    def analyze_sentiment(self, text: str) -> Dict[str, Any]:
        """
        Analyze sentiment of text.
        This is a placeholder - in production, would use Grok API or sentiment analysis model.
        
        Args:
            text: Text to analyze
            
        Returns:
            Sentiment analysis results
        """
        # Simple keyword-based sentiment (placeholder)
        positive_keywords = ['gain', 'profit', 'growth', 'up', 'rise', 'bullish', 'positive']
        negative_keywords = ['loss', 'decline', 'down', 'fall', 'bearish', 'negative', 'drop']
        
        text_lower = text.lower()
        positive_count = sum(1 for word in positive_keywords if word in text_lower)
        negative_count = sum(1 for word in negative_keywords if word in text_lower)
        
        total = positive_count + negative_count
        if total == 0:
            sentiment = 'neutral'
            score = 0.5
        elif positive_count > negative_count:
            sentiment = 'positive'
            score = 0.5 + (positive_count / (total * 2))
        else:
            sentiment = 'negative'
            score = 0.5 - (negative_count / (total * 2))
        
        return {
            'sentiment': sentiment,
            'score': score,
            'positive_signals': positive_count,
            'negative_signals': negative_count
        }
    
    def process_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process a task delegated by the master agent.
        
        Args:
            task: Task dictionary with node_id, priority, and metadata
            
        Returns:
            Processing results with insights
        """
        node_id = task['node_id']
        metadata = task.get('metadata', {})
        
        logger.info(f"Processing text task: {node_id}")
        
        # Extract text content
        text = metadata.get('content', metadata.get('description', ''))
        title = metadata.get('title', '')
        
        # Analyze sentiment
        sentiment = self.analyze_sentiment(text + ' ' + title)
        
        # Extract key information
        insights = [{
            'type': 'text_analysis',
            'node_id': node_id,
            'sentiment': sentiment['sentiment'],
            'confidence': sentiment['score'],
            'summary': f"Sentiment: {sentiment['sentiment']} (score: {sentiment['score']:.2f})"
        }]
        
        return {
            'node_id': node_id,
            'agent': 'text_agent',
            'insights': insights,
            'confidence': sentiment['score']
        }
    
    def process_tasks(self, tasks: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Process multiple tasks.
        
        Args:
            tasks: List of task dictionaries
            
        Returns:
            List of processing results
        """
        results = []
        for task in tasks:
            result = self.process_task(task)
            results.append(result)
        
        logger.info(f"Processed {len(results)} text tasks")
        return results
