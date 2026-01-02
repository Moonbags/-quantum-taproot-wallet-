#!/bin/bash
# Setup script for Market Trend Analysis System

set -e

echo "========================================"
echo "Market Trend Analysis System - Setup"
echo "========================================"
echo ""

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
REQUIRED_VERSION="3.8"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "Error: Python 3.8 or higher is required. Found: $PYTHON_VERSION"
    exit 1
fi

echo "✓ Python version: $PYTHON_VERSION"
echo ""

# Navigate to market_analysis directory
cd "$(dirname "$0")/market_analysis"

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt --quiet

if [ $? -eq 0 ]; then
    echo "✓ Dependencies installed successfully"
else
    echo "Error: Failed to install dependencies"
    exit 1
fi

echo ""

# Setup .env file
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✓ .env file created"
    echo ""
    echo "⚠️  Please edit market_analysis/.env and add your API keys:"
    echo "   - ALPHA_VANTAGE_API_KEY"
    echo "   - NEWS_API_KEY"
    echo "   - GROK_API_KEY (optional)"
    echo "   - PINECONE_API_KEY (optional)"
else
    echo "✓ .env file already exists"
fi

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Configure API keys in market_analysis/.env"
echo "  2. Run the example: python3 market_analysis_example.py"
echo "  3. See market_analysis/README.md for documentation"
echo ""
