# Taproot Wallet Script - Bug Fixes Documentation

This document explains the critical bugs that were fixed in the `create_2of2_taproot_signet.sh` script.

## Overview

The script creates a 2-of-2 multisig Taproot wallet on Bitcoin Signet. This implementation demonstrates the **correct** way to avoid common pitfalls when working with Taproot descriptors and Bitcoin Core RPC.

## Bugs Fixed

### 1. Command Substitution Syntax Error ✓

**Problem:**
```bash
# INCORRECT - pipe is OUTSIDE the command substitution
HOT_PUB=$(bitcoin-cli -signet getdescriptorinfo "tr($XPUB/86'/1'/0'/0/0)") | jq -r .descriptor
```

The closing parenthesis terminates the command substitution before the pipe, so `jq` processes nothing from stdin and the variable contains the full JSON output instead of just the descriptor field.

**Fix:**
```bash
# CORRECT - pipe is INSIDE the command substitution
HOT_PUB=$(bitcoin-cli -signet getdescriptorinfo "tr($XPUB/86'/1'/0'/0/0)" | jq -r .descriptor)
```

**Location in script:** Lines 59-62

---

### 2. Invalid RedeemScript Construction ✓

**Problem:**
```bash
# INCORRECT - string concatenation of opcodes
REDEEMSCRIPT="52 $(echo $HOT_PUB | cut -d'(' -f2 | cut -d')' -f1) $(echo $COLD_PUB | cut -d'(' -f2 | cut -d')' -f1) 2 OP_CHECKMULTISIG 604800 $(bitcoin-cli -signet getblockchaininfo | jq .blocks) OP_CHECKLOCKTIMEVERIFY OP_DROP OP_2DROP"
```

This approach has multiple issues:
- Bitcoin Script cannot be constructed via string concatenation of opcode names
- This produces invalid script data that cannot be executed
- Mixing opcodes with block numbers as strings is invalid
- For Taproot, you cannot use legacy OP_CHECKMULTISIG in script paths

**Fix:**
```bash
# CORRECT - use proper Taproot descriptors
MULTISIG_DESC="tr(${INTERNAL_KEY},{multi_a(2,${HOT_XPUB}/0/*,${COLD_XPUB}/0/*)})"
```

Use Bitcoin Core's descriptor language:
- `tr()` for Taproot
- `multi_a()` for Taproot-native multisig (not legacy OP_CHECKMULTISIG)
- Proper script tree syntax with `{}`
- Let Bitcoin Core handle script compilation

**Location in script:** Lines 99-101

---

### 3. Non-existent bitcoin-cli Command ✓

**Problem:**
```bash
# INCORRECT - 'rawtx' command does not exist
PSBT=$(bitcoin-cli -signet walletprocesspsbt $(bitcoin-cli -signet rawtx $(bitcoin-cli -signet getrawtransaction $TXID) | xxd -p -c 0 | tr -d '\n') | jq -r .psbt)
```

`bitcoin-cli rawtx` is not a valid command in Bitcoin Core.

**Fix:**
```bash
# CORRECT - use walletcreatefundedpsbt for PSBT creation
PSBT=$(bitcoin-cli -signet -rpcwallet=multisig_2of2 walletcreatefundedpsbt \
  '[]' \
  "[{\"$DEST_ADDR\": $AMOUNT}]" | jq -r '.psbt')
```

Valid commands for PSBT workflow:
- `createpsbt` - Create PSBT from specific inputs/outputs
- `walletcreatefundedpsbt` - Create and auto-fund PSBT from wallet
- `fundrawtransaction` - Add inputs to an existing transaction
- `walletprocesspsbt` - Sign PSBT with wallet keys
- `finalizepsbt` - Finalize a fully-signed PSBT

**Location in script:** Lines 159-178

---

### 4. Invalid Taproot Descriptor Syntax ✓

**Problem:**
```bash
# INCORRECT - using '#' for tweaking
TAPROOT_DESC="tr($INTERNAL_PUB#$TWEAK)"
```

This syntax is invalid. The `#` symbol is used for checksums, not for tweaking.

**Fix:**
```bash
# CORRECT - proper Taproot descriptor format
MULTISIG_DESC="tr(${INTERNAL_KEY},{multi_a(2,${HOT_XPUB}/0/*,${COLD_XPUB}/0/*)})"
```

