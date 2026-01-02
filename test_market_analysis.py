#!/usr/bin/env python3
"""
Unit Tests for Market Trend Analysis System
Tests all major components of the LeanAgent-inspired architecture
"""

import unittest
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from market_analysis import (
    MasterAgent, SubAgent, BaseAgent,
    MultimodalDataProcessor,
    LifelongLearningSystem,
    TrendAnalyzer
)
from market_analysis.config import get_config, DEFAULT_CONFIG


class TestBaseAgent(unittest.TestCase):
    """Test BaseAgent functionality"""
    
    def test_agent_initialization(self):
        """Test agent initialization"""
        agent = SubAgent('test_agent', 'test_specialty')
        self.assertEqual(agent.agent_id, 'test_agent')
        self.assertEqual(agent.specialty, 'test_specialty')
        self.assertEqual(agent.state, 'initialized')
    
    def test_agent_state(self):
        """Test agent state management"""
        agent = SubAgent('test_agent', 'test_specialty')
        state = agent.get_state()
        self.assertIn('agent_id', state)
        self.assertIn('state', state)
        self.assertIn('created_at', state)


class TestSubAgent(unittest.TestCase):
    """Test SubAgent functionality"""
    
    def test_price_analysis(self):
        """Test price analysis processing"""
        agent = SubAgent('price_agent', 'price_analysis')
        data = {'prices': [100, 110, 120, 130, 140]}
        
        result = agent.process(data)
        
        self.assertEqual(result['specialty'], 'price_analysis')
        self.assertIn('result', result)
        self.assertIn('confidence', result)
        self.assertEqual(result['result']['trend'], 'upward')
    
    def test_volume_analysis(self):
        """Test volume analysis processing"""
        agent = SubAgent('volume_agent', 'volume_analysis')
        data = {'volumes': [1000, 1200, 1500, 1800, 2000]}
        
        result = agent.process(data)
        
        self.assertEqual(result['specialty'], 'volume_analysis')
        self.assertIn('result', result)
        self.assertEqual(result['result']['trend'], 'increasing')
    
    def test_sentiment_analysis(self):
        """Test sentiment analysis processing"""
        agent = SubAgent('sentiment_agent', 'sentiment_analysis')
        data = {'sentiment_scores': [0.6, 0.7, 0.8, 0.9, 0.95]}
        
        result = agent.process(data)
        
        self.assertEqual(result['specialty'], 'sentiment_analysis')
        self.assertIn('result', result)
        self.assertEqual(result['result']['mood'], 'bullish')
    
    def test_learning(self):
        """Test sub-agent learning"""
        agent = SubAgent('test_agent', 'test_specialty')
        
        initial_expertise = agent.expertise_level
        
        # Successful experience should increase expertise
        agent.learn({'success': True, 'data': 'test'})
        
        self.assertGreater(agent.expertise_level, initial_expertise)
        self.assertEqual(len(agent.memory), 1)


class TestMasterAgent(unittest.TestCase):
    """Test MasterAgent functionality"""
    
    def setUp(self):
        """Set up master agent with sub-agents"""
        self.master = MasterAgent('master_1')
        
        price_agent = SubAgent('price_agent', 'price_analysis')
        volume_agent = SubAgent('volume_agent', 'volume_analysis')
        sentiment_agent = SubAgent('sentiment_agent', 'sentiment_analysis')
        
        self.master.register_sub_agent(price_agent)
        self.master.register_sub_agent(volume_agent)
        self.master.register_sub_agent(sentiment_agent)
    
    def test_sub_agent_registration(self):
        """Test sub-agent registration"""
        self.assertEqual(len(self.master.sub_agents), 3)
        self.assertIn('price_agent', self.master.sub_agents)
        self.assertIn('volume_agent', self.master.sub_agents)
        self.assertIn('sentiment_agent', self.master.sub_agents)
    
    def test_coordination(self):
        """Test master agent coordination"""
        data = {
            'prices': [100, 110, 120],
            'volumes': [1000, 1200, 1500],
            'sentiment_scores': [0.5, 0.6, 0.7]
        }
        
        result = self.master.process(data)
        
        self.assertIn('sub_agent_count', result)
        self.assertIn('consensus', result)
        self.assertEqual(result['sub_agent_count'], 3)
    
    def test_consensus_building(self):
        """Test consensus building from sub-agents"""
        data = {
            'prices': [100, 110, 120, 130, 140],
            'volumes': [1000, 1200, 1500, 1800, 2000]
        }
        
        result = self.master.process(data)
        
        self.assertIn('consensus', result)
        consensus = result['consensus']
        self.assertIn('overall_trend', consensus)
        self.assertIn('confidence', consensus)
    
    def test_system_status(self):
        """Test system status reporting"""
        status = self.master.get_system_status()
        
        self.assertIn('master_agent', status)
        self.assertIn('sub_agents', status)
        self.assertEqual(len(status['sub_agents']), 3)


