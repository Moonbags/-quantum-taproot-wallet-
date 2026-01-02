"""
Market Trend Analysis System

A lightweight AI system for analyzing market trends using master and sub-agent 
architecture, inspired by the LeanAgent framework's SSSP approach.
"""

__version__ = '1.0.0'

from .agents.master_agent import MasterAgent
from .agents.text_agent import TextAgent
from .agents.vision_agent import VisionAgent
from .agents.video_agent import VideoAgent
from .data_processing.market_data import MarketDataProcessor
from .utils.lifelong_learning import LifelongLearning
from .config import config

__all__ = [
    'MasterAgent',
    'TextAgent',
    'VisionAgent',
    'VideoAgent',
    'MarketDataProcessor',
    'LifelongLearning',
    'config'
]
