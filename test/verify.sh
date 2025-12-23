#!/bin/bash
# Merkle Path Verification Script
# Verifies Merkle proofs for vault UTXOs

set -euo pipefail

echo "=== Merkle Path Verification Tool ==="
echo ""

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js."
    exit 1
fi

# Verify quantum-vault.js exists
VAULT_SCRIPT="../src/quantum-vault.js"
if [ ! -f "$VAULT_SCRIPT" ]; then
    echo "❌ quantum-vault.js not found at $VAULT_SCRIPT"
    exit 1
fi

echo "✓ Prerequisites met"
echo ""

# Test data: Sample UTXOs
echo "Test 1: Create Sample Vault"
echo "============================"

node -e "
const vault = require('$VAULT_SCRIPT');

// Sample UTXOs for testing
const utxos = [
  {
    txid: 'a'.repeat(64),
    vout: 0,
    amount: 100000,
    script: 'b'.repeat(64)
  },
  {
    txid: 'c'.repeat(64),
    vout: 1,
    amount: 200000,
    script: 'd'.repeat(64)
  },
  {
    txid: 'e'.repeat(64),
    vout: 0,
    amount: 150000,
    script: 'f'.repeat(64)
  },
  {
    txid: '1'.repeat(64),
    vout: 2,
    amount: 50000,
    script: '2'.repeat(64)
  }
];

console.log('Creating vault with', utxos.length, 'UTXOs...');
const v = vault.createVault(utxos);

console.log('✓ Vault created');
console.log('  Merkle Root:', v.root);
console.log('  Total UTXOs:', v.metadata.utxoCount);
console.log('  Total Amount:', v.metadata.totalAmount, 'satoshis');
console.log('  Security:', v.metadata.quantumSecurity);
console.log('');

// Store vault for next tests
global.testVault = v;
"

echo ""
echo "Test 2: Generate Merkle Proof"
echo "=============================="

node -e "
const vault = require('$VAULT_SCRIPT');

const utxos = [
  { txid: 'a'.repeat(64), vout: 0, amount: 100000, script: 'b'.repeat(64) },
  { txid: 'c'.repeat(64), vout: 1, amount: 200000, script: 'd'.repeat(64) },
  { txid: 'e'.repeat(64), vout: 0, amount: 150000, script: 'f'.repeat(64) },
  { txid: '1'.repeat(64), vout: 2, amount: 50000, script: '2'.repeat(64) }
];

const v = vault.createVault(utxos);

console.log('Generating proof for UTXO index 1...');
const proof = vault.getSpendingProof(v, 1);

console.log('✓ Proof generated');
console.log('  UTXO:', JSON.stringify(proof.utxo, null, 2));
console.log('  Leaf Hash:', proof.leaf.substring(0, 16) + '...');
console.log('  Proof Length:', proof.proof.length, 'nodes');
console.log('  Merkle Root:', proof.root);
console.log('');
console.log('Proof path:');
proof.proof.forEach((p, i) => {
  console.log('  ', i + 1, '-', p.position, ':', p.hash.substring(0, 16) + '...');
});
"

echo ""
echo "Test 3: Verify Merkle Proof"
echo "============================"

node -e "
const vault = require('$VAULT_SCRIPT');

const utxos = [
  { txid: 'a'.repeat(64), vout: 0, amount: 100000, script: 'b'.repeat(64) },
  { txid: 'c'.repeat(64), vout: 1, amount: 200000, script: 'd'.repeat(64) },
  { txid: 'e'.repeat(64), vout: 0, amount: 150000, script: 'f'.repeat(64) },
  { txid: '1'.repeat(64), vout: 2, amount: 50000, script: '2'.repeat(64) }
];

const v = vault.createVault(utxos);

// Test each UTXO
console.log('Verifying all UTXOs in vault...');
let allValid = true;

for (let i = 0; i < utxos.length; i++) {
  const proof = vault.getSpendingProof(v, i);
  const isValid = vault.verifySpendingProof(proof);
  
  const status = isValid ? '✓' : '❌';
  console.log('  UTXO', i, ':', status, isValid ? 'Valid' : 'Invalid');
  
  if (!isValid) allValid = false;
}

