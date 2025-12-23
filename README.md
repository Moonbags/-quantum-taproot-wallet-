# Quantum Taproot Wallet (NUMS-enforced script path)

Taproot exposes internal keys on-chain; key-path spends remain vulnerable to Shor’s attack. This wallet forces **script-path only** by using a NUMS internal key (no private key exists) and commits a Taproot tree with:

- `multi(2, hot, cold)` script leaf (2-of-2)
- `and_v(v:pk(recovery), older(1008))` recovery leaf (~1 week)
- Optional SHA256 Merkle commitments for additional script leaves

Post-quantum signature stubs (ML-DSA/Falcon style) and sweep planning are provided for testing and simulation. Mainnet/Signet ready with Bitcoin Core 25.0+.

## Project Structure

```
quantum-taproot-wallet/
├── setup.sh                # Interactive descriptor generation & wallet import
├── src/
│   ├── descriptors.js      # Taproot NUMS descriptor builder
│   ├── quantum-vault.js    # SHA256 Merkle commitments
│   ├── signatures.js       # PQ signature stubs (ML-DSA/Falcon)
│   └── sweep.js            # UTXO batching (~1.5KB/input, 100KB batches)
├── test/test-descriptor.sh # Signet descriptor validation helper
├── security-audit.js       # Lightweight NUMS/WIF checks + audit reminder
├── README.md
├── LICENSE (MIT)
└── package.json
```

## Prerequisites

- Bitcoin Core 25.0+ (`bitcoin-cli`), `jq`
- Node.js 18+

## Quickstart (Signet by default)

```bash
chmod +x setup.sh test/test-descriptor.sh
./setup.sh
```

Inputs required:

- Hot xpub: `m/86'/{net}'/0'/0/0`
- Cold xpub: `m/86'/{net}'/0'/0/1`
- Recovery xpub: `m/86'/{net}'/0'/1/0`
- Network: `signet` | `testnet` | `mainnet`

The script:

1) Builds `tr(NUMS, or_d(multi(2,hot,cold), and_v(v:pk(recovery), older(1008))))`
2) Appends checksum via `bitcoin-cli getdescriptorinfo`
3) Imports descriptor range `[0,999]`
4) Prints first receive address to fund

## Descriptor validation (optional)

```bash
./test/test-descriptor.sh
```

If `bitcoin-cli --signet` is available, the script validates the descriptor. Otherwise it performs static checks for the NUMS key and `multi(2)` leaf.

## Security & audits

- NUMS internal key: `0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0` (no private key)
- Script-path only: key-path disabled forever
- Recovery delay: 1008 blocks (~1 week)
- Merkle commitments: `src/quantum-vault.js` (SHA256 tree ~128-bit PQ security vs Grover)
- PQ stubs: `src/signatures.js` (demo only, not production crypto)
- Run `npm run security-audit` for local sanity checks and Slither reminder

⚠️ **Testnet/Signet only. Not financial advice. Audit before mainnet use.**
