# Quantum Taproot Wallet

A Bitcoin Taproot wallet with quantum-resistant features, post-quantum signature integration, and Merkle-based vault security.

## Features

- **Quantum-Secure Vaults**: SHA256/128-bit secure Merkle root commitment system
- **Post-Quantum Signatures**: ML-DSA (CRYSTALS-Dilithium) and Falcon integration
- **Taproot Descriptors**: Multi-path spending with classical and post-quantum options
- **Efficient Sweeps**: Optimized vault sweeps targeting ~1.5KB per UTXO
- **Testnet Ready**: Full signet test suite included

## Project Structure

```
quantum-taproot-wallet/
├── src/
│   ├── quantum-vault.js      # Merkle root vaults (SHA256/128-bit quantum secure)
│   ├── descriptors.js        # Taproot output descriptors w/ post-quantum scripts
│   ├── signatures.js         # ML-DSA/Falcon integration for spends
│   └── sweep.js              # Efficient vault sweeps (~1.5KB/UTXO)
├── setup.sh                  # Full environment + dependencies
├── test/
│   ├── testnet-descriptor.sh # Signet test suite
│   ├── verify.sh            # Merkle path verification
│   └── quantum-bench.js     # Performance benchmarks
└── README.md                 # Complete docs + testnet examples
```

## Quick Start

### 1. Environment Setup

Run the setup script to configure your quantum taproot wallet:

```bash
./setup.sh
```

This will:
- Prompt for hot, cold, and recovery xpubs
- Generate a Taproot descriptor with timelock recovery
- Create a watch-only wallet in Bitcoin Core
- Derive your first receiving address

### 2. Run Tests

#### Merkle Vault Verification
```bash
cd test
./verify.sh
```

#### Signet Descriptor Tests
```bash
cd test
./testnet-descriptor.sh
```

#### Performance Benchmarks
```bash
cd test
node quantum-bench.js
```

## Architecture

### Quantum-Secure Vaults

The vault system uses Merkle trees with SHA256 hashing to provide 128-bit quantum security (birthday bound attack resistance):

```javascript
const vault = require('./src/quantum-vault');

// Create vault from UTXOs
const myVault = vault.createVault([
  { txid: '...', vout: 0, amount: 100000, script: '...' },
  { txid: '...', vout: 1, amount: 200000, script: '...' }
]);

// Get spending proof for specific UTXO
const proof = vault.getSpendingProof(myVault, 0);

// Verify proof
const isValid = vault.verifySpendingProof(proof);
```

### Post-Quantum Signatures

Support for NIST-standardized post-quantum signature schemes:

```javascript
const signatures = require('./src/signatures');

// Generate ML-DSA key pair (NIST Level 3)
const keyPair = signatures.generateMLDSAKeyPair('ml-dsa-65');

// Sign transaction
const sig = signatures.signTransaction(tx, 0, keyPair, scriptPubKey, amount);

// Verify signature
const isValid = signatures.verifyTransaction(sig, tx, scriptPubKey, amount);
```

**Supported Schemes:**
- **ML-DSA** (CRYSTALS-Dilithium): NIST Levels 2, 3, 5 (2.4KB - 4.6KB signatures)
- **Falcon**: NIST Levels 1, 5 (666B - 1.3KB signatures, most compact)

### Taproot Descriptors

Hybrid descriptors supporting multiple spending paths:

```javascript
const descriptors = require('./src/descriptors');

// Create hybrid descriptor
const descriptor = descriptors.createHybridDescriptor({
  hotKey: '02...',      // Hot wallet key
  coldKey: '03...',     // Cold storage key
  pqKey: 'abc...',      // Post-quantum public key
  recoveryKey: '04...', // Timelock recovery key
  timelockBlocks: 1008  // ~1 week timelock
});

// Spending paths:
// 1. Key path (most efficient, Schnorr signature)
// 2. Post-quantum path (ML-DSA signature)
// 3. Classical multisig (2-of-2)
// 4. Timelock recovery (after 1008 blocks)
```

