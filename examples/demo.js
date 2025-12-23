#!/usr/bin/env node
/**
 * Quantum Vault Demo
 * 
 * Demonstrates the quantum-resistant vault functionality
 * Run with: node examples/demo.js
 */

const { 
  QuantumVault, 
  createTaprootVaultCommitment,
  TaprootDescriptorBuilder 
} = require('../src');

async function main() {
  console.log('🔬 Quantum Taproot Wallet Demo');
  console.log('================================\n');

  // Step 1: Create a quantum vault
  console.log('Step 1: Creating quantum-resistant vault...');
  console.log('(Generating 64 one-time key pairs for demo)\n');
  
  const vault = new QuantumVault(64, 16);
  await vault.initialize();

  // Step 2: Show vault statistics
  console.log('\nStep 2: Vault Statistics');
  console.log('------------------------');
  const stats1 = vault.getStats();
  console.log(`Total keys:      ${stats1.totalKeys}`);
  console.log(`Used keys:       ${stats1.usedKeys}`);
  console.log(`Remaining keys:  ${stats1.remainingKeys}`);
  console.log(`Merkle root:     ${stats1.merkleRoot.substring(0, 32)}...`);
  console.log(`Proof size:      ~${stats1.proofSizeKB}KB`);

  // Step 3: Create Taproot commitment
  console.log('\nStep 3: Creating Taproot Commitment');
  console.log('-----------------------------------');
  const commitment = createTaprootVaultCommitment(vault.getMerkleRoot());
  console.log(`Type:       ${commitment.type}`);
  console.log(`Merkle root: ${commitment.merkleRoot.substring(0, 48)}...`);
  console.log(`Commitment: ${commitment.commitment.substring(0, 48)}...`);

  // Step 4: Build Taproot descriptor
  console.log('\nStep 4: Building Taproot Descriptor');
  console.log('------------------------------------');
  const builder = new TaprootDescriptorBuilder();
  builder.setInternalKey('0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0');
  builder.addQuantumVault(vault.getMerkleRoot());
  
  const descriptor = builder.build();
  console.log(`Type:           ${descriptor.type}`);
  console.log(`Quantum enabled: ${descriptor.quantum.enabled}`);
  console.log(`Script branches: ${descriptor.scriptTree.length}`);

  // Step 5: Simulate spending
  console.log('\nStep 5: Preparing Quantum-Secure Spend');
  console.log('--------------------------------------');
  
  const spendData1 = vault.prepareSpend(0);
  console.log(`Key index:      ${spendData1.keyIndex}`);
  console.log(`Merkle proof:   ${spendData1.merkleProof.length} steps`);
  console.log(`Verification:   ${QuantumVault.verifySpend(spendData1) ? '✅ Valid' : '❌ Invalid'}`);

  // Demonstrate one-time use enforcement
  console.log('\nStep 6: Demonstrating One-Time Key Security');
  console.log('--------------------------------------------');
  console.log('Attempting to reuse key 0...');
  try {
    vault.prepareSpend(0);
    console.log('❌ ERROR: Key reuse should have been prevented!');
  } catch (error) {
    console.log(`✅ Correctly prevented: ${error.message}`);
  }

  // Use a different key
  console.log('\nUsing key 1 instead...');
  const spendData2 = vault.prepareSpend(1);
  console.log(`✅ Key ${spendData2.keyIndex} prepared successfully`);

  // Final statistics
  console.log('\nStep 7: Final Vault Statistics');
  console.log('-------------------------------');
  const stats2 = vault.getStats();
  console.log(`Total keys:      ${stats2.totalKeys}`);
  console.log(`Used keys:       ${stats2.usedKeys}`);
  console.log(`Remaining keys:  ${stats2.remainingKeys}`);
  console.log(`Utilization:     ${stats2.utilizationPercent}%`);

  // Security summary
  console.log('\n⚛️  Quantum Security Summary');
  console.log('============================');
  console.log('✅ Hash-based signatures (W-OTS) - quantum-resistant');
  console.log('✅ Merkle tree commitment - only reveals used keys');
  console.log('✅ SHA-256 provides ~128-bit quantum security');
  console.log('✅ One-time key usage enforced automatically');
  console.log('');
  console.log('⚠️  Remember:');
  console.log('   - Each key can only be used ONCE');
  console.log('   - After all keys are used, create a new vault');
  console.log('   - Store vault data securely (encrypted)');
  console.log('   - Test on testnet/signet before mainnet');
  console.log('');
  console.log('📚 Learn more: https://blog.bitjson.com/quantumroot/');
}

main().catch(console.error);
