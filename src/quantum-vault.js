/**
 * Quantum-Resistant Vault Implementation
 * 
 * Implements Quantumroot-style vaults for Bitcoin:
 * - Commits Merkle root of multiple post-quantum public keys to blockchain
 * - Reveals only the specific key path needed for spending
 * - Provides ~128-bit quantum security via SHA-256 hash functions
 * 
 * Based on concepts from: https://blog.bitjson.com/quantumroot/
 * 
 * VAULT STRUCTURE:
 * 1. Generate N post-quantum key pairs (e.g., W-OTS)
 * 2. Create Merkle tree from public key hashes
 * 3. Commit Merkle root to Bitcoin via Taproot
 * 4. When spending, reveal: leaf public key + Merkle proof (~1.5KB for 256 leaves)
 * 
 * SECURITY: Quantum computer needs to break SHA-256 preimage resistance
 * (Grover's algorithm provides only quadratic speedup: 2^256 → 2^128 operations)
 */

const { WinternitzOTS, MerkleTree, hash256, generateRandomBytes } = require('./pq-crypto');

class QuantumVault {
  /**
   * Create a new quantum-resistant vault
   * @param {number} numKeys - Number of one-time keys to generate (default: 256)
   * @param {number} winternitzParam - Winternitz parameter (default: 16)
   */
  constructor(numKeys = 256, winternitzParam = 16) {
    this.numKeys = numKeys;
    this.wots = new WinternitzOTS(winternitzParam);
    this.privateKeys = [];
    this.publicKeys = [];
    this.publicKeyHashes = [];
    this.merkleTree = null;
    this.usedKeys = new Set(); // Track which keys have been used (ONE-TIME signatures!)
  }

  /**
   * Initialize vault by generating all key pairs and Merkle tree
   */
  async initialize() {
    console.log(`Generating ${this.numKeys} quantum-resistant key pairs...`);
    
    for (let i = 0; i < this.numKeys; i++) {
      // Generate W-OTS key pair
      const privateKey = this.wots.generatePrivateKey();
      const publicKey = this.wots.derivePublicKey(privateKey);
      const publicKeyHash = this.wots.getPublicKeyHash(publicKey);
      
      this.privateKeys.push(privateKey);
      this.publicKeys.push(publicKey);
      this.publicKeyHashes.push(publicKeyHash);
      
      if ((i + 1) % 50 === 0) {
        console.log(`  Generated ${i + 1}/${this.numKeys} keys...`);
      }
    }

    // Build Merkle tree from public key hashes
    this.merkleTree = new MerkleTree(this.publicKeyHashes);
    
    console.log('✅ Vault initialized');
    console.log(`   Merkle root: ${this.getMerkleRoot().toString('hex')}`);
    console.log(`   Proof size: ~${MerkleTree.getProofSize(this.numKeys)} bytes`);
    
    return this.getMerkleRoot();
  }

  /**
   * Get Merkle root (this is what gets committed to the blockchain)
   */
  getMerkleRoot() {
    if (!this.merkleTree) {
      throw new Error('Vault not initialized. Call initialize() first.');
    }
    return this.merkleTree.getRoot();
  }

  /**
   * Get the next unused key index
   */
  getNextKeyIndex() {
    for (let i = 0; i < this.numKeys; i++) {
      if (!this.usedKeys.has(i)) {
        return i;
      }
    }
    throw new Error('All keys have been used! Generate a new vault.');
  }

  /**
   * Prepare spending data for a specific key index
   * Returns data needed to prove ownership and spend from vault
   */
  prepareSpend(keyIndex) {
    if (keyIndex < 0 || keyIndex >= this.numKeys) {
      throw new Error(`Invalid key index: ${keyIndex}`);
    }

    if (this.usedKeys.has(keyIndex)) {
      throw new Error(`Key ${keyIndex} already used! W-OTS keys can only be used ONCE.`);
    }

    // Mark key as used (CRITICAL for security)
    this.usedKeys.add(keyIndex);

    const publicKey = this.publicKeys[keyIndex];
    const publicKeyHash = this.publicKeyHashes[keyIndex];
    const proof = this.merkleTree.getProof(keyIndex);

    return {
      keyIndex,
      publicKey,
      publicKeyHash,
      merkleProof: proof,
      merkleRoot: this.getMerkleRoot(),
      // In real implementation, this would include the W-OTS signature
      // For now, we just return the structure
    };
  }

  /**
   * Verify spending data is valid
   */
  static verifySpend(spendData) {
    const { publicKeyHash, merkleProof, merkleRoot } = spendData;
    
    // Verify Merkle proof
    const isValid = MerkleTree.verifyProof(publicKeyHash, merkleProof, merkleRoot);
    
    return isValid;
  }

  /**
   * Export vault data (WARNING: Contains private keys!)
   * 
   * SECURITY: In production, this function MUST encrypt private keys
   * before export. Never store unencrypted private keys.
   * 
   * @param {string} encryptionKey - (Not implemented) Encryption key for private data
   * @returns {Object} Vault data (currently unencrypted - FOR DEMO ONLY)
   */
  exportVault(encryptionKey = null) {
    if (!encryptionKey) {
      console.warn('⚠️  WARNING: Exporting unencrypted private keys!');
      console.warn('   This is ONLY safe for testing/demo purposes.');
      console.warn('   Production code MUST encrypt private keys before export.');
    }
    
    // TODO: Implement encryption using encryptionKey parameter
    // For production: use AES-256-GCM or similar authenticated encryption
    
    return {
      numKeys: this.numKeys,
      merkleRoot: this.getMerkleRoot().toString('hex'),
      usedKeys: Array.from(this.usedKeys),
      // SECURITY WARNING: Private keys exported in plaintext (demo only!)
      privateKeys: this.privateKeys.map(pk => pk.map(buf => buf.toString('hex'))),
      publicKeyHashes: this.publicKeyHashes.map(h => h.toString('hex')),
      _encrypted: false,
      _warning: 'UNENCRYPTED - DO NOT USE WITH REAL FUNDS'
    };
  }

  /**
   * Get vault statistics
   */
  getStats() {
    const used = this.usedKeys.size;
    const remaining = this.numKeys - used;
    const proofSize = MerkleTree.getProofSize(this.numKeys);
    
    return {
      totalKeys: this.numKeys,
      usedKeys: used,
      remainingKeys: remaining,
      merkleRoot: this.getMerkleRoot().toString('hex'),
      proofSizeBytes: proofSize,
      proofSizeKB: (proofSize / 1024).toFixed(2),
      utilizationPercent: ((used / this.numKeys) * 100).toFixed(2)
    };
  }
}

/**
 * Create a Bitcoin Taproot commitment to a quantum vault
 * This integrates the vault Merkle root into a Taproot output
 */
function createTaprootVaultCommitment(vaultMerkleRoot) {
  // In a real implementation, this would:
  // 1. Use the vault Merkle root as part of the Taproot script tree
  // 2. Create a spending condition that requires revealing a valid Merkle proof
  // 3. Return a Taproot address that commits to this vault
  
  // For now, return a structure representing the commitment
  return {
    type: 'taproot_vault',
    merkleRoot: vaultMerkleRoot.toString('hex'),
    commitment: hash256(Buffer.concat([
      Buffer.from('QUANTUM_VAULT', 'utf8'),
      vaultMerkleRoot
    ])).toString('hex'),
    // Real implementation would include Taproot address
    note: 'Use with Taproot script path spend to reveal Merkle proof'
  };
}

module.exports = {
  QuantumVault,
  createTaprootVaultCommitment
};
