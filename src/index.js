/**
 * Main entry point for Quantum Taproot Wallet library
 */

const { QuantumVault, createTaprootVaultCommitment } = require('./quantum-vault');
const { TaprootDescriptorBuilder, selectSpendingPath } = require('./taproot-descriptor');
const { WinternitzOTS, MerkleTree, sha256, hash256, generateRandomBytes } = require('./pq-crypto');

module.exports = {
  // Vault functionality
  QuantumVault,
  createTaprootVaultCommitment,
  
  // Taproot descriptor building
  TaprootDescriptorBuilder,
  selectSpendingPath,
  
  // Cryptographic primitives
  WinternitzOTS,
  MerkleTree,
  
  // Utility functions
  sha256,
  hash256,
  generateRandomBytes
};
