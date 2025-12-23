#!/usr/bin/env node
/**
 * Minimal SHA256 Merkle tree utilities for committing Taproot script leaves.
 * This is intentionally simple and dependency-free.
 */
const crypto = require('crypto');

function sha256(buffer) {
  return crypto.createHash('sha256').update(buffer).digest();
}

function toBuffer(input) {
  if (Buffer.isBuffer(input)) return input;
  if (typeof input === 'string') return Buffer.from(input);
  return Buffer.from(JSON.stringify(input));
}

function merkleRoot(leaves) {
  if (!Array.isArray(leaves) || leaves.length === 0) {
    return sha256(Buffer.alloc(0)).toString('hex');
  }
  let level = leaves.map((leaf) => sha256(toBuffer(leaf)));
  while (level.length > 1) {
    const next = [];
    for (let i = 0; i < level.length; i += 2) {
      const left = level[i];
      const right = level[i + 1] || level[i]; // duplicate last if odd
      const [first, second] = Buffer.compare(left, right) <= 0 ? [left, right] : [right, left];
      next.push(sha256(Buffer.concat([first, second])));
    }
    level = next;
  }
  return level[0].toString('hex');
}

function commitScripts(scripts) {
  return merkleRoot(scripts);
}

function main(argv) {
  const scripts = argv.filter(Boolean);
  if (scripts.length === 0) {
    console.log('Usage: node src/quantum-vault.js <scriptLeaf1> <scriptLeaf2> ...');
    process.exit(0);
  }
  if (scripts.some((s) => typeof s !== 'string')) {
    console.error('Script leaves must be strings');
    process.exit(1);
  }
  const root = commitScripts(scripts);
  console.log(root);
}

if (require.main === module) {
  main(process.argv.slice(2));
}

module.exports = { merkleRoot, commitScripts };
