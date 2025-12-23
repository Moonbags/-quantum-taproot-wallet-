#!/usr/bin/env node
/**
 * Quantum Vault - Merkle Root Vaults
 * SHA256/128-bit quantum secure Merkle tree implementation for UTXO commitments
 * 
 * Provides quantum-resistant storage using Merkle trees with SHA256 hashing
 * that maintains 128-bit quantum security (birthday bound attack resistance)
 */

const crypto = require('crypto');

/**
 * Create SHA256 hash (provides 128-bit quantum security via birthday bound)
 * @param {Buffer|string} data - Data to hash
 * @returns {Buffer} SHA256 hash
 */
function sha256(data) {
  return crypto.createHash('sha256').update(data).digest();
}

/**
 * Create Merkle tree leaf node from UTXO data
 * @param {Object} utxo - UTXO data {txid, vout, amount, script}
 * @returns {Buffer} Leaf hash
 */
function createLeaf(utxo) {
  const txidBuf = Buffer.from(utxo.txid, 'hex');
  const voutBuf = Buffer.alloc(4);
  voutBuf.writeUInt32LE(utxo.vout);
  const amountBuf = Buffer.alloc(8);
  amountBuf.writeBigUInt64LE(BigInt(utxo.amount));
  const scriptBuf = Buffer.from(utxo.script, 'hex');
  
  return sha256(Buffer.concat([txidBuf, voutBuf, amountBuf, scriptBuf]));
}

/**
 * Combine two nodes into parent node
 * @param {Buffer} left - Left child hash
 * @param {Buffer} right - Right child hash
 * @returns {Buffer} Parent hash
 */
function combineNodes(left, right) {
  // Lexicographically sort to prevent second preimage attacks
  const [first, second] = left.compare(right) < 0 ? [left, right] : [right, left];
  return sha256(Buffer.concat([first, second]));
}

/**
 * Build Merkle tree from UTXO leaves
 * @param {Buffer[]} leaves - Array of leaf hashes
 * @returns {Object} Merkle tree {root, layers}
 */
function buildMerkleTree(leaves) {
  if (leaves.length === 0) {
    throw new Error('Cannot build Merkle tree from empty leaves');
  }
  
  const layers = [leaves];
  let currentLayer = leaves;
  
  while (currentLayer.length > 1) {
    const nextLayer = [];
    
    for (let i = 0; i < currentLayer.length; i += 2) {
      if (i + 1 < currentLayer.length) {
        nextLayer.push(combineNodes(currentLayer[i], currentLayer[i + 1]));
      } else {
        // Odd number of nodes - promote last node
        nextLayer.push(currentLayer[i]);
      }
    }
    
    layers.push(nextLayer);
    currentLayer = nextLayer;
  }
  
  return {
    root: currentLayer[0],
    layers: layers
  };
}

/**
 * Generate Merkle proof for a specific leaf
 * @param {number} leafIndex - Index of the leaf to prove
 * @param {Object} tree - Merkle tree from buildMerkleTree
 * @returns {Object[]} Proof path [{hash, position}]
 */
function generateMerkleProof(leafIndex, tree) {
  const proof = [];
  let index = leafIndex;
  
  for (let i = 0; i < tree.layers.length - 1; i++) {
    const layer = tree.layers[i];
    const isRightNode = index % 2 === 1;
    
    if (isRightNode && index > 0) {
      proof.push({
        hash: layer[index - 1],
        position: 'left'
      });
    } else if (!isRightNode && index + 1 < layer.length) {
      proof.push({
        hash: layer[index + 1],
        position: 'right'
      });
    }
    
    index = Math.floor(index / 2);
  }
  
  return proof;
}

/**
 * Verify Merkle proof
 * @param {Buffer} leaf - Leaf hash to verify
 * @param {Object[]} proof - Merkle proof path
 * @param {Buffer} root - Expected Merkle root
 * @returns {boolean} True if proof is valid
 */
function verifyMerkleProof(leaf, proof, root) {
  let hash = leaf;
  
  for (const node of proof) {
    if (node.position === 'left') {
      hash = combineNodes(node.hash, hash);
    } else {
      hash = combineNodes(hash, node.hash);
    }
  }
  
  return hash.equals(root);
}

/**
 * Create quantum-secure vault from UTXOs
 * @param {Object[]} utxos - Array of UTXO objects
 * @returns {Object} Vault {root, tree, utxos, metadata}
 */
function createVault(utxos) {
  if (!Array.isArray(utxos) || utxos.length === 0) {
    throw new Error('UTXOs must be a non-empty array');
  }
  
  const leaves = utxos.map(createLeaf);
  const tree = buildMerkleTree(leaves);
  
  const totalAmount = utxos.reduce((sum, utxo) => sum + BigInt(utxo.amount), BigInt(0));
  
  return {
    root: tree.root.toString('hex'),
    tree: tree,
    utxos: utxos,
    metadata: {
      utxoCount: utxos.length,
      totalAmount: totalAmount.toString(),
      createdAt: new Date().toISOString(),
      quantumSecurity: '128-bit (SHA256 birthday bound)'
    }
  };
}

/**
 * Get spending proof for specific UTXO in vault
 * @param {Object} vault - Vault object from createVault
 * @param {number} utxoIndex - Index of UTXO to spend
 * @returns {Object} Spending proof {utxo, proof, root}
 */
function getSpendingProof(vault, utxoIndex) {
  if (utxoIndex < 0 || utxoIndex >= vault.utxos.length) {
    throw new Error('Invalid UTXO index');
  }
  
  const utxo = vault.utxos[utxoIndex];
  const leaf = createLeaf(utxo);
  const proof = generateMerkleProof(utxoIndex, vault.tree);
  
  return {
    utxo: utxo,
    leaf: leaf.toString('hex'),
    proof: proof.map(p => ({
      hash: p.hash.toString('hex'),
      position: p.position
    })),
    root: vault.root
  };
}

/**
 * Verify spending proof
 * @param {Object} spendingProof - Spending proof from getSpendingProof
 * @returns {boolean} True if proof is valid
 */
function verifySpendingProof(spendingProof) {
  const leaf = Buffer.from(spendingProof.leaf, 'hex');
  const proof = spendingProof.proof.map(p => ({
    hash: Buffer.from(p.hash, 'hex'),
    position: p.position
  }));
  const root = Buffer.from(spendingProof.root, 'hex');
  
  return verifyMerkleProof(leaf, proof, root);
}

module.exports = {
  sha256,
  createLeaf,
  combineNodes,
  buildMerkleTree,
  generateMerkleProof,
  verifyMerkleProof,
  createVault,
  getSpendingProof,
  verifySpendingProof
};