Proper Taproot descriptor syntax:
- `tr(internal_key)` - key-path only spending
- `tr(internal_key,{script_tree})` - key-path OR script-path spending
- Script tree uses: `{leaf1,leaf2}` or `{{leaf1,leaf2},leaf3}` for nested trees
- Use `multi_a()` for Taproot multisig, not legacy `multi()`

**Location in script:** Lines 99-101

---

### 5. Insecure Zero Internal Key ✓

**Problem:**
```bash
# INCORRECT - all zeros is insecure
INTERNAL_PUB="0000000000000000000000000000000000000000000000000000000000000000"
```

An all-zeros internal key is:
- Insecure and may be rejected by Bitcoin Core
- Not a valid point on the secp256k1 curve
- Creates potential security vulnerabilities

**Fix:**
```bash
# CORRECT - use NUMS (Nothing Up My Sleeve) point
INTERNAL_KEY="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"
```

This is the standard NUMS point from BIP341:
- Provably has no known private key
- Valid compressed public key format
- Widely recognized as unspendable
- Makes script-path the only spending option

**Location in script:** Lines 84-87

---

## Additional Improvements ✓

### Error Handling
```bash
set -euo pipefail  # Fail fast on errors
```
- `set -e`: Exit on any command failure
- `set -u`: Error on undefined variables
- `set -o pipefail`: Catch errors in pipes

**Location:** Line 6

### Input Validation
```bash
if [ -z "$HOT_XPUB" ] || [ -z "$COLD_XPUB" ]; then
    echo "❌ Failed to extract xpubs from wallets"
    exit 1
fi
```

Validates that xpubs were successfully extracted before proceeding.

**Location:** Lines 65-68

### Comprehensive Comments
Each section includes explanatory comments showing:
- What the code does
- Why it's done this way
- What to avoid (with INCORRECT examples)
- What's correct (with CORRECT examples)

### Bitcoin Core Availability Check
```bash
if ! command -v bitcoin-cli &> /dev/null; then
    echo "❌ bitcoin-cli not found."
    exit 1
fi
```

Ensures Bitcoin Core is installed before proceeding.

**Location:** Lines 18-21

### Daemon Running Check
```bash
if ! bitcoin-cli "$NET" getblockchaininfo &> /dev/null; then
    echo "❌ Bitcoin signet daemon not running."
    exit 1
fi
```

Verifies the daemon is running before attempting operations.

**Location:** Lines 23-26

---

## Testing the Script

To test the script:

```bash
# 1. Ensure Bitcoin Core is installed
bitcoin-cli --version

# 2. Start signet daemon
bitcoind -signet -daemon

# 3. Wait for initial sync (can take a few minutes)
bitcoin-cli -signet getblockchaininfo

# 4. Run the script
./create_2of2_taproot_signet.sh

# 5. Follow the on-screen instructions to fund and test
```

## Comparison: Wrong vs Right

| Issue | Wrong Approach | Right Approach |
|-------|---------------|----------------|
| Command substitution | `VAR=$(cmd) \| jq` | `VAR=$(cmd \| jq)` |
| Script construction | String concat opcodes | Use descriptors |
| PSBT creation | `bitcoin-cli rawtx` | `walletcreatefundedpsbt` |
| Descriptor syntax | `tr(key#tweak)` | `tr(key,{script})` |
| Internal key | All zeros | NUMS point |
| Error handling | None | `set -euo pipefail` |
| Input validation | None | Check extracted values |

## References

- [BIP 340](https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki) - Schnorr Signatures
- [BIP 341](https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki) - Taproot
- [BIP 342](https://github.com/bitcoin/bips/blob/master/bip-0342.mediawiki) - Tapscript
- [BIP 386](https://github.com/bitcoin/bips/blob/master/bip-0386.mediawiki) - tr() Output Script Descriptors
- [Bitcoin Core Descriptors](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md)
- [Bitcoin Core PSBT Workflow](https://github.com/bitcoin/bitcoin/blob/master/doc/psbt.md)

## Security Notes

⚠️ **This is educational code for testnet/signet only**

- Never use on mainnet without thorough testing
- Always backup wallet descriptors
- Test recovery procedures before funding
- Verify all addresses independently
- Keep private keys secure and separate

## License

This documentation is provided as-is for educational purposes. See repository LICENSE for details.
