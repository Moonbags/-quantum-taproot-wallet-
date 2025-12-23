# Quantum-Resistant Taproot: Script-Path Only Wallet

Bitcoin Core 25.0+ descriptor wallet **permanently disables key-path spends** using NUMS internal key (no known discrete log). Forces script-path only.

> **NOT FINANCIAL ADVICE. Do this at your own risk. Test on testnet first.**

## Spend Conditions
- **Normal**: 2-of-2 hot/cold xpubs  
- **Recovery**: Single recovery xpub after ~1 week (1008 blocks)

## Setup (Mainnet 25.0)
```bash
INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"
HOT="[[fingerprint/86'/1'/0'/0/0]xpubYourHotXpubHere]"
COLD="[[fingerprint/86'/1'/0'/0/1]xpubYourColdXpubHere]"
RECOV="[[fingerprint/86'/1'/0'/1/0]xpubYourRecoveryXpubHere]"

BASE_DESC="tr($INTERNAL,{{or_d(pk_h($HOT),pk_h($COLD),and_v(v:pk_h($RECOV),older(1008)))}})"
CHECKSUM=$(bitcoin-cli getdescriptorinfo "$BASE_DESC" | jq -r '.checksum')
DESC="${BASE_DESC}#${CHECKSUM}"

bitcoin-cli createwallet "qs" true true false true false
bitcoin-cli -rpcwallet=qs -named importdescriptors '[{"desc":"'"$DESC"'","active":true,"range":[0,999],"timestamp":"now","internal":false}]'
ADDR=$(bitcoin-cli -rpcwallet=qs -named deriveaddresses descriptor="$DESC" range="[0,0]" | jq -r '.[0]')
echo "Fund: $ADDR"
```

## Why NUMS?
Internal: `0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0`—no privkey → key-path impossible forever. Wallet auto-tweaks output key.

## Test First
1. Use `bitcoin-cli -testnet`
2. Verify descriptor: `bitcoin-cli getdescriptorinfo "$BASE_DESC"`
3. Fund small amount, test spends

## License
MIT License - see LICENSE file.
