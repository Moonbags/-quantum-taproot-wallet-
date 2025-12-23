#!/usr/bin/env node
/**
 * Taproot Descriptors with Post-Quantum Scripts
 * 
 * Generates Bitcoin Taproot output descriptors integrated with
 * post-quantum signature schemes in the script tree
 * 
 * ⚠️ IMPORTANT: Key tweaking uses simplified simulation (XOR) for demonstration.
 * In production, implement proper BIP 341 Taproot key tweaking with actual
 * elliptic curve point addition using secp256k1 library.
 */

const crypto = require('crypto');

/**
 * Generate internal key for Taproot (x-only pubkey)
 * @param {string} seed - Hex seed for key generation
 * @returns {string} 32-byte x-only public key (hex)
 */
function generateInternalKey(seed) {
  // Deterministic internal key generation from seed
  const hash = crypto.createHash('sha256').update(seed).digest();
  return hash.toString('hex');
}

/**
 * Create post-quantum script leaf
 * @param {string} pqPubkey - Post-quantum public key (hex)
 * @param {string} scheme - Signature scheme ('ml-dsa' or 'falcon')
 * @returns {Object} Script leaf {script, version}
 */
function createPQScriptLeaf(pqPubkey, scheme = 'ml-dsa') {
  // Post-quantum signature verification script
  // Format: <pq_pubkey> OP_CHECKSIG (simplified for tapscript)
  // In practice, this would use a custom OP_CODE or witness program
  
  const schemePrefix = scheme === 'ml-dsa' ? '01' : '02'; // ML-DSA vs Falcon
  const script = `${schemePrefix}${pqPubkey} OP_PQ_CHECKSIG`;
  
  return {
    script: script,
    version: 0xc0, // Tapscript version
    scheme: scheme,
    securityLevel: scheme === 'ml-dsa' ? 'NIST-3' : 'NIST-5'
  };
}

/**
 * Create classical multisig script leaf
 * @param {string[]} pubkeys - Array of classical public keys (hex)
 * @param {number} threshold - Number of required signatures
 * @returns {Object} Script leaf {script, version}
 */
function createMultisigLeaf(pubkeys, threshold) {
  if (threshold > pubkeys.length || threshold < 1) {
    throw new Error('Invalid threshold for multisig');
  }
  
  const script = `OP_${threshold} ${pubkeys.join(' ')} OP_${pubkeys.length} OP_CHECKMULTISIG`;
  
  return {
    script: script,
    version: 0xc0,
    type: 'multisig',
    threshold: threshold,
    total: pubkeys.length
  };
}

/**
 * Create timelock recovery script leaf
 * @param {string} recoveryKey - Recovery public key (hex)
 * @param {number} blocks - Timelock in blocks (CSV)
 * @returns {Object} Script leaf {script, version}
 */
function createTimelockLeaf(recoveryKey, blocks) {
  // OP_CHECKSEQUENCEVERIFY timelock script
  const script = `${blocks} OP_CSV OP_DROP ${recoveryKey} OP_CHECKSIG`;
  
  return {
    script: script,
    version: 0xc0,
    type: 'timelock',
    blocks: blocks,
    recoveryKey: recoveryKey
  };
}

/**
 * Build Taproot script tree from leaves
 * @param {Object[]} leaves - Array of script leaves
 * @returns {Object} Script tree {root, merkleRoot}
 */
function buildScriptTree(leaves) {
  if (!leaves || leaves.length === 0) {
    throw new Error('Script tree requires at least one leaf');
  }
  
  // Calculate tagged hash for each leaf (TapLeaf)
  const leafHashes = leaves.map(leaf => {
    const leafData = Buffer.from(leaf.script, 'utf8');
    const tag = 'TapLeaf';
    const tagHash = crypto.createHash('sha256').update(tag).digest();
    const taggedHash = crypto.createHash('sha256')
      .update(Buffer.concat([tagHash, tagHash, leafData]))
      .digest();
    return taggedHash;
  });
  
  // Build Merkle tree from leaf hashes
  let currentLevel = leafHashes;
  
  while (currentLevel.length > 1) {
    const nextLevel = [];
    
    for (let i = 0; i < currentLevel.length; i += 2) {
      if (i + 1 < currentLevel.length) {
        // TapBranch hash
        const tag = 'TapBranch';
        const tagHash = crypto.createHash('sha256').update(tag).digest();
        const [left, right] = currentLevel[i].compare(currentLevel[i + 1]) < 0 
          ? [currentLevel[i], currentLevel[i + 1]]
          : [currentLevel[i + 1], currentLevel[i]];
        
        const branchHash = crypto.createHash('sha256')
          .update(Buffer.concat([tagHash, tagHash, left, right]))
          .digest();
        
        nextLevel.push(branchHash);
      } else {
        nextLevel.push(currentLevel[i]);
      }
    }
    
    currentLevel = nextLevel;
  }
  
  return {
    root: currentLevel[0].toString('hex'),
    merkleRoot: currentLevel[0],
    leaves: leaves,
    leafCount: leaves.length
  };
}

