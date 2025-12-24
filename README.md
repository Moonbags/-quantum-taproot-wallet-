# Quantum Taproot Wallet

A professional Bitcoin Taproot wallet setup tool with quantum-resistant features using BIP86 derivation, multisig security, and time-locked recovery options.

## Features

- **BIP86 Taproot Derivation**: Proper m/86'/0'/0'/0/0 paths for hot and cold keys
- **Quantum-Safe Hashlock**: Uses multisig with SHA256 hashing for quantum resistance
- **Time-Locked Fallback**: CSV (CheckSequenceVerify) for 1008 blocks (~1 week) cold key recovery
- **PSBT Support**: Partially Signed Bitcoin Transactions for secure multi-party signing
- **Correct or_d Opcodes**: Professional implementation of conditional spending paths
- **Zero-Key Tweak**: Proper Taproot internal key tweaking with annex handling

## Requirements

- Bitcoin Core with `bitcoin-cli` installed
- `jq` for JSON processing
- `xxd` for hex conversion

## Project Structure

```
quantum-taproot-wallet/
├── README.md          # Main docs + setup
├── setup.sh           # Executable script (BIP86 compliant)
└── LICENSE            # MIT license
```

## Setup

1. Edit `setup.sh` and replace `your_xpub_here` with your actual BIP86 xpub
2. Run the setup script:

```bash
./setup.sh
```

3. The script will:
   - Derive hot and cold public keys using BIP86 paths
   - Generate quantum-safe multisig redeemScript with or_d opcodes
   - Create Taproot address with proper zero-key tweak
   - Prompt for UTXO details to create a PSBT
   - Save `quantum.psbt` for signing

## Usage

After running the script, you'll receive:
- A Taproot address to fund
- RedeemScript hash for verification
- PSBT file (`quantum.psbt`) for signing

Sign the PSBT with both keys:
```bash
bitcoin-cli walletprocesspsbt quantum.psbt
```

⚠️ **NOT FINANCIAL ADVICE. Test on testnet first.**
