"""
Multimodal Data Processing Module
Handles different types of market data efficiently
"""

from typing import Dict, List, Any, Optional
from datetime import datetime
import json


class MultimodalDataProcessor:
    """
    Processes multiple types of market data (price, volume, sentiment, etc.)
    Implements efficient data normalization and validation
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize multimodal data processor
        
        Args:
            config: Optional configuration dictionary
        """
        self.config = config or {}
        self.processed_count = 0
        self.error_count = 0
        self.data_types = ['price', 'volume', 'sentiment', 'technical', 'news']
        
    def process(self, raw_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process raw multimodal market data
        
        Args:
            raw_data: Dictionary containing various types of market data
            
        Returns:
            Processed and normalized data
        """
        processed = {
            'timestamp': datetime.now().isoformat(),
            'data_types_present': [],
            'processed_data': {}
        }
        
        # Process each data type
        for data_type in self.data_types:
            if data_type in raw_data:
                try:
                    processed_value = self._process_by_type(data_type, raw_data[data_type])
                    processed['processed_data'][data_type] = processed_value
                    processed['data_types_present'].append(data_type)
                except Exception as e:
                    self.error_count += 1
                    processed['processed_data'][data_type] = {
                        'error': str(e),
                        'raw_data': raw_data[data_type]
                    }
        
        self.processed_count += 1
        processed['validation'] = self._validate_data(processed['processed_data'])
        
        return processed
    
    def _process_by_type(self, data_type: str, data: Any) -> Dict[str, Any]:
        """
        Process data based on its type
        
        Args:
            data_type: Type of data (price, volume, etc.)
            data: Raw data to process
            
        Returns:
            Processed data
        """
        if data_type == 'price':
            return self._process_price_data(data)
        elif data_type == 'volume':
            return self._process_volume_data(data)
        elif data_type == 'sentiment':
            return self._process_sentiment_data(data)
        elif data_type == 'technical':
            return self._process_technical_data(data)
        elif data_type == 'news':
            return self._process_news_data(data)
        else:
            return {'raw': data, 'normalized': True}
    
    def _process_price_data(self, data: Any) -> Dict[str, Any]:
        """
        Process price data
        
        Args:
            data: Price data (list of prices or dict with OHLCV)
            
        Returns:
            Normalized price data
        """
        if isinstance(data, list):
            # Simple price list
            prices = [float(p) for p in data]
            return {
                'prices': prices,
                'count': len(prices),
                'min': min(prices) if prices else 0,
                'max': max(prices) if prices else 0,
                'avg': sum(prices) / len(prices) if prices else 0,
                'latest': prices[-1] if prices else 0
            }
        elif isinstance(data, dict):
            # OHLCV format
            return {
                'open': float(data.get('open', 0)),
                'high': float(data.get('high', 0)),
                'low': float(data.get('low', 0)),
                'close': float(data.get('close', 0)),
                'volume': float(data.get('volume', 0))
            }
        else:
            return {'raw': data, 'type': 'unknown'}
    
    def _process_volume_data(self, data: Any) -> Dict[str, Any]:
        """
        Process volume data
        
        Args:
            data: Volume data
            
        Returns:
            Normalized volume data
        """
        if isinstance(data, list):
            volumes = [float(v) for v in data]
            return {
                'volumes': volumes,
                'count': len(volumes),
                'total': sum(volumes),
                'avg': sum(volumes) / len(volumes) if volumes else 0,
                'max': max(volumes) if volumes else 0,
                'latest': volumes[-1] if volumes else 0
            }
        else:
            return {'volume': float(data), 'single_value': True}
    
    def _process_sentiment_data(self, data: Any) -> Dict[str, Any]:
        """
        Process sentiment data
        
        Args:
            data: Sentiment data (scores, text, etc.)
            
        Returns:
            Normalized sentiment data
        """
        if isinstance(data, list):
            # List of sentiment scores
            scores = [float(s) for s in data]
            normalized_scores = [self._normalize_sentiment(s) for s in scores]
            return {
                'sentiment_scores': normalized_scores,
                'count': len(scores),
                'avg': sum(normalized_scores) / len(normalized_scores) if normalized_scores else 0,
                'classification': self._classify_sentiment(sum(normalized_scores) / len(normalized_scores) if normalized_scores else 0)
            }
        elif isinstance(data, dict):
            # Structured sentiment data
            return {
                'score': self._normalize_sentiment(float(data.get('score', 0))),
                'classification': data.get('classification', 'neutral'),
                'confidence': float(data.get('confidence', 0.5))
            }
        else:
            # Single score
            score = self._normalize_sentiment(float(data))
            return {
                'score': score,
                'classification': self._classify_sentiment(score)
            }
    
    def _process_technical_data(self, data: Any) -> Dict[str, Any]:
        """
        Process technical indicator data
        
        Args:
            data: Technical indicator data
            
        Returns:
            Normalized technical data
        """
        if isinstance(data, dict):
            processed = {}
            for indicator, value in data.items():
                processed[indicator] = {
                    'value': float(value) if isinstance(value, (int, float)) else value,
                    'indicator': indicator
                }
            return processed
        else:
            return {'raw': data, 'type': 'unknown'}
    
    def _process_news_data(self, data: Any) -> Dict[str, Any]:
        """
        Process news/event data
        
        Args:
            data: News data
            
        Returns:
            Normalized news data
        """
        if isinstance(data, list):
            # List of news items
            return {
                'count': len(data),
                'items': data,
                'has_data': len(data) > 0
            }
        elif isinstance(data, dict):
            # Single news item
            return {
                'headline': data.get('headline', ''),
                'content': data.get('content', ''),
                'source': data.get('source', 'unknown'),
                'impact': data.get('impact', 'medium')
            }
        else:
            return {'raw': data, 'type': 'text'}
    
    def _normalize_sentiment(self, score: float) -> float:
        """
        Normalize sentiment score to [-1, 1] range
        
        Args:
            score: Raw sentiment score
            
        Returns:
            Normalized score
        """
        # Assume scores might come in different ranges
        if -1 <= score <= 1:
            return score
        elif 0 <= score <= 100:
            return (score - 50) / 50
        elif 0 <= score <= 5:
            return (score - 2.5) / 2.5
        else:
            # Clip to range
            return max(-1, min(1, score))
    
    def _classify_sentiment(self, score: float) -> str:
        """
        Classify sentiment based on score
        
        Args:
            score: Normalized sentiment score [-1, 1]
            
        Returns:
            Classification string
        """
        if score > 0.3:
            return 'bullish'
        elif score < -0.3:
            return 'bearish'
        else:
            return 'neutral'
    
    def _validate_data(self, processed_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate processed data
        
        Args:
            processed_data: Processed data dictionary
            
        Returns:
            Validation results
        """
        validation = {
            'is_valid': True,
            'warnings': [],
            'errors': []
        }
        
        # Check for required data types
        if not processed_data:
            validation['is_valid'] = False
            validation['errors'].append('No data types present')
        
        # Check for errors in any data type
        for data_type, data in processed_data.items():
            if isinstance(data, dict) and 'error' in data:
                validation['warnings'].append(f'Error in {data_type}: {data["error"]}')
        
        # Check data completeness
        if len(processed_data) < 2:
            validation['warnings'].append('Limited data types - analysis may be incomplete')
        
        return validation
    
    def batch_process(self, data_batch: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Process multiple data items efficiently
        
        Args:
            data_batch: List of raw data dictionaries
            
        Returns:
            List of processed data
        """
        return [self.process(data) for data in data_batch]
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get processing statistics"""
        return {
            'processed_count': self.processed_count,
            'error_count': self.error_count,
            'error_rate': self.error_count / self.processed_count if self.processed_count > 0 else 0,
            'supported_data_types': self.data_types
        }
