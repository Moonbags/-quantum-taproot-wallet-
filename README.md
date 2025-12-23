# Quantum Taproot Wallet

A Bitcoin Taproot wallet with **quantum-resistant vault features** and time-locked recovery options. Implements Quantumroot-style Merkle tree commitments and hash-based signatures to protect against future quantum computer threats.

## 🔬 Quantum Resistance Features

### What Makes This Quantum-Resistant?

Bitcoin's current ECDSA/Schnorr signatures are vulnerable to [Shor's algorithm](https://en.wikipedia.org/wiki/Shor%27s_algorithm) on quantum computers. This wallet implements:

1. **Hash-Based Signatures (Winternitz OTS)**
   - One-time signature scheme resistant to quantum attacks
   - Security relies on SHA-256 preimage resistance
   - Grover's algorithm only provides quadratic speedup: 2^256 → 2^128 operations

2. **Merkle Tree Vaults (Quantumroot)**
   - Commit Merkle root of 256 public keys to blockchain
   - Reveal only specific key + proof when spending (~1.5KB)
   - Based on [bitjson's Quantumroot proposal](https://blog.bitjson.com/quantumroot/)

3. **Taproot Integration**
   - Standard Taproot for normal spending (fast, cheap)
   - Script path with quantum vault for quantum-secure spending (larger, but safe)
   - Flexible switching based on threat level

## 📋 Project Structure

```
quantum-taproot-wallet/
├── README.md              # Documentation
├── setup.sh               # Interactive setup script
├── package.json           # Node.js dependencies
├── LICENSE                # MIT license
├── src/
│   ├── index.js           # Main entry point
│   ├── pq-crypto.js       # Post-quantum crypto primitives
│   ├── quantum-vault.js   # Vault implementation
│   └── taproot-descriptor.js  # Taproot integration
└── test/
    ├── quantum-vault.test.js  # JavaScript test suite
    ├── test-descriptor.sh     # Descriptor tests
    └── verify.sh              # Security verification
```

## 🚀 Setup

### Prerequisites

- **Node.js** 14+ (for quantum vault mode)
- **Bitcoin Core** with descriptor wallet support (for standard mode)
- **jq** (for descriptor mode)

### Installation

```bash
# Clone repository
git clone https://github.com/Moonbags/-quantum-taproot-wallet-.git
cd -quantum-taproot-wallet-

# Install dependencies
npm install

# Run tests
npm test
```

### Quick Start

Run the interactive setup script:

```bash
./setup.sh
```

Choose between:
1. **Standard Taproot**: Traditional hot/cold/recovery keys (requires Bitcoin Core)
2. **Quantum Vault**: Experimental quantum-resistant vault (requires Node.js)

## 🧪 Testing

Run the complete test suite:

```bash
# JavaScript tests
npm test

# Descriptor validation
./test/test-descriptor.sh

# Security verification
./test/verify.sh
```

## 📚 Usage Examples

### Creating a Quantum Vault

```javascript
const { QuantumVault, createTaprootVaultCommitment } = require('./src');

async function createVault() {
    // Create vault with 256 one-time keys
    const vault = new QuantumVault(256, 16);
    await vault.initialize();
    
    // Get Merkle root (this goes on-chain)
    const merkleRoot = vault.getMerkleRoot();
    console.log('Merkle root:', merkleRoot.toString('hex'));
    
    // Get vault statistics
    const stats = vault.getStats();
    console.log('Stats:', stats);
    // {
    //   totalKeys: 256,
    //   usedKeys: 0,
    //   remainingKeys: 256,
    //   merkleRoot: '...',
    //   proofSizeKB: '0.25'
    // }
}
```

### Preparing a Spend

```javascript
// Prepare spending from vault (uses one key)
const spendData = vault.prepareSpend(0);

// Verify spend data
const isValid = QuantumVault.verifySpend(spendData);
console.log('Valid spend:', isValid);

// ⚠️ WARNING: Key 0 can now NEVER be used again!
```

### Building Taproot Descriptor

```javascript
const { TaprootDescriptorBuilder } = require('./src');

const builder = new TaprootDescriptorBuilder();

// Set internal key
builder.setInternalKey('YOUR_INTERNAL_KEY');

// Add quantum vault
builder.addQuantumVault(vault.getMerkleRoot());

// Add standard fallback keys
builder.addStandardKeyPaths(
    'HOT_KEY',
    'COLD_KEY', 
    'RECOVERY_KEY',
    1008 // timelock blocks
);

// Build descriptor
const descriptor = builder.build();
console.log(descriptor);
```

## ⚠️ Security Warnings

### Critical Limitations

1. **🧪 EXPERIMENTAL IMPLEMENTATION**
   - This is a reference/educational implementation
   - NOT audited for production use
   - Use testnet/signet only
   - Real funds require standardized PQ algorithms (e.g., NIST ML-DSA/Dilithium)

2. **🔑 ONE-TIME SIGNATURES**
   - Winternitz OTS keys can ONLY be used ONCE
   - Reusing a key completely breaks security
   - Vault automatically tracks used keys
   - After 256 spends, create a new vault

3. **💾 KEY MANAGEMENT**
   - Private keys must be encrypted at rest
   - Back up vault data before using any keys
   - Use hardware security modules for production
   - NEVER commit wallet files to version control

4. **⚛️ QUANTUM THREAT TIMELINE**
   - Current estimate: 2030-2035 for cryptographically relevant quantum computers
   - SHA-256 provides ~128-bit quantum security (Grover's algorithm)
   - Taproot exposes public keys on-chain (vulnerable to Shor's algorithm)
   - This vault protects via hash commitments (quantum-resistant)

5. **💰 TRANSACTION COSTS**
   - Quantum-secure spends are larger (~1.5KB for Merkle proof)
   - Higher transaction fees than standard Taproot
   - Consider using key path spend for normal operations
   - Reserve quantum vault for high-value/long-term storage

### Recommendations for Production

- [ ] Integrate NIST-standardized post-quantum algorithms (ML-DSA, XMSS)
- [ ] Professional security audit
- [ ] Hardware security module integration
- [ ] Extensive testnet/signet testing
- [ ] Multi-signature schemes for redundancy
- [ ] Monitor quantum computing developments
- [ ] Plan migration strategy for quantum threats

## 🔐 Security Model

### Threat Model

**Protected Against:**
- ✅ Shor's algorithm (breaks ECDSA/Schnorr in polynomial time)
- ✅ Future quantum computers attacking public keys
- ✅ Long-term storage threats (coins held past quantum breakthrough)

**Assumptions:**
- ⚠️ SHA-256 preimage resistance holds (128-bit quantum security)
- ⚠️ Private keys remain secret (no quantum advantage for key theft)
- ⚠️ Quantum computer timeline is 2030+ (need to transition before then)

**NOT Protected Against:**
- ❌ Traditional cryptographic attacks on stored private keys
- ❌ Social engineering, phishing, malware
- ❌ Implementation bugs (not audited)
- ❌ Side-channel attacks on key generation/storage

### Why Merkle Trees?

Standard Taproot exposes public keys on-chain, which are vulnerable to quantum attacks. Our approach:

1. **Commitment Phase**: Publish only Merkle root (hash of hashes)
2. **Spending Phase**: Reveal one leaf + proof to verify
3. **Quantum Security**: Attacker must break SHA-256 preimage resistance

Even with Grover's algorithm, breaking SHA-256 requires ~2^128 operations (infeasible).

## 🌐 Integration Examples

### Solana/DeFi Integration (Future)

This wallet architecture can extend to:
- Cross-chain quantum-secure bridges
- Solana vault programs with similar Merkle commitments
- DeFi protocols requiring quantum-resistant signatures
- Perps trading with quantum-secure settlement

### Bitcoin Signet Testing

```bash
# Switch to signet for testing
export BITCOIN_NETWORK="signet"

# Run setup with quantum vault
./setup.sh
# Choose option 2 (Quantum Vault)
```

## 📖 References

- [Quantumroot: Quantum-Secure Vaults for Bitcoin Cash](https://blog.bitjson.com/quantumroot/) - bitjson
- [NIST Post-Quantum Cryptography Standards](https://csrc.nist.gov/Projects/post-quantum-cryptography)
- [Taproot BIP 341](https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki)
- [Winternitz OTS](https://en.wikipedia.org/wiki/Hash-based_cryptography#Winternitz_signature)
- [The Taproot Quantum Problem](https://www.youtube.com/watch?v=l9xC81Z0UDQ)

## 📄 License

MIT License - Copyright (c) 2025 Moonbags

See [LICENSE](LICENSE) for details.

## ⚡ NOT FINANCIAL ADVICE

**Test on testnet first.** This software is provided as-is without warranty. Use at your own risk.

