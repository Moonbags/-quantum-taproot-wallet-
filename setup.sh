#!/bin/bash
# Quantum Taproot Wallet Setup - NOT FINANCIAL ADVICE. Testnet first.
set -euo pipefail  # Exit on error, undefined vars

INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

echo "=== Quantum Taproot Wallet Setup ==="
echo ""
echo "Choose setup mode:"
echo "  1) Standard Taproot (hot/cold/recovery keys)"
echo "  2) Quantum Vault (experimental - requires Node.js)"
echo ""
read -p "Mode (1/2): " MODE

if [[ "$MODE" == "2" ]]; then
    echo ""
    echo "🔬 Quantum Vault Mode (Experimental)"
    echo ""
    echo "This mode creates a quantum-resistant vault using:"
    echo "  - Winternitz One-Time Signatures (hash-based)"
    echo "  - Merkle tree commitment (256 keys)"
    echo "  - SHA-256 (128-bit quantum security)"
    echo ""
    echo "⚠️  WARNING: Experimental implementation"
    echo "    - For educational/testing purposes only"
    echo "    - Use testnet/signet only"
    echo "    - Each key can only be used ONCE"
    echo ""
    read -p "Continue? (y/N): " CONTINUE
    
    if [[ "$CONTINUE" != "y" ]]; then
        echo "Setup cancelled"
        exit 0
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js is required for quantum vault mode"
        echo "   Install from: https://nodejs.org/"
        exit 1
    fi
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing dependencies..."
        npm install
    fi
    
    # Run quantum vault demo
    echo ""
    echo "🔐 Generating quantum vault..."
    node -e "
    const { QuantumVault, createTaprootVaultCommitment } = require('./src/quantum-vault');
    const { TaprootDescriptorBuilder } = require('./src/taproot-descriptor');
    
    async function setup() {
        // Create vault with 256 one-time keys
        const vault = new QuantumVault(256, 16);
        await vault.initialize();
        
        // Get statistics
        const stats = vault.getStats();
        console.log('');
        console.log('✅ Quantum Vault Created');
        console.log(\`   Total keys: \${stats.totalKeys}\`);
        console.log(\`   Merkle root: \${stats.merkleRoot.substring(0, 16)}...\`);
        console.log(\`   Proof size: ~\${stats.proofSizeKB}KB\`);
        
        // Create Taproot commitment
        const commitment = createTaprootVaultCommitment(vault.getMerkleRoot());
        console.log('');
        console.log('📝 Taproot Commitment:');
        console.log(\`   Type: \${commitment.type}\`);
        console.log(\`   Root: \${commitment.merkleRoot.substring(0, 32)}...\`);
        
        // Build descriptor
        const builder = new TaprootDescriptorBuilder();
        builder.setInternalKey('${INTERNAL}');
        builder.addQuantumVault(vault.getMerkleRoot());
        
        const descriptorStr = builder.toDescriptorString();
        console.log('');
        console.log('🔑 Descriptor: ' + descriptorStr);
        console.log('');
        console.log('⚠️  IMPORTANT:');
        console.log('   - Save vault data securely (contains private keys)');
        console.log('   - Each key can only be used ONCE');
        console.log('   - After 256 spends, create a new vault');
        console.log('   - Test on testnet/signet first');
    }
    
    setup().catch(console.error);
    "
    
else
    echo ""
    echo "📝 Standard Taproot Mode"
    echo ""
    read -p "Hot xpub (m/86'/1'/0'/0/0): " HOT
    read -p "Cold xpub (m/86'/1'/0'/0/1): " COLD  
    read -p "Recovery xpub (m/86'/1'/0'/1/0): " RECOV
    read -p "Testnet? (y/N): " TESTNET

    [[ "$TESTNET" == "y" ]] && EXTRA="--testnet" || EXTRA=""

    BASE_DESC="tr(${INTERNAL},{or_d(pk_h(${HOT}),pk_h(${COLD}),and_v(v:pk_h(${RECOV}),older(1008)))})"

    echo "Validating descriptor..."
    bitcoin-cli $EXTRA getdescriptorinfo "$BASE_DESC" || { echo "Invalid descriptor"; exit 1; }

    CHECKSUM=$(bitcoin-cli $EXTRA getdescriptorinfo "$BASE_DESC" | jq -r '.checksum')
    DESC="${BASE_DESC}#${CHECKSUM}"

    echo "✅ Descriptor: $DESC"

    bitcoin-cli $EXTRA createwallet "qs" true true false true false
    bitcoin-cli $EXTRA -rpcwallet=qs -named importdescriptors "[{\"desc\":\"$DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\",\"internal\":false}]"

    ADDR=$(bitcoin-cli $EXTRA -rpcwallet=qs -named deriveaddresses descriptor="$DESC" range="[0,0]" | jq -r '.[0]')
    echo "💰 Fund this address: $ADDR"
    echo "📋 Save descriptor: $DESC"
fi
