"""
Data Processing Module for fetching market data from various sources.
"""

import logging
from typing import List, Dict, Any, Optional
import requests
from datetime import datetime

from ..config import config


logger = logging.getLogger(__name__)


class MarketDataProcessor:
    """
    Processes and aggregates market data from various sources.
    """
    
    def __init__(self):
        """Initialize the market data processor."""
        self.alpha_vantage_key = config.ALPHA_VANTAGE_API_KEY
        self.news_api_key = config.NEWS_API_KEY
    
    def fetch_stock_data(self, symbol: str) -> Optional[Dict[str, Any]]:
        """
        Fetch stock data from Alpha Vantage.
        
        Args:
            symbol: Stock ticker symbol
            
        Returns:
            Stock data dictionary or None if fetch fails
        """
        if not self.alpha_vantage_key:
            logger.warning("Alpha Vantage API key not configured")
            return None
        
        url = config.ALPHA_VANTAGE_BASE_URL
        params = {
            'function': 'GLOBAL_QUOTE',
            'symbol': symbol,
            'apikey': self.alpha_vantage_key
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if 'Global Quote' in data:
                quote = data['Global Quote']
                return {
                    'symbol': symbol,
                    'price': float(quote.get('05. price', 0)),
                    'change': float(quote.get('09. change', 0)),
                    'change_percent': quote.get('10. change percent', '0%'),
                    'volume': int(quote.get('06. volume', 0)),
                    'timestamp': quote.get('07. latest trading day', ''),
                    'weight': 1.0  # Default weight for graph
                }
            
            logger.warning(f"No data returned for symbol: {symbol}")
            return None
            
        except requests.RequestException as e:
            logger.error(f"Error fetching stock data for {symbol}: {e}")
            return None
    
    def fetch_news(self, query: str, max_articles: int = 10) -> List[Dict[str, Any]]:
        """
        Fetch news articles related to a query.
        
        Args:
            query: Search query
            max_articles: Maximum number of articles to fetch
            
        Returns:
            List of news article dictionaries
        """
        if not self.news_api_key:
            logger.warning("NewsAPI key not configured")
            return []
        
        url = f"{config.NEWS_API_BASE_URL}/everything"
        params = {
            'q': query,
            'apiKey': self.news_api_key,
            'pageSize': max_articles,
            'sortBy': 'publishedAt',
            'language': 'en'
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            articles = []
            for article in data.get('articles', []):
                articles.append({
                    'title': article.get('title', ''),
                    'description': article.get('description', ''),
                    'content': article.get('content', ''),
                    'url': article.get('url', ''),
                    'source': article.get('source', {}).get('name', ''),
                    'published_at': article.get('publishedAt', ''),
                    'weight': 1.5,  # News gets slightly higher weight
                    'related_stocks': []  # To be populated by analysis
                })
            
            logger.info(f"Fetched {len(articles)} news articles")
            return articles
            
        except requests.RequestException as e:
            logger.error(f"Error fetching news: {e}")
            return []
    
    def create_sample_data(self, symbols: List[str]) -> Dict[str, Any]:
        """
        Create sample market data structure.
        Useful for testing without API keys.
        
        Args:
            symbols: List of stock symbols
            
        Returns:
            Sample market data dictionary
        """
        market_data = {
            'target': 'market_analysis',
            'timestamp': datetime.now().isoformat(),
            'stocks': [],
            'news': [],
            'charts': [],
            'videos': []
        }
        
        # Sample stock data
        for symbol in symbols:
            market_data['stocks'].append({
                'symbol': symbol,
                'price': 100.0,
                'change': 2.5,
                'change_percent': '+2.5%',
                'volume': 1000000,
                'timestamp': datetime.now().isoformat(),
                'weight': 1.0
            })
        
        # Sample news
        market_data['news'].append({
            'title': f'Market Analysis: {symbols[0] if symbols else "STOCK"} Shows Strong Performance',
            'description': 'The stock showed significant gains in recent trading...',
            'content': 'Detailed market analysis content here...',
            'url': 'https://example.com/news/1',
            'source': 'Market News',
            'published_at': datetime.now().isoformat(),
            'weight': 1.5,
            'related_stocks': symbols[:1] if symbols else []
        })
        
        # Sample chart
        market_data['charts'].append({
            'chart_type': 'price_chart',
            'symbol': symbols[0] if symbols else 'STOCK',
            'data': [95, 97, 98, 100, 102],  # Sample price data
            'weight': 2.0
        })
        
        # Sample video
        market_data['videos'].append({
            'video_type': 'earnings_call',
            'symbol': symbols[0] if symbols else 'STOCK',
            'duration': 3600,
            'transcript': 'Earnings call transcript with revenue and guidance information...',
            'weight': 3.0
        })
        
        return market_data
    
    def aggregate_market_data(
        self, 
        symbols: List[str],
        news_query: Optional[str] = None,
        use_sample: bool = False
    ) -> Dict[str, Any]:
        """
        Aggregate market data from all sources.
        
        Args:
            symbols: List of stock symbols to analyze
            news_query: Query for news articles (uses symbols if not provided)
            use_sample: If True, returns sample data instead of fetching from APIs
            
        Returns:
            Aggregated market data dictionary
        """
        if use_sample:
            logger.info("Using sample data")
            return self.create_sample_data(symbols)
        
        market_data = {
            'target': 'market_analysis',
            'timestamp': datetime.now().isoformat(),
            'stocks': [],
            'news': [],
            'charts': [],
            'videos': []
        }
        
        # Fetch stock data
        for symbol in symbols:
            stock_data = self.fetch_stock_data(symbol)
            if stock_data:
                market_data['stocks'].append(stock_data)
        
        # Fetch news
        query = news_query or ' OR '.join(symbols)
        news_articles = self.fetch_news(query)
        market_data['news'] = news_articles
        
        # Note: Charts and videos would require additional APIs/processing
        # For now, we include placeholders
        
        logger.info(f"Aggregated data: {len(market_data['stocks'])} stocks, "
                   f"{len(market_data['news'])} news articles")
        
        return market_data
