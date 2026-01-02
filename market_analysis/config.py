"""
Configuration module for Market Trend Analysis System.
Loads environment variables and provides centralized configuration.
"""

import os
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables from .env file
env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)


class Config:
    """Centralized configuration for the Market Trend Analysis System."""
    
    # API Keys
    ALPHA_VANTAGE_API_KEY = os.getenv('ALPHA_VANTAGE_API_KEY', '')
    NEWS_API_KEY = os.getenv('NEWS_API_KEY', '')
    GROK_API_KEY = os.getenv('GROK_API_KEY', '')
    GROK_API_ENDPOINT = os.getenv('GROK_API_ENDPOINT', 'https://api.x.ai/v1')
    
    # Pinecone Configuration
    PINECONE_API_KEY = os.getenv('PINECONE_API_KEY', '')
    PINECONE_ENVIRONMENT = os.getenv('PINECONE_ENVIRONMENT', 'us-west1-gcp')
    PINECONE_INDEX_NAME = os.getenv('PINECONE_INDEX_NAME', 'market-trends-index')
    
    # Algorithm Parameters
    MAX_GRAPH_DEPTH = int(os.getenv('MAX_GRAPH_DEPTH', '5'))
    SSSP_PRIORITY_THRESHOLD = float(os.getenv('SSSP_PRIORITY_THRESHOLD', '0.3'))
    
    # API Endpoints
    ALPHA_VANTAGE_BASE_URL = 'https://www.alphavantage.co/query'
    NEWS_API_BASE_URL = 'https://newsapi.org/v2'
    
    @classmethod
    def validate(cls):
        """Validate that required configuration is present."""
        required_keys = [
            'ALPHA_VANTAGE_API_KEY',
            'NEWS_API_KEY',
        ]
        
        missing_keys = [key for key in required_keys if not getattr(cls, key)]
        
        if missing_keys:
            raise ValueError(
                f"Missing required configuration: {', '.join(missing_keys)}. "
                f"Please check your .env file."
            )
        
        return True
    
    @classmethod
    def is_grok_enabled(cls):
        """Check if Grok API is configured."""
        return bool(cls.GROK_API_KEY)
    
    @classmethod
    def is_pinecone_enabled(cls):
        """Check if Pinecone vector database is configured."""
        return bool(cls.PINECONE_API_KEY)


# Export config instance
config = Config()
