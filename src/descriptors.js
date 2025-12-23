#!/usr/bin/env node
/**
 * Taproot descriptor helper that forces script-path spends by using a NUMS internal key.
 * Script tree: 2-of-2 hot/cold OR recovery key after 1008 blocks.
 */
const { spawnSync } = require('child_process');

const NUMS_INTERNAL_KEY = '0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0';
const DEFAULT_RANGE = '[0,999]';
const RECOVERY_DELAY = 1008; // ~1 week

const NETWORK_FLAGS = {
  signet: ['--signet'],
  testnet: ['--testnet'],
  mainnet: [],
};

function assertSafeDescriptor(descriptor) {
  if (!descriptor || typeof descriptor !== 'string') {
    throw new Error('Descriptor is required');
  }
  if (!/^[A-Za-z0-9_:/\[\]{}(),*#\.-]+$/.test(descriptor)) {
    throw new Error('Descriptor contains unsupported characters');
  }
  return descriptor;
}

function ensureXpub(label, value) {
  if (!value || typeof value !== 'string' || value.trim().length < 100) {
    throw new Error(`Missing or invalid ${label} xpub`);
  }
  return value.trim();
}

function buildScriptTree({ hotXpub, coldXpub, recoveryXpub }) {
  const hot = `${ensureXpub('hot', hotXpub)}/0/*`;
  const cold = `${ensureXpub('cold', coldXpub)}/0/*`;
  const recovery = `${ensureXpub('recovery', recoveryXpub)}/1/*`;
  // 2-of-2 hot/cold OR time-locked recovery key
  return `or_d(multi(2,${hot},${cold}),and_v(v:pk(${recovery}),older(${RECOVERY_DELAY})))`;
}

function buildDescriptor({ hotXpub, coldXpub, recoveryXpub }) {
  return `tr(${NUMS_INTERNAL_KEY},${buildScriptTree({ hotXpub, coldXpub, recoveryXpub })})`;
}

function descriptorWithChecksum(descriptor, network = 'signet') {
  const safeDescriptor = assertSafeDescriptor(descriptor);
  const args = [...(NETWORK_FLAGS[network] || []), 'getdescriptorinfo', safeDescriptor];
  const cli = spawnSync('bitcoin-cli', args, { encoding: 'utf8' });
  if (cli.status !== 0) {
    return { descriptor, checksum: null, source: 'local' };
  }
  try {
    const parsed = JSON.parse(cli.stdout);
    return { descriptor: `${parsed.descriptor}#${parsed.checksum}`, checksum: parsed.checksum, source: 'bitcoin-cli' };
  } catch (err) {
    return { descriptor, checksum: null, source: 'local' };
  }
}

function buildImportDescriptor(params, network = 'signet', range = DEFAULT_RANGE, withChecksum = false) {
  const base = assertSafeDescriptor(buildDescriptor(params));
  const full = withChecksum ? descriptorWithChecksum(base, network).descriptor : base;
  return {
    desc: full,
    active: true,
    range: JSON.parse(range),
    timestamp: 'now',
    internal: false,
  };
}

function usage() {
  console.error('Usage: node src/descriptors.js --hot <xpub> --cold <xpub> --recovery <xpub> [--network signet|testnet|mainnet] [--range "[0,999]"] [--with-checksum]');
}

function selftest() {
  const hot = 'tpubD6NzVbkrYhZ4YRta2zJKR8cGe1nq5Se5g8xyZxWQxjV7qo3Z1dCoWH9kH6SHrwUpBAkLTnX2UjsFvdcGaVbL9DJBSSTXobHxPPH1kN6H9We';
  const cold = 'tpubD6NzVbkrYhZ4XUf4r8Q4f4fbQ3qykF5NCz7YsYsJhBKt3vnDnNQfX6BxPTsCkXbkNvVKgfH7C9ZwTe74MkRUYw35vjpsXadB1iKsFcEYJIh';
  const recov = 'tpubD6NzVbkrYhZ4YF1vGjufH6G6DqJziWBGSAdoo6gWQBaUXpBoBPuiGNsq4CPGK8PvX9nuSUXGKmzME2YkdEYY5EYXPLkZX31vT7xGTFeoDyC';
  const descriptor = buildDescriptor({ hotXpub: hot, coldXpub: cold, recoveryXpub: recov });
  if (!descriptor.includes(NUMS_INTERNAL_KEY)) {
    throw new Error('Selftest failed: NUMS key missing');
  }
  if (!descriptor.includes('multi(2')) {
    throw new Error('Selftest failed: multi(2) not present');
  }
  return descriptor;
}

function main(argv) {
  const opts = { network: 'signet', range: DEFAULT_RANGE, withChecksum: false, quiet: false };
  let hot;
  let cold;
  let recovery;
  let runSelftest = false;

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    switch (arg) {
      case '--hot':
        hot = argv[++i];
        break;
      case '--cold':
        cold = argv[++i];
        break;
      case '--recovery':
        recovery = argv[++i];
        break;
      case '--network':
        {
          const nextArg = argv[++i];
          opts.network = nextArg || 'signet';
        }
        break;
      case '--range':
        opts.range = argv[++i] || DEFAULT_RANGE;
        break;
      case '--with-checksum':
        opts.withChecksum = true;
        break;
      case '--quiet':
        opts.quiet = true;
        break;
      case '--selftest':
        runSelftest = true;
        break;
      default:
        usage();
        process.exit(1);
    }
  }

  if (runSelftest) {
    const sample = selftest();
    if (!opts.quiet) {
      console.log('Selftest descriptor:', sample);
    } else {
      console.log(sample);
    }
    return;
  }

  if (!hot || !cold || !recovery) {
    usage();
    process.exit(1);
  }

  const baseDescriptor = assertSafeDescriptor(buildDescriptor({ hotXpub: hot, coldXpub: cold, recoveryXpub: recovery }));
  const finalDesc = opts.withChecksum ? descriptorWithChecksum(baseDescriptor, opts.network).descriptor : baseDescriptor;

  if (!opts.quiet) {
    console.error(`Network: ${opts.network}`);
    console.error(`Range: ${opts.range}`);
    console.error('Descriptor (NUMS internal key forces script-path only):');
  }
  console.log(finalDesc);
}

if (require.main === module) {
  main(process.argv.slice(2));
}

module.exports = {
  NUMS_INTERNAL_KEY,
  RECOVERY_DELAY,
  DEFAULT_RANGE,
  buildScriptTree,
  buildDescriptor,
  descriptorWithChecksum,
  buildImportDescriptor,
  selftest,
};
