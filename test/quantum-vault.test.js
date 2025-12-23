/**
 * Test suite for Quantum Vault implementation
 * 
 * Run with: node test/quantum-vault.test.js
 */

const { QuantumVault, createTaprootVaultCommitment } = require('../src/quantum-vault');
const { TaprootDescriptorBuilder } = require('../src/taproot-descriptor');
const { MerkleTree, WinternitzOTS } = require('../src/pq-crypto');

// Simple test framework
class TestRunner {
  constructor() {
    this.tests = [];
    this.passed = 0;
    this.failed = 0;
  }

  test(name, fn) {
    this.tests.push({ name, fn });
  }

  async run() {
    console.log('🧪 Running Quantum Vault Tests\n');
    
    for (const test of this.tests) {
      try {
        await test.fn();
        this.passed++;
        console.log(`✅ ${test.name}`);
      } catch (error) {
        this.failed++;
        console.log(`❌ ${test.name}`);
        console.log(`   Error: ${error.message}`);
      }
    }
    
    console.log(`\n📊 Results: ${this.passed} passed, ${this.failed} failed`);
    
    if (this.failed > 0) {
      process.exit(1);
    }
  }
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

function assertEqual(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(message || `Expected ${expected}, got ${actual}`);
  }
}

// Tests
const runner = new TestRunner();

runner.test('WinternitzOTS key generation', () => {
  const wots = new WinternitzOTS(16);
  const privateKey = wots.generatePrivateKey();
  
  assert(Array.isArray(privateKey), 'Private key should be array');
  assert(privateKey.length > 0, 'Private key should have elements');
  assert(Buffer.isBuffer(privateKey[0]), 'Private key elements should be buffers');
});

runner.test('WinternitzOTS public key derivation', () => {
  const wots = new WinternitzOTS(16);
  const privateKey = wots.generatePrivateKey();
  const publicKey = wots.derivePublicKey(privateKey);
  
  assert(Array.isArray(publicKey), 'Public key should be array');
  assertEqual(publicKey.length, privateKey.length, 'Public and private keys should have same length');
});

runner.test('Merkle tree construction', () => {
  const leaves = [
    Buffer.from('leaf1'),
    Buffer.from('leaf2'),
    Buffer.from('leaf3'),
    Buffer.from('leaf4')
  ];
  
  const tree = new MerkleTree(leaves);
  const root = tree.getRoot();
  
  assert(Buffer.isBuffer(root), 'Root should be buffer');
  assertEqual(root.length, 32, 'Root should be 32 bytes (SHA-256)');
});

runner.test('Merkle proof generation and verification', () => {
  const leaves = [
    Buffer.from('leaf1'),
    Buffer.from('leaf2'),
    Buffer.from('leaf3'),
    Buffer.from('leaf4')
  ];
  
  const tree = new MerkleTree(leaves);
  const root = tree.getRoot();
  const proof = tree.getProof(0);
  
  const isValid = MerkleTree.verifyProof(leaves[0], proof, root);
  assert(isValid, 'Proof should be valid');
});

runner.test('Merkle proof verification fails for wrong leaf', () => {
  const leaves = [
    Buffer.from('leaf1'),
    Buffer.from('leaf2'),
    Buffer.from('leaf3'),
    Buffer.from('leaf4')
  ];
  
  const tree = new MerkleTree(leaves);
  const root = tree.getRoot();
  const proof = tree.getProof(0);
  
  const wrongLeaf = Buffer.from('wrong_leaf');
  const isValid = MerkleTree.verifyProof(wrongLeaf, proof, root);
  assert(!isValid, 'Proof should be invalid for wrong leaf');
});

runner.test('QuantumVault initialization (small)', async () => {
  const vault = new QuantumVault(4, 16); // Small vault for testing
  await vault.initialize();
  
  const root = vault.getMerkleRoot();
  assert(Buffer.isBuffer(root), 'Merkle root should be buffer');
  assertEqual(root.length, 32, 'Merkle root should be 32 bytes');
});