### Vault Sweeps

Efficient batched sweeping with fee optimization:

```javascript
const sweep = require('./src/sweep');

// Create sweep transaction
const sweepTx = sweep.createSweepTransaction(
  myVault,
  'tb1p...',  // Destination address
  keyPair,
  { feeRate: 10, maxInputs: 50 }
);

// Sign and broadcast
const signed = sweep.signSweepTransaction(sweepTx, myVault, keyPair);
const txHex = sweep.serializeTransaction(signed);
```

**Performance:**
- Key path spend: ~57 vbytes/input
- Script path (ML-DSA-65): ~241 vbytes/input
- Target efficiency: ~1.5KB/UTXO with batching

## Testnet Examples

### Signet Faucet Addresses

1. Run the setup script with testnet mode
2. Get your first address:
   ```bash
   bitcoin-cli -signet -rpcwallet=qs getnewaddress
   ```
3. Fund from signet faucet: https://signetfaucet.com
4. Monitor transactions:
   ```bash
   bitcoin-cli -signet -rpcwallet=qs listtransactions
   ```

### Sample Descriptor

```
tr(0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0,{
  pk(02a5c7...),                           # Hot key
  pk(03b6d8...),                           # Cold key
  and_v(v:pk(04c7d8...),older(1008))      # Recovery after 1008 blocks
})#checksum
```

## Security Considerations

### Quantum Resistance

- **Merkle vaults**: 128-bit quantum security via SHA256 birthday bound
- **Post-quantum signatures**: NIST-approved ML-DSA and Falcon schemes
- **Hybrid approach**: Combine classical and post-quantum for defense in depth

### Best Practices

1. **Test on signet/testnet first** - Never use mainnet for testing
2. **Secure key management** - Store post-quantum keys offline
3. **Verify descriptors** - Always validate with `bitcoin-cli getdescriptorinfo`
4. **Backup recovery paths** - Document timelock recovery procedures
5. **Fee optimization** - Use key path when quantum resistance not required

### Performance Trade-offs

| Spend Type | Size | Security | Use Case |
|------------|------|----------|----------|
| Key path | ~64 bytes | Classical (Schnorr) | Day-to-day spends |
| Falcon-512 | ~666 bytes | NIST-1 PQ | Compact quantum-resistant |
| ML-DSA-65 | ~2.4KB | NIST-3 PQ | Balanced PQ security |
| ML-DSA-87 | ~4.6KB | NIST-5 PQ | Maximum PQ security |

## Development

### Prerequisites

- Node.js (for JavaScript tools)
- Bitcoin Core 24.0+ (for descriptor wallet support)
- jq (for JSON parsing in bash scripts)

### Running Benchmarks

```bash
cd test
node quantum-bench.js
```

This will benchmark:
- Vault creation performance
- Merkle proof generation/verification
- Post-quantum signature operations
- Sweep transaction efficiency

## License

MIT License - See LICENSE file for details

## Disclaimer

⚠️ **NOT FINANCIAL ADVICE**

This is experimental software implementing cutting-edge cryptography. While the post-quantum signature schemes (ML-DSA, Falcon) are NIST-approved, their integration with Bitcoin is non-standard and requires custom opcodes or witness programs that may not be supported by the Bitcoin network.

**Use at your own risk. Test thoroughly on testnet before any mainnet use.**

## References

- [BIP 341](https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki) - Taproot
- [BIP 386](https://github.com/bitcoin/bips/blob/master/bip-0386.mediawiki) - Output Descriptors for tr()
- [NIST PQC](https://csrc.nist.gov/projects/post-quantum-cryptography) - Post-Quantum Cryptography
- [ML-DSA](https://csrc.nist.gov/pubs/fips/204/ipd) - Module-Lattice Digital Signature Algorithm
- [Falcon](https://falcon-sign.info/) - Fast Fourier Lattice-based Compact Signatures
