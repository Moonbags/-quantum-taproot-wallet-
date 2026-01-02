"""
Market Trend Analysis System
Inspired by LeanAgent framework with master/sub-agent architecture
"""

from .agents import MasterAgent, SubAgent, BaseAgent
from .data_processor import MultimodalDataProcessor
from .learning import LifelongLearningSystem
from .trend_analyzer import TrendAnalyzer

__version__ = '1.0.0'
__all__ = [
    'MasterAgent',
    'SubAgent',
    'BaseAgent',
    'MultimodalDataProcessor',
    'LifelongLearningSystem',
    'TrendAnalyzer',
]
