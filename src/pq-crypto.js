/**
 * Post-Quantum Cryptography Utilities
 * 
 * This module provides quantum-resistant cryptographic primitives:
 * - Hash-based signatures (XMSS-like)
 * - Merkle tree construction for Quantumroot vaults
 * - SHA-256 based operations (128-bit quantum security)
 * 
 * SECURITY NOTE: This is a reference implementation. For production use,
 * integrate standardized post-quantum algorithms (e.g., NIST ML-DSA/Dilithium).
 */

const crypto = require('crypto');

/**
 * Hash function using SHA-256 (provides ~128-bit quantum security via Grover's algorithm)
 */
function sha256(data) {
  return crypto.createHash('sha256').update(data).digest();
}

/**
 * Double SHA-256 (Bitcoin standard)
 */
function hash256(data) {
  return sha256(sha256(data));
}

/**
 * Generate a cryptographically secure random value
 */
function generateRandomBytes(length = 32) {
  return crypto.randomBytes(length);
}

/**
 * Winternitz One-Time Signature (W-OTS) - simplified hash-based signature
 * Quantum-resistant as it relies only on hash function preimage resistance
 * 
 * WARNING: Each key pair can only sign ONE message. Reuse breaks security.
 */
class WinternitzOTS {
  constructor(w = 16) {
    this.w = w; // Winternitz parameter (affects signature size vs security)
    this.n = 32; // Hash output size (256 bits)
  }

  /**
   * Generate a W-OTS private key (array of random values)
   */
  generatePrivateKey(messageLength = 32) {
    const t = Math.ceil((messageLength * 8) / Math.log2(this.w));
    const checksumLength = Math.ceil(Math.log2(t * (this.w - 1)) / Math.log2(this.w));
    const totalLength = t + checksumLength;
    
    const privateKey = [];
    for (let i = 0; i < totalLength; i++) {
      privateKey.push(generateRandomBytes(this.n));
    }
    
    return privateKey;
  }

  /**
   * Derive public key from private key by hashing w times
   */
  derivePublicKey(privateKey) {
    const publicKey = [];
    
    for (let i = 0; i < privateKey.length; i++) {
      let hash = privateKey[i];
      for (let j = 0; j < this.w - 1; j++) {
        hash = sha256(hash);
      }
      publicKey.push(hash);
    }
    
    return publicKey;
  }

  /**
   * Compute public key hash (commitment)
   */
  getPublicKeyHash(publicKey) {
    const concatenated = Buffer.concat(publicKey);
    return hash256(concatenated);
  }
}

/**
 * Merkle Tree implementation for Quantumroot-style vaults
 * Allows committing to multiple public keys and revealing only the one needed
 */
class MerkleTree {
  constructor(leaves) {
    this.leaves = leaves.map(leaf => Buffer.isBuffer(leaf) ? leaf : Buffer.from(leaf, 'hex'));
    this.tree = this.buildTree(this.leaves);
  }

  /**
   * Build Merkle tree from leaves
   */
  buildTree(leaves) {
    if (leaves.length === 0) {
      throw new Error('Cannot build tree with no leaves');
    }

    let currentLevel = leaves.map(leaf => hash256(leaf));
    const tree = [currentLevel];

    while (currentLevel.length > 1) {
      const nextLevel = [];
      
      for (let i = 0; i < currentLevel.length; i += 2) {
        if (i + 1 < currentLevel.length) {
          const combined = Buffer.concat([currentLevel[i], currentLevel[i + 1]]);
          nextLevel.push(hash256(combined));
        } else {
          // Odd number of nodes, hash with itself
          const combined = Buffer.concat([currentLevel[i], currentLevel[i]]);
          nextLevel.push(hash256(combined));
        }
      }
      
      tree.push(nextLevel);
      currentLevel = nextLevel;
    }

    return tree;
  }

  /**
   * Get Merkle root (commitment to all leaves)
   */
  getRoot() {
    return this.tree[this.tree.length - 1][0];
  }

  /**
   * Generate Merkle proof for a specific leaf
   */
  getProof(leafIndex) {
    const proof = [];
    let index = leafIndex;

    for (let level = 0; level < this.tree.length - 1; level++) {
      const currentLevel = this.tree[level];
      const isRightNode = index % 2 === 1;
      const siblingIndex = isRightNode ? index - 1 : index + 1;

      if (siblingIndex < currentLevel.length) {
        proof.push({
          hash: currentLevel[siblingIndex],
          position: isRightNode ? 'left' : 'right'
        });
      } else {
        // Odd number of nodes, sibling is self
        proof.push({
          hash: currentLevel[index],
          position: 'self'
        });
      }

      index = Math.floor(index / 2);
    }

    return proof;
  }

  /**
   * Verify Merkle proof
   */
  static verifyProof(leaf, proof, root) {
    let hash = hash256(Buffer.isBuffer(leaf) ? leaf : Buffer.from(leaf, 'hex'));

    for (const step of proof) {
      const sibling = step.hash;
      
      if (step.position === 'left') {
        hash = hash256(Buffer.concat([sibling, hash]));
      } else if (step.position === 'right') {
        hash = hash256(Buffer.concat([hash, sibling]));
      } else {
        // position === 'self'
        hash = hash256(Buffer.concat([hash, hash]));
      }
    }

    return hash.equals(root);
  }

  /**
   * Calculate approximate size of proof in bytes
   */
  static getProofSize(numLeaves) {
    const depth = Math.ceil(Math.log2(numLeaves));
    return depth * 32; // 32 bytes per hash in proof
  }
}

module.exports = {
  sha256,
  hash256,
  generateRandomBytes,
  WinternitzOTS,
  MerkleTree
};