class TestMultimodalDataProcessor(unittest.TestCase):
    """Test MultimodalDataProcessor functionality"""
    
    def setUp(self):
        """Set up data processor"""
        self.processor = MultimodalDataProcessor()
    
    def test_price_processing(self):
        """Test price data processing"""
        data = {'price': [100, 110, 120, 130, 140]}
        result = self.processor.process(data)
        
        self.assertIn('processed_data', result)
        self.assertIn('validation', result)
    
    def test_multimodal_processing(self):
        """Test processing multiple data types"""
        data = {
            'price': [100, 110, 120],
            'volume': [1000, 1200, 1500],
            'sentiment': [0.5, 0.6, 0.7]
        }
        
        result = self.processor.process(data)
        
        self.assertIn('data_types_present', result)
        self.assertIn('processed_data', result)
    
    def test_validation(self):
        """Test data validation"""
        data = {'price': [100, 110, 120]}
        result = self.processor.process(data)
        
        self.assertIn('validation', result)
        validation = result['validation']
        self.assertIn('is_valid', validation)
    
    def test_batch_processing(self):
        """Test batch processing"""
        batch = [
            {'price': [100, 110]},
            {'price': [120, 130]},
            {'price': [140, 150]}
        ]
        
        results = self.processor.batch_process(batch)
        
        self.assertEqual(len(results), 3)
    
    def test_statistics(self):
        """Test processing statistics"""
        data = {'price': [100, 110, 120]}
        self.processor.process(data)
        
        stats = self.processor.get_statistics()
        
        self.assertIn('processed_count', stats)
        self.assertIn('error_count', stats)
        self.assertGreater(stats['processed_count'], 0)


class TestLifelongLearningSystem(unittest.TestCase):
    """Test LifelongLearningSystem functionality"""
    
    def setUp(self):
        """Set up learning system"""
        self.learning = LifelongLearningSystem({
            'memory_capacity': 100,
            'replay_batch_size': 10
        })
    
    def test_experience_storage(self):
        """Test storing experiences"""
        experience = {
            'state': {'price': 100},
            'action': {'type': 'buy'},
            'outcome': 'success',
            'reward': 1.0
        }
        
        self.learning.store_experience(experience)
        
        self.assertEqual(len(self.learning.experience_memory), 1)
    
    def test_experience_replay(self):
        """Test experience replay"""
        # Store multiple experiences
        for i in range(20):
            self.learning.store_experience({
                'state': {'price': 100 + i},
                'action': {'type': 'test'},
                'reward': i * 0.1
            })
        
        # Replay a batch
        batch = self.learning.experience_replay(5)
        
        self.assertEqual(len(batch), 5)
    
    def test_learning_from_batch(self):
        """Test learning from experiences"""
        # Store experiences
        for i in range(10):
            self.learning.store_experience({
                'state': {'price': 100},
                'action': {'type': 'strategy_A'},
                'reward': 1.0 if i % 2 == 0 else -0.5,
                'success': i % 2 == 0
            })
        
        # Learn from batch
        results = self.learning.learn_from_batch()
        
        self.assertIn('batch_size', results)
        self.assertIn('patterns', results)
        self.assertGreater(results['batch_size'], 0)
    
    def test_performance_metrics(self):
        """Test performance metrics tracking"""
        # Store successful experience
        self.learning.store_experience({
            'state': {'price': 100},
            'action': {'type': 'test'},
            'reward': 1.0
        })
        
        metrics = self.learning.performance_metrics
        
        self.assertIn('total_experiences', metrics)
        self.assertIn('accuracy', metrics)
        self.assertEqual(metrics['total_experiences'], 1)
    
    def test_knowledge_export_import(self):
        """Test knowledge export and import"""
        # Store some experiences
        for i in range(5):
            self.learning.store_experience({
                'state': {'price': 100 + i},
                'action': {'type': 'test'},
                'reward': 1.0
            })
        
        # Export knowledge
        knowledge = self.learning.export_knowledge()
        
        self.assertIn('performance_metrics', knowledge)
        self.assertIn('top_experiences', knowledge)
        
        # Create new system and import
        new_learning = LifelongLearningSystem()
        new_learning.import_knowledge(knowledge)
        
        self.assertEqual(
            new_learning.performance_metrics['total_experiences'],
            self.learning.performance_metrics['total_experiences']
        )


