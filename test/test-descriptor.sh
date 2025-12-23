#!/bin/bash
# Test Taproot descriptor creation with quantum vault support
# Tests integration between quantum vault and Bitcoin descriptors

set -euo pipefail

echo "=== Quantum Taproot Descriptor Test ==="
echo ""

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required but not installed"
    exit 1
fi

echo "✅ Node.js found: $(node --version)"
echo ""

# Check if npm packages are installed
if [ ! -d "../node_modules" ]; then
    echo "📦 Installing dependencies..."
    cd .. && npm install && cd test
    echo ""
fi

# Run the JavaScript test suite
echo "🧪 Running quantum vault tests..."
echo ""
node quantum-vault.test.js

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All tests passed!"
    echo ""
    echo "📝 Quantum Vault Features Verified:"
    echo "   - Winternitz OTS key generation"
    echo "   - Merkle tree construction and proofs"
    echo "   - Quantum vault initialization"
    echo "   - One-time key usage enforcement"
    echo "   - Taproot descriptor integration"
    echo ""
    echo "🔐 Security Notes:"
    echo "   - SHA-256 provides ~128-bit quantum security (Grover's algorithm)"
    echo "   - Merkle proofs are ~256-512 bytes for typical vaults"
    echo "   - W-OTS keys are ONE-TIME USE only - reuse breaks security!"
    echo ""
else
    echo ""
    echo "❌ Tests failed"
    exit 1
fi
