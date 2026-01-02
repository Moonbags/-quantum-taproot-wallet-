"""
Lifelong Learning System Module
Implements continuous learning and experience replay mechanisms
"""

from typing import Dict, List, Any, Optional
from datetime import datetime
import json
import random


class LifelongLearningSystem:
    """
    Implements lifelong learning capabilities for market analysis
    Features experience replay, adaptive strategies, and memory management
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize lifelong learning system
        
        Args:
            config: Optional configuration dictionary
        """
        self.config = config or {}
        self.memory_capacity = self.config.get('memory_capacity', 10000)
        self.replay_batch_size = self.config.get('replay_batch_size', 32)
        
        # Memory stores experiences
        self.experience_memory: List[Dict[str, Any]] = []
        self.learning_history: List[Dict[str, Any]] = []
        
        # Learning parameters
        self.learning_rate = self.config.get('learning_rate', 0.01)
        self.adaptation_factor = 1.0
        self.performance_metrics = {
            'total_experiences': 0,
            'successful_predictions': 0,
            'failed_predictions': 0,
            'accuracy': 0.0
        }
        
    def store_experience(self, experience: Dict[str, Any]) -> None:
        """
        Store a new experience in memory
        
        Args:
            experience: Experience dictionary containing:
                - state: Market state data
                - action: Action taken (analysis/prediction)
                - outcome: Actual outcome
                - reward: Reward/penalty from outcome
        """
        experience['timestamp'] = datetime.now().isoformat()
        experience['id'] = len(self.experience_memory)
        
        self.experience_memory.append(experience)
        self.performance_metrics['total_experiences'] += 1
        
        # Update performance metrics
        if experience.get('reward', 0) > 0:
            self.performance_metrics['successful_predictions'] += 1
        else:
            self.performance_metrics['failed_predictions'] += 1
        
        # Calculate accuracy
        total = (self.performance_metrics['successful_predictions'] + 
                self.performance_metrics['failed_predictions'])
        if total > 0:
            self.performance_metrics['accuracy'] = (
                self.performance_metrics['successful_predictions'] / total
            )
        
        # Manage memory capacity
        if len(self.experience_memory) > self.memory_capacity:
            self._prune_memory()
    
    def experience_replay(self, batch_size: Optional[int] = None) -> List[Dict[str, Any]]:
        """
        Retrieve a batch of experiences for replay learning
        
        Args:
            batch_size: Number of experiences to retrieve (uses default if None)
            
        Returns:
            List of sampled experiences
        """
        if not self.experience_memory:
            return []
        
        size = batch_size or self.replay_batch_size
        size = min(size, len(self.experience_memory))
        
        # Sample experiences with priority to recent and high-reward experiences
        sampled = self._priority_sampling(size)
        
        return sampled
    
    def _priority_sampling(self, size: int) -> List[Dict[str, Any]]:
        """
        Sample experiences with priority to valuable ones
        
        Args:
            size: Number of samples to retrieve
            
        Returns:
            List of sampled experiences
        """
        if len(self.experience_memory) <= size:
            return self.experience_memory.copy()
        
        # Calculate priorities based on recency and reward
        experiences_with_priority = []
        for i, exp in enumerate(self.experience_memory):
            # Priority = recency_score + reward_score
            recency_score = i / len(self.experience_memory)  # 0 to 1
            reward_score = max(0, exp.get('reward', 0))
            priority = recency_score + reward_score
            experiences_with_priority.append((priority, exp))
        
        # Sort by priority and take top experiences
        experiences_with_priority.sort(reverse=True, key=lambda x: x[0])
        
        # Mix of top priority and random for diversity
        top_half = size // 2
        random_half = size - top_half
        
        top_experiences = [exp for _, exp in experiences_with_priority[:top_half]]
        random_pool = experiences_with_priority[top_half:]
        random_experiences = random.sample(random_pool, min(random_half, len(random_pool)))
        random_experiences = [exp for _, exp in random_experiences]
        
        return top_experiences + random_experiences
    
    def _prune_memory(self) -> None:
        """
        Prune memory to maintain capacity
        Keeps most valuable experiences
        """
        # Keep 80% of capacity after pruning
        target_size = int(self.memory_capacity * 0.8)
        
        # Calculate importance scores for all experiences
        scored_experiences = []
        for exp in self.experience_memory:
            importance = self._calculate_importance(exp)
            scored_experiences.append((importance, exp))
        
        # Sort by importance and keep top experiences
        scored_experiences.sort(reverse=True, key=lambda x: x[0])
        self.experience_memory = [exp for _, exp in scored_experiences[:target_size]]
    
    def _calculate_importance(self, experience: Dict[str, Any]) -> float:
        """
        Calculate importance score for an experience
        
        Args:
            experience: Experience to score
            
        Returns:
            Importance score
        """
        # Factors: reward, recency, uniqueness
        reward_score = abs(experience.get('reward', 0))
        
        # Recency (newer is more important)
        try:
            timestamp = datetime.fromisoformat(experience['timestamp'])
            age_seconds = (datetime.now() - timestamp).total_seconds()
            recency_score = 1.0 / (1.0 + age_seconds / 3600)  # Decay over hours
        except (ValueError, KeyError, TypeError):
            recency_score = 0.5
        
        # Combine scores
        importance = reward_score * 0.6 + recency_score * 0.4
        return importance
    
    def learn_from_batch(self, batch: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
        """
        Learn from a batch of experiences
        
        Args:
            batch: Batch of experiences (uses replay if None)
            
        Returns:
            Learning results
        """
        if batch is None:
            batch = self.experience_replay()
        
        if not batch:
            return {'status': 'no_experiences', 'learning_updates': 0}
        
        learning_results = {
            'batch_size': len(batch),
            'learning_updates': 0,
            'insights': [],
            'timestamp': datetime.now().isoformat()
        }
        
        # Analyze patterns in batch
        patterns = self._extract_patterns(batch)
        learning_results['patterns'] = patterns
        
        # Update strategies based on patterns
        strategy_updates = self._update_strategies(patterns)
        learning_results['strategy_updates'] = strategy_updates
        learning_results['learning_updates'] = len(strategy_updates)
        
        # Store learning event
        self.learning_history.append(learning_results)
        
        # Adapt learning rate based on performance
        self._adapt_learning_rate()
        
        return learning_results
    
    def _extract_patterns(self, batch: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Extract patterns from a batch of experiences
        
        Args:
            batch: List of experiences
            
        Returns:
            Discovered patterns
        """
        patterns = {
            'successful_strategies': [],
            'failed_strategies': [],
            'market_conditions': {},
            'action_outcomes': {}
        }
        
        for exp in batch:
            reward = exp.get('reward', 0)
            action = exp.get('action', {})
            state = exp.get('state', {})
            
            # Track successful vs failed strategies
            strategy = action.get('type', 'unknown')
            if reward > 0:
                patterns['successful_strategies'].append(strategy)
            else:
                patterns['failed_strategies'].append(strategy)
            
            # Track market conditions
            market_condition = state.get('condition', 'unknown')
            if market_condition not in patterns['market_conditions']:
                patterns['market_conditions'][market_condition] = {
                    'count': 0,
                    'avg_reward': 0.0
                }
            patterns['market_conditions'][market_condition]['count'] += 1
            
            # Track action outcomes
            if strategy not in patterns['action_outcomes']:
                patterns['action_outcomes'][strategy] = {
                    'count': 0,
                    'total_reward': 0.0,
                    'success_rate': 0.0
                }
            patterns['action_outcomes'][strategy]['count'] += 1
            patterns['action_outcomes'][strategy]['total_reward'] += reward
        
        # Calculate success rates
        for strategy, data in patterns['action_outcomes'].items():
            if data['count'] > 0:
                data['avg_reward'] = data['total_reward'] / data['count']
                successful = sum(1 for s in patterns['successful_strategies'] if s == strategy)
                data['success_rate'] = successful / data['count']
        
        return patterns
    
    def _update_strategies(self, patterns: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Update strategies based on discovered patterns
        
        Args:
            patterns: Discovered patterns
            
        Returns:
            List of strategy updates
        """
        updates = []
        
        # Identify best performing strategies
        action_outcomes = patterns.get('action_outcomes', {})
        if action_outcomes:
            best_strategy = max(
                action_outcomes.items(),
                key=lambda x: x[1].get('avg_reward', 0)
            )
            updates.append({
                'type': 'prioritize_strategy',
                'strategy': best_strategy[0],
                'reason': f"Highest average reward: {best_strategy[1]['avg_reward']:.3f}"
            })
        
        # Identify strategies to avoid
        worst_performers = [
            strategy for strategy, data in action_outcomes.items()
            if data.get('success_rate', 0) < 0.3 and data.get('count', 0) > 5
        ]
        for strategy in worst_performers:
            updates.append({
                'type': 'deprioritize_strategy',
                'strategy': strategy,
                'reason': f"Low success rate: {action_outcomes[strategy]['success_rate']:.2%}"
            })
        
        return updates
    
    def _adapt_learning_rate(self) -> None:
        """Adapt learning rate based on recent performance"""
        if len(self.learning_history) < 5:
            return
        
        # Check trend in recent learning events
        recent = self.learning_history[-5:]
        update_counts = [event.get('learning_updates', 0) for event in recent]
        avg_updates = sum(update_counts) / len(update_counts)
        
        # Increase learning rate if making good progress
        if avg_updates > 3:
            self.learning_rate = min(0.1, self.learning_rate * 1.1)
        # Decrease if stagnant
        elif avg_updates < 1:
            self.learning_rate = max(0.001, self.learning_rate * 0.9)
        
        # Update adaptation factor
        self.adaptation_factor = 1.0 + (self.learning_rate * 10)
    
    def get_insights(self) -> Dict[str, Any]:
        """
        Get insights from accumulated learning
        
        Returns:
            Learning insights and recommendations
        """
        insights = {
            'performance_metrics': self.performance_metrics.copy(),
            'learning_rate': self.learning_rate,
            'adaptation_factor': self.adaptation_factor,
            'memory_usage': len(self.experience_memory),
            'memory_capacity': self.memory_capacity,
            'total_learning_events': len(self.learning_history)
        }
        
        # Add recent patterns if available
        if self.learning_history:
            recent_learning = self.learning_history[-1]
            insights['recent_patterns'] = recent_learning.get('patterns', {})
            insights['recent_updates'] = recent_learning.get('strategy_updates', [])
        
        return insights
    
    def export_knowledge(self) -> Dict[str, Any]:
        """
        Export learned knowledge for persistence
        
        Returns:
            Exportable knowledge dictionary
        """
        return {
            'version': '1.0.0',
            'exported_at': datetime.now().isoformat(),
            'performance_metrics': self.performance_metrics,
            'learning_rate': self.learning_rate,
            'adaptation_factor': self.adaptation_factor,
            'top_experiences': self._priority_sampling(100),
            'learning_history': self.learning_history[-50:],  # Last 50 events
            'insights': self.get_insights()
        }
    
    def import_knowledge(self, knowledge: Dict[str, Any]) -> None:
        """
        Import previously learned knowledge
        
        Args:
            knowledge: Knowledge dictionary from export_knowledge
        """
        if 'performance_metrics' in knowledge:
            self.performance_metrics = knowledge['performance_metrics']
        
        if 'learning_rate' in knowledge:
            self.learning_rate = knowledge['learning_rate']
        
        if 'adaptation_factor' in knowledge:
            self.adaptation_factor = knowledge['adaptation_factor']
        
        if 'top_experiences' in knowledge:
            self.experience_memory.extend(knowledge['top_experiences'])
        
        if 'learning_history' in knowledge:
            self.learning_history.extend(knowledge['learning_history'])