class TestTrendAnalyzer(unittest.TestCase):
    """Test TrendAnalyzer functionality"""
    
    def setUp(self):
        """Set up trend analyzer"""
        self.analyzer = TrendAnalyzer()
    
    def test_bullish_trend_detection(self):
        """Test detection of bullish trends"""
        processed_data = {
            'processed_data': {
                'price': {
                    'prices': [100, 110, 120, 130, 140]
                }
            }
        }
        
        result = self.analyzer.analyze(processed_data)
        
        self.assertIn('trends', result)
        self.assertIn('price', result['trends'])
        self.assertEqual(result['trends']['price']['direction'], 'upward')
    
    def test_bearish_trend_detection(self):
        """Test detection of bearish trends"""
        processed_data = {
            'processed_data': {
                'price': {
                    'prices': [140, 130, 120, 110, 100]
                }
            }
        }
        
        result = self.analyzer.analyze(processed_data)
        
        self.assertEqual(result['trends']['price']['direction'], 'downward')
    
    def test_recommendations(self):
        """Test recommendation generation"""
        processed_data = {
            'processed_data': {
                'price': {
                    'prices': [100, 110, 120, 130, 140]
                },
                'volume': {
                    'volumes': [1000, 1200, 1500, 1800, 2000]
                }
            }
        }
        
        result = self.analyzer.analyze(processed_data)
        
        self.assertIn('recommendations', result)
        self.assertGreater(len(result['recommendations']), 0)
    
    def test_pattern_detection(self):
        """Test pattern detection"""
        processed_data = {
            'processed_data': {
                'price': {
                    'prices': [100, 110, 120, 130, 140]  # Consistent uptrend
                }
            }
        }
        
        result = self.analyzer.analyze(processed_data)
        
        self.assertIn('patterns', result)
    
    def test_confidence_calculation(self):
        """Test confidence score calculation"""
        processed_data = {
            'processed_data': {
                'price': {
                    'prices': [100, 110, 120]
                }
            }
        }
        
        result = self.analyzer.analyze(processed_data)
        
        self.assertIn('confidence', result)
        self.assertGreaterEqual(result['confidence'], 0.0)
        self.assertLessEqual(result['confidence'], 1.0)
    
    def test_analysis_summary(self):
        """Test analysis summary"""
        # Perform some analyses
        for i in range(5):
            processed_data = {
                'processed_data': {
                    'price': {
                        'prices': [100 + i*10, 110 + i*10, 120 + i*10]
                    }
                }
            }
            self.analyzer.analyze(processed_data)
        
        summary = self.analyzer.get_summary()
        
        self.assertIn('total_analyses', summary)
        self.assertEqual(summary['total_analyses'], 5)


class TestConfiguration(unittest.TestCase):
    """Test configuration system"""
    
    def test_default_config(self):
        """Test default configuration"""
        config = get_config()
        
        self.assertIn('agents', config)
        self.assertIn('learning', config)
        self.assertIn('trend_analyzer', config)
    
    def test_custom_config(self):
        """Test custom configuration override"""
        custom = {
            'learning': {
                'learning_rate': 0.05
            }
        }
        
        config = get_config(custom)
        
        self.assertEqual(config['learning']['learning_rate'], 0.05)
        # Other defaults should be preserved
        self.assertIn('memory_capacity', config['learning'])


class TestIntegration(unittest.TestCase):
    """Integration tests for the complete system"""
    
    def test_complete_workflow(self):
        """Test complete analysis workflow"""
        # Initialize components
        master = MasterAgent('master')
        master.register_sub_agent(SubAgent('price_agent', 'price_analysis'))
        master.register_sub_agent(SubAgent('volume_agent', 'volume_analysis'))
        
        processor = MultimodalDataProcessor()
        learning = LifelongLearningSystem()
        analyzer = TrendAnalyzer()
        
        # Process data
        market_data = {
            'prices': [100, 110, 120, 130, 140],
            'volumes': [1000, 1200, 1500, 1800, 2000]
        }
        
        processed = processor.process(market_data)
        agent_results = master.process(market_data)
        analysis = analyzer.analyze(processed)
        
        # Store experience
        experience = {
            'state': processed,
            'action': {'type': 'analysis'},
            'reward': 1.0,
            'success': True
        }
        learning.store_experience(experience)
        
        # Verify results
        self.assertIn('processed_data', processed)
        self.assertIn('consensus', agent_results)
        self.assertIn('trends', analysis)
        self.assertEqual(learning.performance_metrics['total_experiences'], 1)


def run_tests():
    """Run all tests"""
    print("=" * 70)
    print("Market Trend Analysis System - Unit Tests")
    print("=" * 70 + "\n")
    
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add all test classes
    suite.addTests(loader.loadTestsFromTestCase(TestBaseAgent))
    suite.addTests(loader.loadTestsFromTestCase(TestSubAgent))
    suite.addTests(loader.loadTestsFromTestCase(TestMasterAgent))
    suite.addTests(loader.loadTestsFromTestCase(TestMultimodalDataProcessor))
    suite.addTests(loader.loadTestsFromTestCase(TestLifelongLearningSystem))
    suite.addTests(loader.loadTestsFromTestCase(TestTrendAnalyzer))
    suite.addTests(loader.loadTestsFromTestCase(TestConfiguration))
    suite.addTests(loader.loadTestsFromTestCase(TestIntegration))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Print summary
    print("\n" + "=" * 70)
    print("Test Summary")
    print("=" * 70)
    print(f"Tests run: {result.testsRun}")
    print(f"Successes: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print("=" * 70)
    
    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
