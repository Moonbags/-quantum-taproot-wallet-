#!/usr/bin/env node
/**
 * Vault Sweep - Efficient UTXO Sweeping
 * 
 * Optimized vault sweeps targeting ~1.5KB per UTXO
 * Implements batching and witness optimization for post-quantum signatures
 */

const { createTxSignatureMessage, signTransaction } = require('./signatures');
const { getSpendingProof } = require('./quantum-vault');

/**
 * Calculate transaction weight units
 * @param {Object} tx - Transaction structure
 * @returns {number} Weight units (vbytes * 4)
 */
function calculateWeight(tx) {
  // Simplified weight calculation
  // Taproot inputs: ~57.5 vbytes base + witness
  // Outputs: ~43 vbytes each
  
  const baseSize = 10; // Version (4) + locktime (4) + marker/flag (2)
  const inputBaseSize = 41; // Outpoint (36) + scriptSig (1) + sequence (4)
  const outputSize = 43; // Amount (8) + scriptPubKey (35)
  
  let weight = (baseSize + 
                tx.inputs.length * inputBaseSize + 
                tx.outputs.length * outputSize) * 4;
  
  // Add witness weight
  tx.inputs.forEach(input => {
    if (input.witness) {
      // Witness can be a number (estimated size) or an array
      weight += typeof input.witness === 'number' ? input.witness : input.witness.length;
    }
  });
  
  return weight;
}

/**
 * Calculate virtual bytes from weight
 * @param {number} weight - Weight units
 * @returns {number} Virtual bytes
 */
function weightToVbytes(weight) {
  return Math.ceil(weight / 4);
}

/**
 * Estimate fee for transaction
 * @param {number} vbytes - Transaction size in vbytes
 * @param {number} feeRate - Fee rate in sat/vbyte
 * @returns {number} Estimated fee in satoshis
 */
function estimateFee(vbytes, feeRate) {
  return Math.ceil(vbytes * feeRate);
}

/**
 * Create sweep transaction from vault
 * @param {Object} vault - Vault object with UTXOs
 * @param {string} destination - Destination address
 * @param {Object} keyPair - Post-quantum key pair for signing
 * @param {Object} options - Sweep options {feeRate, maxInputs}
 * @returns {Object} Sweep transaction
 */
function createSweepTransaction(vault, destination, keyPair, options = {}) {
  const {
    feeRate = 10, // sat/vbyte
    maxInputs = 50, // Limit inputs per transaction
    useKeyPath = false // Use key path spend vs script path
  } = options;
  
  if (!vault.utxos || vault.utxos.length === 0) {
    throw new Error('Vault has no UTXOs to sweep');
  }
  
  // Select UTXOs to sweep (up to maxInputs)
  const utxosToSweep = vault.utxos.slice(0, maxInputs);
  
  // Calculate total input amount
  const totalInput = utxosToSweep.reduce((sum, utxo) => 
    sum + BigInt(utxo.amount), BigInt(0));
  
  // Build transaction structure
  const tx = {
    version: 2,
    inputs: [],
    outputs: [],
    locktime: 0
  };
  
  // Add inputs
  utxosToSweep.forEach((utxo, index) => {
    tx.inputs.push({
      txid: utxo.txid,
      vout: utxo.vout,
      sequence: 0xfffffffd, // Enable RBF
      scriptSig: '',
      witness: null // Will be filled during signing
    });
  });
  
  // Estimate witness size per input
  const witnessPerInput = useKeyPath ? 64 : (
    keyPair && keyPair.algorithm === 'ML-DSA' ? 2420 : 
    keyPair && keyPair.algorithm === 'Falcon' ? 1280 : 2420
  );
  
  // Add witness size estimate
  tx.inputs.forEach(input => {
    input.witness = witnessPerInput;
  });
  
  // Create dummy output for fee estimation
  tx.outputs.push({
    value: 0, // Will be calculated
    scriptPubKey: '5120' + '00'.repeat(32) // P2TR output (dummy)
  });
  
  // Calculate fee
  const weight = calculateWeight(tx);
  const vbytes = weightToVbytes(weight);
  const fee = estimateFee(vbytes, feeRate);
  
  // Calculate output amount
  const outputAmount = totalInput - BigInt(fee);
  
  if (outputAmount <= 0) {
    throw new Error('Insufficient funds to cover fee');
  }
  
  // Update output with actual amount
  tx.outputs[0].value = outputAmount.toString();
  tx.outputs[0].address = destination;
  
  return {
    transaction: tx,
    metadata: {
      inputCount: tx.inputs.length,
      totalInput: totalInput.toString(),
      outputAmount: outputAmount.toString(),
      fee: fee,
      feeRate: feeRate,
      vbytes: vbytes,
      weight: weight,
      avgBytesPerUtxo: Math.ceil(vbytes / tx.inputs.length),
      efficiency: useKeyPath ? 'optimal (key path)' : 'script path (PQ sig)'
    }
  };
}

/**
 * Sign sweep transaction inputs
 * @param {Object} sweepTx - Sweep transaction from createSweepTransaction
 * @param {Object} vault - Source vault
 * @param {Object} keyPair - Post-quantum key pair
 * @returns {Object} Signed transaction
 */
