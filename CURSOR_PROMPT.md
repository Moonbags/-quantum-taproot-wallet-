# Taproot Multisig Setup with Timelock

## Instructions

1) From my xpub, derive two child keys—one hot, one cold. 
2) Bake a two-of-two multisig redeemScript with a one-week timelock fallback. 
3) SHA256 that script, then SHA256 again, get a commitment hash. 
4) Build a Taproot descriptor where internal pubkey is a tweaked zero-key, annex is empty, tree leaf is wsh(or_d(multisig,timelock)) locked behind that hash. 
5) fundrawtransaction call—give me the hex, the PSBT, everything.

## Implementation

See `taproot_multisig_setup.sh` for the full implementation of these instructions.

### Quick Usage

```bash
./taproot_multisig_setup.sh
```

This script will:
- Derive hot and cold child keys from your xpub
- Create a 2-of-2 multisig redeemScript with one-week (1008 blocks) timelock fallback
- Compute the double SHA256 commitment hash
- Build the Taproot descriptor with NUMS (tweaked zero-key) internal key
- Output the raw transaction hex and PSBT for funding