console.log('');
if (allValid) {
  console.log('✓ All proofs verified successfully');
} else {
  console.log('❌ Some proofs failed verification');
  process.exit(1);
}
"

echo ""
echo "Test 4: Tamper Detection"
echo "========================="

node -e "
const vault = require('$VAULT_SCRIPT');

const utxos = [
  { txid: 'a'.repeat(64), vout: 0, amount: 100000, script: 'b'.repeat(64) },
  { txid: 'c'.repeat(64), vout: 1, amount: 200000, script: 'd'.repeat(64) }
];

const v = vault.createVault(utxos);
const proof = vault.getSpendingProof(v, 0);

console.log('Testing tamper detection...');

// Test 1: Valid proof
const valid = vault.verifySpendingProof(proof);
console.log('  Original proof:', valid ? '✓ Valid' : '❌ Invalid');

// Test 2: Tampered root
const tamperedProof1 = { ...proof, root: '0'.repeat(64) };
const invalid1 = vault.verifySpendingProof(tamperedProof1);
console.log('  Tampered root:', invalid1 ? '❌ Accepted (BAD)' : '✓ Rejected (GOOD)');

// Test 3: Tampered leaf
const tamperedProof2 = { ...proof, leaf: '0'.repeat(64) };
const invalid2 = vault.verifySpendingProof(tamperedProof2);
console.log('  Tampered leaf:', invalid2 ? '❌ Accepted (BAD)' : '✓ Rejected (GOOD)');

// Test 4: Tampered proof path
let invalid3 = false;
if (proof.proof.length > 0) {
  const tamperedProof3 = {
    ...proof,
    proof: proof.proof.map(p => ({ ...p, hash: '0'.repeat(64) }))
  };
  invalid3 = vault.verifySpendingProof(tamperedProof3);
  console.log('  Tampered path:', invalid3 ? '❌ Accepted (BAD)' : '✓ Rejected (GOOD)');
}

console.log('');
if (!invalid1 && !invalid2 && !invalid3) {
  console.log('✓ Tamper detection working correctly');
} else {
  console.log('❌ Tamper detection failed - security issue!');
  process.exit(1);
}
"

echo ""
echo "Test 5: Large Vault Performance"
echo "================================"

node -e "
const vault = require('$VAULT_SCRIPT');

console.log('Creating large vault with 100 UTXOs...');
const startTime = Date.now();

const utxos = [];
for (let i = 0; i < 100; i++) {
  utxos.push({
    txid: i.toString(16).padStart(64, '0'),
    vout: i % 4,
    amount: 10000 + i * 1000,
    script: (i * 2).toString(16).padStart(64, '0')
  });
}

const v = vault.createVault(utxos);
const createTime = Date.now() - startTime;

console.log('✓ Vault created in', createTime, 'ms');
console.log('  Merkle Root:', v.root.substring(0, 16) + '...');
console.log('  Total UTXOs:', v.metadata.utxoCount);
console.log('');

// Test proof generation and verification
console.log('Testing proof generation and verification...');
const proofStart = Date.now();

for (let i = 0; i < 10; i++) {
  const idx = Math.floor(Math.random() * utxos.length);
  const proof = vault.getSpendingProof(v, idx);
  const isValid = vault.verifySpendingProof(proof);
  
  if (!isValid) {
    console.log('❌ Proof verification failed for index', idx);
    process.exit(1);
  }
}

const proofTime = Date.now() - proofStart;
console.log('✓ 10 proofs verified in', proofTime, 'ms');
console.log('  Average:', (proofTime / 10).toFixed(2), 'ms per proof');
"

echo ""
echo "=== Verification Complete ==="
echo "Summary:"
echo "  ✓ Vault creation"
echo "  ✓ Merkle proof generation"
echo "  ✓ Proof verification"
echo "  ✓ Tamper detection"
echo "  ✓ Performance testing"
echo ""
echo "All Merkle path verifications passed!"