function signSweepTransaction(sweepTx, vault, keyPair) {
  const tx = sweepTx.transaction;
  const signatures = [];
  
  // Sign each input
  tx.inputs.forEach((input, index) => {
    const utxo = vault.utxos[index];
    
    // Get spending proof from vault
    const proof = getSpendingProof(vault, index);
    
    // Create signature
    const sig = signTransaction(
      tx,
      index,
      keyPair,
      utxo.script,
      utxo.amount
    );
    
    signatures.push({
      inputIndex: index,
      signature: sig,
      proof: proof
    });
    
    // Update witness with actual signature
    // Witness format: <signature> <proof> <script>
    const witnessStack = [
      sig.signature,
      proof.leaf,
      ...proof.proof.map(p => p.hash)
    ];
    
    input.witness = witnessStack;
  });
  
  return {
    ...sweepTx,
    transaction: tx,
    signatures: signatures,
    signed: true
  };
}

/**
 * Create batched sweep for large vaults
 * @param {Object} vault - Vault with many UTXOs
 * @param {string} destination - Destination address
 * @param {Object} keyPair - Post-quantum key pair
 * @param {Object} options - Batch options
 * @returns {Object[]} Array of sweep transactions
 */
function createBatchSweep(vault, destination, keyPair, options = {}) {
  const {
    feeRate = 10,
    maxInputsPerTx = 50,
    useKeyPath = false
  } = options;
  
  const batches = [];
  const totalUtxos = vault.utxos.length;
  
  // Split UTXOs into batches
  for (let i = 0; i < totalUtxos; i += maxInputsPerTx) {
    const batchUtxos = vault.utxos.slice(i, i + maxInputsPerTx);
    
    // Create vault subset for this batch
    const batchVault = {
      ...vault,
      utxos: batchUtxos
    };
    
    // Create sweep transaction for this batch
    const sweepTx = createSweepTransaction(
      batchVault,
      destination,
      keyPair,
      { feeRate, maxInputs: maxInputsPerTx, useKeyPath }
    );
    
    // Sign the transaction
    const signedTx = signSweepTransaction(sweepTx, batchVault, keyPair);
    
    batches.push({
      batchNumber: batches.length + 1,
      ...signedTx
    });
  }
  
  // Calculate total statistics
  const totalStats = batches.reduce((stats, batch) => {
    return {
      totalInputs: stats.totalInputs + batch.metadata.inputCount,
      totalFee: stats.totalFee + batch.metadata.fee,
      totalVbytes: stats.totalVbytes + batch.metadata.vbytes
    };
  }, { totalInputs: 0, totalFee: 0, totalVbytes: 0 });
  
  return {
    batches: batches,
    batchCount: batches.length,
    summary: {
      ...totalStats,
      avgBytesPerUtxo: Math.ceil(totalStats.totalVbytes / totalStats.totalInputs),
      avgFeePerUtxo: Math.ceil(totalStats.totalFee / totalStats.totalInputs)
    }
  };
}

/**
 * Optimize sweep with UTXO selection
 * @param {Object} vault - Vault with UTXOs
 * @param {string} destination - Destination address
 * @param {Object} keyPair - Post-quantum key pair
 * @param {number} targetAmount - Target amount to sweep (optional)
 * @param {Object} options - Options
 * @returns {Object} Optimized sweep transaction
 */
function optimizeSweep(vault, destination, keyPair, targetAmount, options = {}) {
  const { feeRate = 10, useKeyPath = false } = options;
  
  // Sort UTXOs by amount (descending) for efficient selection
  const sortedUtxos = [...vault.utxos].sort((a, b) => 
    Number(BigInt(b.amount) - BigInt(a.amount))
  );
  
  let selectedUtxos = [];
  let accumulatedAmount = BigInt(0);
  
  if (targetAmount) {
    // Select UTXOs until we reach target amount
    const target = BigInt(targetAmount);
    
    for (const utxo of sortedUtxos) {
      selectedUtxos.push(utxo);
      accumulatedAmount += BigInt(utxo.amount);
      
      // Estimate fee with current selection
      const tempVault = { ...vault, utxos: selectedUtxos };
      const tempTx = createSweepTransaction(tempVault, destination, keyPair, 
        { feeRate, useKeyPath });
      const estimatedFee = BigInt(tempTx.metadata.fee);
      
      if (accumulatedAmount >= target + estimatedFee) {
        break; // Have enough to cover target + fee
      }
    }
  } else {
    // Sweep all UTXOs
    selectedUtxos = sortedUtxos;
  }
  
  const optimizedVault = { ...vault, utxos: selectedUtxos };
  const sweepTx = createSweepTransaction(optimizedVault, destination, keyPair, 
    { feeRate, useKeyPath });
  
  return signSweepTransaction(sweepTx, optimizedVault, keyPair);
}

/**
 * Serialize transaction for broadcast
 * @param {Object} signedTx - Signed sweep transaction
 * @returns {string} Serialized transaction (hex)
 */
function serializeTransaction(signedTx) {
  // Simplified serialization
  // In production: Follow full Bitcoin transaction serialization format
  
  const tx = signedTx.transaction;
  const parts = [];
  
  // Version
  parts.push(tx.version.toString(16).padStart(8, '0'));
  
  // Input count
  parts.push(tx.inputs.length.toString(16).padStart(2, '0'));
  
  // Inputs
  tx.inputs.forEach(input => {
    parts.push(input.txid);
    parts.push(input.vout.toString(16).padStart(8, '0'));
  });
  
  // Output count
  parts.push(tx.outputs.length.toString(16).padStart(2, '0'));
  
  // Outputs
  tx.outputs.forEach(output => {
    const amount = BigInt(output.value);
    parts.push(amount.toString(16).padStart(16, '0'));
  });
  
  return parts.join('');
}

module.exports = {
  calculateWeight,
  weightToVbytes,
  estimateFee,
  createSweepTransaction,
  signSweepTransaction,
  createBatchSweep,
  optimizeSweep,
  serializeTransaction
};