/**
 * Create Taproot descriptor with post-quantum scripts
 * @param {string} internalKey - Internal x-only pubkey (hex)
 * @param {Object[]} scriptLeaves - Array of script leaves
 * @param {boolean} testnet - Use testnet parameters
 * @returns {Object} Taproot descriptor
 */
function createTaprootDescriptor(internalKey, scriptLeaves, testnet = false) {
  const tree = buildScriptTree(scriptLeaves);
  
  // Tweak internal key with script tree root
  const tweakedKey = tweakPublicKey(internalKey, tree.merkleRoot);
  
  // Build descriptor string
  const scriptPaths = scriptLeaves.map((leaf, idx) => {
    return `{${leaf.script}}`;
  }).join(',');
  
  const descriptor = `tr(${internalKey},${scriptPaths})`;
  
  return {
    descriptor: descriptor,
    internalKey: internalKey,
    tweakedKey: tweakedKey,
    scriptTree: tree,
    network: testnet ? 'testnet' : 'mainnet',
    version: 1
  };
}

/**
 * Tweak public key with Taproot commitment
 * @param {string} internalKey - Internal x-only pubkey (hex)
 * @param {Buffer} merkleRoot - Script tree Merkle root
 * @returns {string} Tweaked x-only pubkey (hex)
 */
function tweakPublicKey(internalKey, merkleRoot) {
  // TapTweak = tagged_hash("TapTweak", internal_key || merkle_root)
  const tag = 'TapTweak';
  const tagHash = crypto.createHash('sha256').update(tag).digest();
  
  const internalKeyBuf = Buffer.from(internalKey, 'hex');
  const tweakData = Buffer.concat([internalKeyBuf, merkleRoot]);
  
  const tweak = crypto.createHash('sha256')
    .update(Buffer.concat([tagHash, tagHash, tweakData]))
    .digest();
  
  // In practice, this would do point addition on the curve
  // For this implementation, we simulate by XORing (not cryptographically valid)
  // WARNING: This is a DEMONSTRATION ONLY. In production, use proper elliptic curve
  // point addition for Taproot key tweaking as specified in BIP 341
  const tweakedKey = Buffer.alloc(32);
  for (let i = 0; i < 32; i++) {
    tweakedKey[i] = internalKeyBuf[i] ^ tweak[i];
  }
  
  return tweakedKey.toString('hex');
}

/**
 * Create hybrid descriptor with classical + post-quantum options
 * @param {Object} config - Configuration {hotKey, coldKey, pqKey, recoveryKey, timelockBlocks}
 * @param {boolean} testnet - Use testnet
 * @returns {Object} Hybrid Taproot descriptor
 */
function createHybridDescriptor(config, testnet = false) {
  const {hotKey, coldKey, pqKey, recoveryKey, timelockBlocks = 1008} = config;
  
  // Generate internal key from configuration
  const internalKey = generateInternalKey(hotKey + coldKey);
  
  // Build script tree with multiple spending paths
  const scriptLeaves = [];
  
  // Path 1: Post-quantum signature (ML-DSA)
  if (pqKey) {
    scriptLeaves.push(createPQScriptLeaf(pqKey, 'ml-dsa'));
  }
  
  // Path 2: Classical 2-of-2 multisig (hot + cold)
  if (hotKey && coldKey) {
    scriptLeaves.push(createMultisigLeaf([hotKey, coldKey], 2));
  }
  
  // Path 3: Timelock recovery
  if (recoveryKey) {
    scriptLeaves.push(createTimelockLeaf(recoveryKey, timelockBlocks));
  }
  
  const descriptor = createTaprootDescriptor(internalKey, scriptLeaves, testnet);
  
  return {
    ...descriptor,
    spendingPaths: {
      keyPath: 'Internal key spend (most efficient)',
      pqPath: pqKey ? 'Post-quantum ML-DSA signature' : null,
      multisigPath: (hotKey && coldKey) ? '2-of-2 classical multisig' : null,
      recoveryPath: recoveryKey ? `Timelock recovery (${timelockBlocks} blocks)` : null
    }
  };
}

/**
 * Estimate descriptor witness size
 * @param {string} spendingPath - Type of spending path used
 * @returns {number} Estimated witness size in bytes
 */
function estimateWitnessSize(spendingPath) {
  const sizes = {
    keyPath: 64,           // Schnorr signature
    pqPath: 2420,          // ML-DSA-65 signature (~2.4KB)
    falconPath: 1280,      // Falcon-512 signature (~1.3KB)
    multisigPath: 128,     // 2 Schnorr signatures
    recoveryPath: 96       // Signature + timelock witness
  };
  
  return sizes[spendingPath] || 64;
}

module.exports = {
  generateInternalKey,
  createPQScriptLeaf,
  createMultisigLeaf,
  createTimelockLeaf,
  buildScriptTree,
  createTaprootDescriptor,
  tweakPublicKey,
  createHybridDescriptor,
  estimateWitnessSize
};
