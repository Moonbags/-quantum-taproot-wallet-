#!/bin/bash
# NOT FINANCIAL ADVICE. Testnet first. Your risk.
INTERNAL="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"
echo "Replace HOT/COLD/RECOV xpubs below"
HOT="[[fingerprint/86'/1'/0'/0/0]xpubHOT]"
COLD="[[fingerprint/86'/1'/0'/0/1]xpubCOLD]"
RECOV="[[fingerprint/86'/1'/0'/1/0]xpubRECOV]"
BASE_DESC="tr($INTERNAL,{or_d(pk_h($HOT),pk_h($COLD),and_v(v:pk_h($RECOV),older(1008)))})"
CHECKSUM=$(bitcoin-cli getdescriptorinfo "$BASE_DESC" | jq -r '.checksum')
DESC="${BASE_DESC}#${CHECKSUM}"
echo "Descriptor: $DESC"
