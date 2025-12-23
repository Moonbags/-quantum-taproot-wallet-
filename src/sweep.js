#!/usr/bin/env node
/**
 * Simple UTXO sweep planner with conservative size estimates (~1.5KB/input).
 */
const APPROX_INPUT_BYTES = 1500; // ~1.5KB per Taproot script-path input
const DEFAULT_BATCH_BYTES = 100 * 1024; // keep batches under ~100KB
const DEFAULT_MAX_INPUTS = 400;
const DUST_THRESHOLD = 546;

function toSats(value) {
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? 0 : parsed;
}

function sumValue(inputs) {
  return inputs.reduce((sum, u) => sum + toSats(u.value || 0), 0);
}

function planBatches(utxos, {
  maxBatchBytes = DEFAULT_BATCH_BYTES,
  maxInputs = DEFAULT_MAX_INPUTS,
  approxBytesPerInput = APPROX_INPUT_BYTES,
  dustThreshold = DUST_THRESHOLD,
} = {}) {
  const spendable = (utxos || []).filter((u) => Number(u.value || 0) > dustThreshold);
  const batches = [];

  let current = [];
  let currentBytes = 0;

  for (const utxo of spendable) {
    const nextBytes = currentBytes + approxBytesPerInput;
    if (current.length >= maxInputs || nextBytes > maxBatchBytes) {
      batches.push({
        inputs: current,
        estimatedBytes: current.length * approxBytesPerInput,
        totalValue: sumValue(current),
      });
      current = [];
      currentBytes = 0;
    }
    current.push(utxo);
    currentBytes += approxBytesPerInput;
  }

  if (current.length) {
    batches.push({
      inputs: current,
      estimatedBytes: current.length * approxBytesPerInput,
      totalValue: sumValue(current),
    });
  }

  return { batches, approxBytesPerInput, dustThreshold };
}

function main(argv) {
  if (argv.length === 0) {
    console.log('Usage: node src/sweep.js \'[{"txid":"...","vout":0,"value":100000}]\'');
    process.exit(0);
  }
  let utxos;
  try {
    utxos = JSON.parse(argv[0]);
  } catch (err) {
    console.error('Invalid UTXO JSON payload');
    process.exit(1);
  }
  if (!Array.isArray(utxos)) {
    console.error('UTXO payload must be an array');
    process.exit(1);
  }
  const plan = planBatches(utxos);
  console.log(JSON.stringify(plan, null, 2));
}

if (require.main === module) {
  main(process.argv.slice(2));
}

module.exports = { planBatches, sumValue, APPROX_INPUT_BYTES, DEFAULT_BATCH_BYTES, DEFAULT_MAX_INPUTS, DUST_THRESHOLD };
