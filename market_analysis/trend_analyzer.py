"""
Trend Analysis Module
Implements market trend detection and pattern recognition algorithms
"""

from typing import Dict, List, Any, Optional
from datetime import datetime
import statistics


class TrendAnalyzer:
    """
    Analyzes market trends and identifies patterns
    Provides actionable insights for decision making
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize trend analyzer
        
        Args:
            config: Optional configuration dictionary
        """
        self.config = config or {}
        self.min_data_points = self.config.get('min_data_points', 3)
        self.trend_threshold = self.config.get('trend_threshold', 0.02)  # 2% change
        self.analysis_history: List[Dict[str, Any]] = []
        
    def analyze(self, processed_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Perform comprehensive trend analysis
        
        Args:
            processed_data: Processed market data from MultimodalDataProcessor
            
        Returns:
            Analysis results with trends, signals, and recommendations
        """
        analysis = {
            'timestamp': datetime.now().isoformat(),
            'trends': {},
            'signals': [],
            'recommendations': [],
            'confidence': 0.0
        }
        
        # Extract processed data
        data = processed_data.get('processed_data', {})
        
        # Analyze each data type
        if 'price' in data:
            price_analysis = self._analyze_price_trend(data['price'])
            analysis['trends']['price'] = price_analysis
            if price_analysis.get('signal'):
                analysis['signals'].append(price_analysis['signal'])
        
        if 'volume' in data:
            volume_analysis = self._analyze_volume_trend(data['volume'])
            analysis['trends']['volume'] = volume_analysis
            if volume_analysis.get('signal'):
                analysis['signals'].append(volume_analysis['signal'])
        
        if 'sentiment' in data:
            sentiment_analysis = self._analyze_sentiment_trend(data['sentiment'])
            analysis['trends']['sentiment'] = sentiment_analysis
            if sentiment_analysis.get('signal'):
                analysis['signals'].append(sentiment_analysis['signal'])
        
        # Generate overall recommendation
        analysis['recommendations'] = self._generate_recommendations(analysis['trends'])
        
        # Calculate overall confidence
        analysis['confidence'] = self._calculate_overall_confidence(analysis['trends'])
        
        # Detect patterns
        analysis['patterns'] = self._detect_patterns(data)
        
        # Store in history
        self.analysis_history.append(analysis)
        if len(self.analysis_history) > 1000:
            self.analysis_history = self.analysis_history[-1000:]
        
        return analysis
    
    def _analyze_price_trend(self, price_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze price trend
        
        Args:
            price_data: Processed price data
            
        Returns:
            Price trend analysis
        """
        analysis = {
            'direction': 'neutral',
            'strength': 0.0,
            'volatility': 'unknown',
            'signal': None
        }
        
        # Handle different price data formats
        if 'prices' in price_data:
            prices = price_data['prices']
            if len(prices) >= self.min_data_points:
                # Calculate trend
                first_price = prices[0]
                last_price = prices[-1]
                change_pct = (last_price - first_price) / first_price if first_price != 0 else 0
                
                analysis['change_percent'] = change_pct * 100
                
                # Determine direction
                if change_pct > self.trend_threshold:
                    analysis['direction'] = 'upward'
                    analysis['signal'] = {
                        'type': 'price',
                        'direction': 'bullish',
                        'strength': min(1.0, abs(change_pct) * 10)
                    }
                elif change_pct < -self.trend_threshold:
                    analysis['direction'] = 'downward'
                    analysis['signal'] = {
                        'type': 'price',
                        'direction': 'bearish',
                        'strength': min(1.0, abs(change_pct) * 10)
                    }
                
                # Calculate strength
                analysis['strength'] = min(1.0, abs(change_pct) * 10)
                
                # Assess volatility
                if len(prices) > 1:
                    volatility = statistics.stdev(prices) / statistics.mean(prices) if statistics.mean(prices) != 0 else 0
                    if volatility > 0.05:
                        analysis['volatility'] = 'high'
                    elif volatility > 0.02:
                        analysis['volatility'] = 'medium'
                    else:
                        analysis['volatility'] = 'low'
                    analysis['volatility_value'] = volatility
        
        elif 'close' in price_data and 'open' in price_data:
            # OHLCV format
            change = price_data['close'] - price_data['open']
            change_pct = change / price_data['open'] if price_data['open'] != 0 else 0
            
            analysis['change_percent'] = change_pct * 100
            
            if change_pct > self.trend_threshold:
                analysis['direction'] = 'upward'
            elif change_pct < -self.trend_threshold:
                analysis['direction'] = 'downward'
            
            analysis['strength'] = min(1.0, abs(change_pct) * 10)
        
        return analysis
    
    def _analyze_volume_trend(self, volume_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze volume trend
        
        Args:
            volume_data: Processed volume data
            
        Returns:
            Volume trend analysis
        """
        analysis = {
            'trend': 'neutral',
            'significance': 'low',
            'signal': None
        }
        
        if 'volumes' in volume_data:
            volumes = volume_data['volumes']
            if len(volumes) >= self.min_data_points:
                avg_volume = sum(volumes) / len(volumes)
                latest_volume = volumes[-1]
                
                # Compare latest to average
                deviation = (latest_volume - avg_volume) / avg_volume if avg_volume != 0 else 0
                
                analysis['avg_volume'] = avg_volume
                analysis['latest_volume'] = latest_volume
                analysis['deviation_percent'] = deviation * 100
                
                if deviation > 0.2:  # 20% above average
                    analysis['trend'] = 'increasing'
                    analysis['significance'] = 'high'
                    analysis['signal'] = {
                        'type': 'volume',
                        'direction': 'surge',
                        'strength': min(1.0, deviation)
                    }
                elif deviation < -0.2:  # 20% below average
                    analysis['trend'] = 'decreasing'
                    analysis['significance'] = 'medium'
                    analysis['signal'] = {
                        'type': 'volume',
                        'direction': 'drop',
                        'strength': min(1.0, abs(deviation))
                    }
                elif abs(deviation) > 0.1:
                    analysis['significance'] = 'medium'
                else:
                    analysis['significance'] = 'low'
        
        return analysis
    
    def _analyze_sentiment_trend(self, sentiment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze sentiment trend
        
        Args:
            sentiment_data: Processed sentiment data
            
        Returns:
            Sentiment trend analysis
        """
        analysis = {
            'mood': 'neutral',
            'intensity': 'low',
            'signal': None
        }
        
        if 'sentiment_scores' in sentiment_data:
            scores = sentiment_data['sentiment_scores']
            if scores:
                avg_sentiment = sum(scores) / len(scores)
                
                analysis['avg_sentiment'] = avg_sentiment
                
                # Classify mood
                if avg_sentiment > 0.3:
                    analysis['mood'] = 'bullish'
                    analysis['intensity'] = 'high' if avg_sentiment > 0.6 else 'medium'
                    analysis['signal'] = {
                        'type': 'sentiment',
                        'direction': 'bullish',
                        'strength': abs(avg_sentiment)
                    }
                elif avg_sentiment < -0.3:
                    analysis['mood'] = 'bearish'
                    analysis['intensity'] = 'high' if avg_sentiment < -0.6 else 'medium'
                    analysis['signal'] = {
                        'type': 'sentiment',
                        'direction': 'bearish',
                        'strength': abs(avg_sentiment)
                    }
                else:
                    analysis['mood'] = 'neutral'
                    analysis['intensity'] = 'low'
        
        elif 'score' in sentiment_data:
            score = sentiment_data['score']
            analysis['score'] = score
            
            if score > 0.3:
                analysis['mood'] = 'bullish'
            elif score < -0.3:
                analysis['mood'] = 'bearish'
            
            analysis['intensity'] = 'high' if abs(score) > 0.6 else 'medium' if abs(score) > 0.3 else 'low'
        
        return analysis
    
    def _generate_recommendations(self, trends: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Generate actionable recommendations based on trends
        
        Args:
            trends: Analyzed trends from all data types
            
        Returns:
            List of recommendations
        """
        recommendations = []
        
        # Analyze price trend
        price_trend = trends.get('price', {})
        volume_trend = trends.get('volume', {})
        sentiment_trend = trends.get('sentiment', {})
        
        # Strong upward price with high volume
        if (price_trend.get('direction') == 'upward' and 
            volume_trend.get('trend') == 'increasing'):
            recommendations.append({
                'action': 'strong_buy_signal',
                'reason': 'Upward price trend confirmed by increasing volume',
                'confidence': 0.8
            })
        
        # Strong downward price with high volume
        elif (price_trend.get('direction') == 'downward' and 
              volume_trend.get('trend') == 'increasing'):
            recommendations.append({
                'action': 'strong_sell_signal',
                'reason': 'Downward price trend confirmed by increasing volume',
                'confidence': 0.8
            })
        
        # Price and sentiment alignment
        if (price_trend.get('direction') == 'upward' and 
            sentiment_trend.get('mood') == 'bullish'):
            recommendations.append({
                'action': 'bullish_confirmation',
                'reason': 'Price trend and sentiment both bullish',
                'confidence': 0.7
            })
        
        elif (price_trend.get('direction') == 'downward' and 
              sentiment_trend.get('mood') == 'bearish'):
            recommendations.append({
                'action': 'bearish_confirmation',
                'reason': 'Price trend and sentiment both bearish',
                'confidence': 0.7
            })
        
        # Divergence warnings
        if (price_trend.get('direction') == 'upward' and 
            volume_trend.get('trend') == 'decreasing'):
            recommendations.append({
                'action': 'divergence_warning',
                'reason': 'Price rising but volume decreasing - potential reversal',
                'confidence': 0.6
            })
        
        # High volatility warning
        if price_trend.get('volatility') == 'high':
            recommendations.append({
                'action': 'high_volatility_warning',
                'reason': 'High price volatility detected - exercise caution',
                'confidence': 0.9
            })
        
        # If no clear signals
        if not recommendations:
            recommendations.append({
                'action': 'hold',
                'reason': 'No strong signals detected - maintain current position',
                'confidence': 0.5
            })
        
        return recommendations
    
    def _calculate_overall_confidence(self, trends: Dict[str, Any]) -> float:
        """
        Calculate overall confidence in analysis
        
        Args:
            trends: All trend analyses
            
        Returns:
            Confidence score (0-1)
        """
        confidences = []
        
        # Extract confidence from each trend type
        for trend_type, trend_data in trends.items():
            if trend_data.get('strength'):
                confidences.append(trend_data['strength'])
            if trend_data.get('signal'):
                confidences.append(trend_data['signal'].get('strength', 0.5))
        
        if confidences:
            return sum(confidences) / len(confidences)
        
        return 0.5  # Default medium confidence
    
    def _detect_patterns(self, data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Detect common market patterns
        
        Args:
            data: Processed market data
            
        Returns:
            List of detected patterns
        """
        patterns = []
        
        # Price patterns
        if 'price' in data and 'prices' in data['price']:
            prices = data['price']['prices']
            
            # Double bottom pattern
            if len(prices) >= 5:
                if (prices[0] < prices[1] and prices[1] > prices[2] and 
                    prices[2] < prices[3] and prices[3] > prices[4]):
                    patterns.append({
                        'type': 'double_bottom',
                        'description': 'Potential reversal pattern detected',
                        'bullish': True
                    })
            
            # Consistent uptrend
            if len(prices) >= 3:
                if all(prices[i] < prices[i+1] for i in range(len(prices)-1)):
                    patterns.append({
                        'type': 'consistent_uptrend',
                        'description': 'Strong continuous upward movement',
                        'bullish': True
                    })
            
            # Consistent downtrend
            if len(prices) >= 3:
                if all(prices[i] > prices[i+1] for i in range(len(prices)-1)):
                    patterns.append({
                        'type': 'consistent_downtrend',
                        'description': 'Strong continuous downward movement',
                        'bullish': False
                    })
        
        return patterns
    
    def get_summary(self, num_recent: int = 10) -> Dict[str, Any]:
        """
        Get summary of recent analyses
        
        Args:
            num_recent: Number of recent analyses to summarize
            
        Returns:
            Summary statistics
        """
        if not self.analysis_history:
            return {'status': 'no_data'}
        
        recent = self.analysis_history[-num_recent:]
        
        # Aggregate signals
        all_signals = []
        for analysis in recent:
            all_signals.extend(analysis.get('signals', []))
        
        # Count signal types
        signal_counts = {}
        for signal in all_signals:
            signal_type = signal.get('type', 'unknown')
            signal_counts[signal_type] = signal_counts.get(signal_type, 0) + 1
        
        # Average confidence
        avg_confidence = sum(a.get('confidence', 0) for a in recent) / len(recent)
        
        return {
            'total_analyses': len(self.analysis_history),
            'recent_count': len(recent),
            'signal_counts': signal_counts,
            'avg_confidence': avg_confidence,
            'latest_analysis': recent[-1] if recent else None
        }