runner.test('QuantumVault spend preparation', async () => {
  const vault = new QuantumVault(4, 16);
  await vault.initialize();
  
  const spendData = vault.prepareSpend(0);
  
  assert(spendData.keyIndex === 0, 'Key index should be 0');
  assert(Array.isArray(spendData.publicKey), 'Public key should be array');
  assert(Buffer.isBuffer(spendData.publicKeyHash), 'Public key hash should be buffer');
  assert(Array.isArray(spendData.merkleProof), 'Merkle proof should be array');
});

runner.test('QuantumVault spend verification', async () => {
  const vault = new QuantumVault(4, 16);
  await vault.initialize();
  
  const spendData = vault.prepareSpend(0);
  const isValid = QuantumVault.verifySpend(spendData);
  
  assert(isValid, 'Spend data should be valid');
});

runner.test('QuantumVault prevents key reuse', async () => {
  const vault = new QuantumVault(4, 16);
  await vault.initialize();
  
  vault.prepareSpend(0); // Use key 0
  
  let errorThrown = false;
  try {
    vault.prepareSpend(0); // Try to reuse key 0
  } catch (error) {
    errorThrown = true;
    assert(error.message.includes('already used'), 'Should throw key reuse error');
  }
  
  assert(errorThrown, 'Should throw error on key reuse');
});

runner.test('QuantumVault statistics', async () => {
  const vault = new QuantumVault(8, 16);
  await vault.initialize();
  
  vault.prepareSpend(0);
  vault.prepareSpend(1);
  
  const stats = vault.getStats();
  
  assertEqual(stats.totalKeys, 8, 'Total keys should be 8');
  assertEqual(stats.usedKeys, 2, 'Used keys should be 2');
  assertEqual(stats.remainingKeys, 6, 'Remaining keys should be 6');
  assert(stats.merkleRoot.length === 64, 'Merkle root hex should be 64 chars');
});

runner.test('Taproot vault commitment creation', async () => {
  const vault = new QuantumVault(4, 16);
  await vault.initialize();
  
  const root = vault.getMerkleRoot();
  const commitment = createTaprootVaultCommitment(root);
  
  assertEqual(commitment.type, 'taproot_vault', 'Commitment type should be taproot_vault');
  assert(commitment.merkleRoot.length === 64, 'Merkle root should be hex string');
  assert(commitment.commitment.length === 64, 'Commitment should be hash');
});

runner.test('TaprootDescriptorBuilder basic construction', () => {
  const builder = new TaprootDescriptorBuilder();
  
  const internalKey = '0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0';
  builder.setInternalKey(internalKey);
  
  const descriptor = builder.build();
  
  assertEqual(descriptor.type, 'tr', 'Descriptor type should be Taproot');
  assertEqual(descriptor.internalKey, internalKey, 'Internal key should match');
});

runner.test('TaprootDescriptorBuilder with quantum vault', async () => {
  const vault = new QuantumVault(4, 16);
  await vault.initialize();
  
  const builder = new TaprootDescriptorBuilder();
  builder.setInternalKey('0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0');
  builder.addQuantumVault(vault.getMerkleRoot());
  
  const descriptor = builder.build();
  
  assert(descriptor.quantum.enabled, 'Quantum should be enabled');
  assert(descriptor.quantum.vaultRoot !== null, 'Vault root should be set');
  assert(descriptor.scriptTree.length > 0, 'Script tree should have entries');
});

runner.test('Large vault initialization (256 keys)', async () => {
  console.log('   (This may take a moment...)');
  const vault = new QuantumVault(256, 16);
  await vault.initialize();
  
  const stats = vault.getStats();
  assertEqual(stats.totalKeys, 256, 'Total keys should be 256');
  assertEqual(stats.usedKeys, 0, 'No keys should be used initially');
  
  // Verify proof size is reasonable
  const proofSizeKB = parseFloat(stats.proofSizeKB);
  assert(proofSizeKB < 1.0, 'Proof size should be under 1KB for 256 leaves');
});

// Run all tests
runner.run().catch(console.error);
