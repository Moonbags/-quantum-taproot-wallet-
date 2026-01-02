"""
Configuration Module for Market Trend Analysis System
"""

from typing import Dict, Any

# Default configuration for the Market Trend Analysis System
DEFAULT_CONFIG: Dict[str, Any] = {
    # Agent configuration
    'agents': {
        'master': {
            'enabled': True,
            'coordination_strategy': 'consensus',
        },
        'sub_agents': [
            {
                'id': 'price_agent',
                'specialty': 'price_analysis',
                'enabled': True
            },
            {
                'id': 'volume_agent',
                'specialty': 'volume_analysis',
                'enabled': True
            },
            {
                'id': 'sentiment_agent',
                'specialty': 'sentiment_analysis',
                'enabled': True
            }
        ]
    },
    
    # Data processor configuration
    'data_processor': {
        'supported_types': ['price', 'volume', 'sentiment', 'technical', 'news'],
        'validation_enabled': True,
        'normalization_enabled': True
    },
    
    # Learning system configuration
    'learning': {
        'memory_capacity': 10000,
        'replay_batch_size': 32,
        'learning_rate': 0.01,
        'enable_experience_replay': True,
        'enable_adaptation': True
    },
    
    # Trend analyzer configuration
    'trend_analyzer': {
        'min_data_points': 3,
        'trend_threshold': 0.02,  # 2% change threshold
        'enable_pattern_detection': True,
        'confidence_threshold': 0.6
    },
    
    # System configuration
    'system': {
        'enable_logging': True,
        'log_level': 'INFO',
        'enable_history': True,
        'history_limit': 1000
    }
}


def get_config(custom_config: Dict[str, Any] = None) -> Dict[str, Any]:
    """
    Get configuration with optional custom overrides
    
    Args:
        custom_config: Custom configuration to override defaults
        
    Returns:
        Merged configuration
    """
    config = DEFAULT_CONFIG.copy()
    
    if custom_config:
        # Deep merge custom config
        config = _deep_merge(config, custom_config)
    
    return config


def _deep_merge(base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
    """
    Deep merge two dictionaries
    
    Args:
        base: Base dictionary
        override: Dictionary with override values
        
    Returns:
        Merged dictionary
    """
    result = base.copy()
    
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = _deep_merge(result[key], value)
        else:
            result[key] = value
    
    return result


# Example custom configurations

CONSERVATIVE_CONFIG = {
    'trend_analyzer': {
        'trend_threshold': 0.05,  # 5% - more conservative
        'confidence_threshold': 0.7
    },
    'learning': {
        'learning_rate': 0.005  # Slower learning
    }
}

AGGRESSIVE_CONFIG = {
    'trend_analyzer': {
        'trend_threshold': 0.01,  # 1% - more aggressive
        'confidence_threshold': 0.5
    },
    'learning': {
        'learning_rate': 0.02  # Faster learning
    }
}

MINIMAL_CONFIG = {
    'agents': {
        'sub_agents': [
            {
                'id': 'price_agent',
                'specialty': 'price_analysis',
                'enabled': True
            }
        ]
    },
    'learning': {
        'memory_capacity': 1000,
        'replay_batch_size': 16
    }
}
