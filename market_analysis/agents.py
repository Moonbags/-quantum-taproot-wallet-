"""
Agent Architecture Module
Implements master and sub-agent patterns inspired by LeanAgent framework
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Any, Optional
import time
import json
from datetime import datetime


class BaseAgent(ABC):
    """Abstract base class for all agents in the system"""
    
    def __init__(self, agent_id: str, config: Optional[Dict[str, Any]] = None):
        """
        Initialize base agent
        
        Args:
            agent_id: Unique identifier for the agent
            config: Optional configuration dictionary
        """
        self.agent_id = agent_id
        self.config = config or {}
        self.created_at = datetime.now()
        self.state = "initialized"
        self.memory = []
        
    @abstractmethod
    def process(self, data: Any) -> Any:
        """
        Process input data and return results
        
        Args:
            data: Input data to process
            
        Returns:
            Processed results
        """
        pass
    
    @abstractmethod
    def learn(self, experience: Dict[str, Any]) -> None:
        """
        Learn from experience
        
        Args:
            experience: Experience dictionary containing data and outcomes
        """
        pass
    
    def get_state(self) -> Dict[str, Any]:
        """Get current agent state"""
        return {
            'agent_id': self.agent_id,
            'state': self.state,
            'created_at': self.created_at.isoformat(),
            'memory_size': len(self.memory)
        }


class SubAgent(BaseAgent):
    """
    Sub-agent for specialized tasks
    Handles specific aspects of market analysis
    """
    
    def __init__(self, agent_id: str, specialty: str, config: Optional[Dict[str, Any]] = None):
        """
        Initialize sub-agent
        
        Args:
            agent_id: Unique identifier
            specialty: Agent's area of expertise (e.g., 'price_analysis', 'sentiment')
            config: Optional configuration
        """
        super().__init__(agent_id, config)
        self.specialty = specialty
        self.expertise_level = 0.0
        self.task_count = 0
        
    def process(self, data: Any) -> Any:
        """
        Process data according to specialty
        
        Args:
            data: Input data
            
        Returns:
            Processed results with metadata
        """
        self.task_count += 1
        self.state = "processing"
        
        # Process based on specialty
        result = self._specialized_processing(data)
        
        self.state = "idle"
        return {
            'agent_id': self.agent_id,
            'specialty': self.specialty,
            'result': result,
            'confidence': self._calculate_confidence(),
            'processed_at': datetime.now().isoformat()
        }
    
    def _specialized_processing(self, data: Any) -> Any:
        """
        Perform specialized processing based on agent's expertise
        
        Args:
            data: Input data
            
        Returns:
            Processed result
        """
        # Default implementation - can be overridden
        if self.specialty == 'price_analysis':
            return self._analyze_price_data(data)
        elif self.specialty == 'volume_analysis':
            return self._analyze_volume_data(data)
        elif self.specialty == 'sentiment_analysis':
            return self._analyze_sentiment_data(data)
        else:
            return {'raw_data': data, 'processed': True}
    
    def _analyze_price_data(self, data: Any) -> Dict[str, Any]:
        """Analyze price trends"""
        if isinstance(data, dict) and 'prices' in data:
            prices = data['prices']
            return {
                'trend': 'upward' if len(prices) > 1 and prices[-1] > prices[0] else 'downward',
                'volatility': self._calculate_volatility(prices),
                'data_points': len(prices)
            }
        return {'error': 'Invalid price data format'}
    
    def _analyze_volume_data(self, data: Any) -> Dict[str, Any]:
        """Analyze volume patterns"""
        if isinstance(data, dict) and 'volumes' in data:
            volumes = data['volumes']
            avg_volume = sum(volumes) / len(volumes) if volumes else 0
            return {
                'average_volume': avg_volume,
                'trend': 'increasing' if volumes[-1] > avg_volume else 'decreasing',
                'data_points': len(volumes)
            }
        return {'error': 'Invalid volume data format'}
    
    def _analyze_sentiment_data(self, data: Any) -> Dict[str, Any]:
        """Analyze sentiment indicators"""
        if isinstance(data, dict) and 'sentiment_scores' in data:
            scores = data['sentiment_scores']
            avg_sentiment = sum(scores) / len(scores) if scores else 0
            return {
                'average_sentiment': avg_sentiment,
                'mood': 'bullish' if avg_sentiment > 0 else 'bearish',
                'data_points': len(scores)
            }
        return {'error': 'Invalid sentiment data format'}
    
    def _calculate_volatility(self, prices: List[float]) -> float:
        """Calculate price volatility"""
        if len(prices) < 2:
            return 0.0
        
        changes = [abs(prices[i] - prices[i-1]) for i in range(1, len(prices))]
        return sum(changes) / len(changes) if changes else 0.0
    
    def _calculate_confidence(self) -> float:
        """Calculate confidence based on expertise and experience"""
        base_confidence = min(0.9, 0.5 + (self.task_count * 0.01))
        return base_confidence * (1 + self.expertise_level)
    
    def learn(self, experience: Dict[str, Any]) -> None:
        """
        Learn from experience and improve expertise
        
        Args:
            experience: Experience data including outcomes
        """
        self.memory.append({
            'timestamp': datetime.now().isoformat(),
            'experience': experience
        })
        
        # Improve expertise based on successful experiences
        if experience.get('success', False):
            self.expertise_level = min(1.0, self.expertise_level + 0.05)
        
        # Keep memory manageable
        if len(self.memory) > 1000:
            self.memory = self.memory[-1000:]


class MasterAgent(BaseAgent):
    """
    Master agent coordinating multiple sub-agents
    Implements hierarchical decision-making and task distribution
    """
    
    def __init__(self, agent_id: str, config: Optional[Dict[str, Any]] = None):
        """
        Initialize master agent
        
        Args:
            agent_id: Unique identifier
            config: Optional configuration
        """
        super().__init__(agent_id, config)
        self.sub_agents: Dict[str, SubAgent] = {}
        self.task_queue = []
        self.results_history = []
        
    def register_sub_agent(self, sub_agent: SubAgent) -> None:
        """
        Register a sub-agent with the master
        
        Args:
            sub_agent: SubAgent instance to register
        """
        self.sub_agents[sub_agent.agent_id] = sub_agent
        
    def process(self, data: Any) -> Any:
        """
        Process data by coordinating sub-agents
        
        Args:
            data: Input data (typically multimodal market data)
            
        Returns:
            Aggregated results from all sub-agents
        """
        self.state = "coordinating"
        results = {}
        
        # Distribute tasks to appropriate sub-agents
        for agent_id, sub_agent in self.sub_agents.items():
            # Extract relevant data for each sub-agent's specialty
            agent_data = self._extract_relevant_data(data, sub_agent.specialty)
            if agent_data:
                result = sub_agent.process(agent_data)
                results[agent_id] = result
        
        # Aggregate results
        aggregated = self._aggregate_results(results)
        
        # Store in history
        self.results_history.append({
            'timestamp': datetime.now().isoformat(),
            'results': aggregated
        })
        
        # Keep history manageable
        if len(self.results_history) > 500:
            self.results_history = self.results_history[-500:]
        
        self.state = "idle"
        return aggregated
    
    def _extract_relevant_data(self, data: Any, specialty: str) -> Optional[Any]:
        """
        Extract data relevant to a specific specialty
        
        Args:
            data: Full dataset
            specialty: Agent specialty
            
        Returns:
            Relevant data subset or None
        """
        if not isinstance(data, dict):
            return data
        
        if specialty == 'price_analysis' and 'prices' in data:
            return {'prices': data['prices']}
        elif specialty == 'volume_analysis' and 'volumes' in data:
            return {'volumes': data['volumes']}
        elif specialty == 'sentiment_analysis' and 'sentiment_scores' in data:
            return {'sentiment_scores': data['sentiment_scores']}
        
        return data
    
    def _aggregate_results(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """
        Aggregate results from multiple sub-agents
        
        Args:
            results: Dictionary of results from sub-agents
            
        Returns:
            Aggregated analysis
        """
        aggregated = {
            'timestamp': datetime.now().isoformat(),
            'sub_agent_count': len(results),
            'individual_results': results,
            'consensus': self._build_consensus(results)
        }
        
        return aggregated
    
    def _build_consensus(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build consensus from sub-agent results
        
        Args:
            results: Individual sub-agent results
            
        Returns:
            Consensus analysis
        """
        consensus = {
            'overall_trend': 'neutral',
            'confidence': 0.0,
            'signals': []
        }
        
        trends = []
        confidences = []
        
        for agent_id, result in results.items():
            if 'result' in result:
                agent_result = result['result']
                if 'trend' in agent_result:
                    trends.append(agent_result['trend'])
                if 'confidence' in result:
                    confidences.append(result['confidence'])
        
        # Determine overall trend
        if trends:
            # Simple majority voting
            trend_counts = {}
            for trend in trends:
                trend_counts[trend] = trend_counts.get(trend, 0) + 1
            consensus['overall_trend'] = max(trend_counts, key=trend_counts.get)
        
        # Calculate average confidence
        if confidences:
            consensus['confidence'] = sum(confidences) / len(confidences)
        
        return consensus
    
    def learn(self, experience: Dict[str, Any]) -> None:
        """
        Coordinate learning across all sub-agents
        
        Args:
            experience: Shared experience for learning
        """
        self.memory.append({
            'timestamp': datetime.now().isoformat(),
            'experience': experience
        })
        
        # Propagate learning to sub-agents
        for sub_agent in self.sub_agents.values():
            # Customize experience for each sub-agent's specialty
            specialized_exp = {
                **experience,
                'specialty_context': sub_agent.specialty
            }
            sub_agent.learn(specialized_exp)
        
        # Keep memory manageable
        if len(self.memory) > 1000:
            self.memory = self.memory[-1000:]
    
    def get_system_status(self) -> Dict[str, Any]:
        """Get comprehensive status of the master agent and all sub-agents"""
        return {
            'master_agent': self.get_state(),
            'sub_agents': {
                agent_id: agent.get_state()
                for agent_id, agent in self.sub_agents.items()
            },
            'total_results': len(self.results_history)
        }
