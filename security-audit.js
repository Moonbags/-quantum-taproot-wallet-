#!/usr/bin/env node
/**
 * Lightweight security sanity checks.
 * - Confirms NUMS internal key is referenced.
 * - Warns if WIF-looking strings are present (avoid leaking secrets).
 * - Reminds to run Slither for solidity-style audits if applicable.
 */
const fs = require('fs');
const path = require('path');

const root = __dirname;
const NUMS_KEY = '0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0';
const files = [
  path.join(root, 'setup.sh'),
  path.join(root, 'src', 'descriptors.js'),
];

function fileContains(file, needle) {
  if (!fs.existsSync(file)) return false;
  return fs.readFileSync(file, 'utf8').includes(needle);
}

function scanForWif(file) {
  if (!fs.existsSync(file)) return [];
  const content = fs.readFileSync(file, 'utf8');
  const matches = content.match(/\b[KL5][1-9A-HJ-NP-Za-km-z]{20,}/g) || [];
  return matches.slice(0, 3);
}

let ok = true;
for (const file of files) {
  if (fileContains(file, NUMS_KEY)) {
    console.log(`✅ ${path.basename(file)} references NUMS internal key`);
  } else {
    ok = false;
    console.warn(`❌ ${path.basename(file)} missing NUMS internal key`);
  }
  const wifs = scanForWif(file);
  if (wifs.length) {
    ok = false;
    console.warn(`⚠️ Possible WIF-like strings in ${path.basename(file)}: ${wifs.join(', ')}`);
  }
}

console.log('Reminder: run Slither or equivalent static analysis for any Solidity components (none in this repo).');
process.exit(ok ? 0 : 1);
