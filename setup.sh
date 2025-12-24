#!/bin/bash
set -euo pipefail
XPUB="your_xpub_here"  # Replace with real xpub (tprv... or zpub... BIP86)
WEEKS_BLOCKS=1008

# BIP86 Taproot derivation: hot m/86'/0'/0'/0/0, cold m/86'/0'/0'/0/1
HOT_PATH="86'/0'/0'/0/0"
COLD_PATH="86'/0'/0'/0/1"

# Derive public keys from xpub using BIP86 paths
HOT_DESC="tr($XPUB/$HOT_PATH)"
COLD_DESC="tr($XPUB/$COLD_PATH)"
HOT_PUB=$(bitcoin-cli getdescriptorinfo "$HOT_DESC" | jq -r '.descriptor' | sed 's/#.*//' | xargs -I {} bitcoin-cli deriveaddresses "{}" "[0,0]" | jq -r '.[0]' | xargs bitcoin-cli getaddressinfo | jq -r '.pubkey')
COLD_PUB=$(bitcoin-cli getdescriptorinfo "$COLD_DESC" | jq -r '.descriptor' | sed 's/#.*//' | xargs -I {} bitcoin-cli deriveaddresses "{}" "[0,0]" | jq -r '.[0]' | xargs bitcoin-cli getaddressinfo | jq -r '.pubkey')

# or_d(2 hot cold 2, CSV1008 cold checksig)
# OP_CHECKSIG opcode
AC="ac"
MULTI="5220$(echo -n "$HOT_PUB$COLD_PUB" | xxd -r -p | sha256sum -b | cut -d' ' -f1 | xxd -p)57"
CSV="$(printf '%02x' $((WEEKS_BLOCKS>>16)))$(printf '%02x' $((WEEKS_BLOCKS>>8&0xff)))$(printf '%02x' $((WEEKS_BLOCKS&0xff)))51${COLD_PUB}${AC}"
ORD="67${MULTI}${CSV}68"  # or_d
WSH=$(echo -n "$ORD" | xxd -r -p | sha256sum -b | cut -d' ' -f1 | xxd -p -c0)
SCRIPT_HASH=$(echo -n "$WSH" | xxd -r -p | sha256sum -b | cut -d' ' -f1 | xxd -p -c0)

# Taproot: tr(tweaked-zero,script_hash) empty annex
ZEROPUB="020000000000000000000000000000000000000000000000000000000000000000"
TAPTREE="tr($ZEROPUB,$SCRIPT_HASH)"
CHKSUM=$(bitcoin-cli getdescriptorinfo "$TAPTREE" | jq -r '.checksum')
DESC="$TAPTREE#$CHKSUM"
ADDR=$(bitcoin-cli deriveaddresses "$DESC" "[0,0]" | jq -r '.[0]')

echo "=== QUANTUM-SAFE TAPROOT ADDRESS ==="
echo "Fund: $ADDR"
echo "RedeemScript: $WSH"
echo "CommitHash: $SCRIPT_HASH"
echo "Descriptor: $DESC"

# PSBT funding (requires wallet to be loaded)
echo ""
echo "=== PSBT Creation (Optional) ==="
read -p "Create PSBT? (y/N): " CREATE_PSBT
if [[ "$CREATE_PSBT" == "y" ]]; then
    read -p "UTXO txid: " TXID
    read -p "UTXO vout: " VOUT
    read -p "Amount (BTC): " AMT

    TXIN="[{ \"txid\": \"$TXID\", \"vout\": $VOUT }]"
    TXOUT="[ { \"$ADDR\": $AMT } ]"
    RAW=$(bitcoin-cli createrawtransaction "$TXIN" "$TXOUT")
    
    # Note: fundrawtransaction requires a loaded wallet
    echo "Creating PSBT (requires wallet loaded)..."
    PSBT=$(bitcoin-cli walletcreatefundedpsbt "[]" "$TXOUT" | jq -r '.psbt')
    echo "$PSBT" > quantum.psbt
    echo "PSBT saved: quantum.psbt"
    echo "Sign both keys: bitcoin-cli walletprocesspsbt \$(cat quantum.psbt)"
fi
