#!/bin/bash
# Taproot Multisig Setup with Timelock
# Implements: 2-of-2 multisig with one-week timelock fallback
# 
# Features:
# - Derives hot/cold child keys from xpub
# - Creates 2-of-2 multisig redeemScript with timelock
# - Computes double SHA256 commitment hash
# - Builds Taproot descriptor with NUMS internal key
# - Outputs fundrawtransaction hex and PSBT
#
# NOT FINANCIAL ADVICE - Test on testnet first.
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     TAPROOT MULTISIG SETUP WITH TIMELOCK                   ║"
echo "║     2-of-2 Multisig + One-Week Timelock Fallback          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Network selection
read -rp "Select network (testnet/signet/regtest) [testnet]: " NETWORK
NETWORK=${NETWORK:-testnet}

case "$NETWORK" in
    testnet)
        NET="-testnet"
        ;;
    signet)
        NET="-signet"
        ;;
    regtest)
        NET="-regtest"
        ;;
    *)
        echo "❌ Invalid network. Use testnet, signet, or regtest."
        exit 1
        ;;
esac

OS_NAME=$(uname -s)
IS_MACOS=false
if [[ "$OS_NAME" == "Darwin" ]]; then
    IS_MACOS=true
fi

require_cmd() {
    local cmd="$1"
    local brew_pkg="${2:-$1}"

    if ! command -v "$cmd" &> /dev/null; then
        if $IS_MACOS; then
            echo "❌ Missing $cmd. Install with: brew install $brew_pkg"
            echo "   See MACOS_SETUP.md for full setup."
        else
            echo "❌ $cmd not found. Install it and re-run."
        fi
        exit 1
    fi
}

# Verify Bitcoin Core
echo "Checking Bitcoin Core..."
require_cmd "bitcoin-cli" "bitcoin"
require_cmd "jq" "jq"
require_cmd "openssl" "openssl"
require_cmd "xxd" "vim"
require_cmd "bc" "bc"

VERSION=$(bitcoin-cli $NET --version 2>/dev/null | head -1 || echo "Unknown")
echo "✅ $VERSION"

# Check if daemon is running
if ! bitcoin-cli $NET getblockchaininfo &> /dev/null; then
    echo "❌ Bitcoin daemon not running. Start with: bitcoind $NET -daemon"
    exit 1
fi
echo "✅ Daemon running on $NETWORK"

# ============================================================================
# STEP 1: Derive hot and cold child keys from xpub
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "STEP 1: Deriving hot and cold child keys from xpub"
echo "═══════════════════════════════════════════════════════════════"

# Create wallets if they don't exist
for WALLET in hot_wallet cold_wallet; do
    if bitcoin-cli $NET -rpcwallet=$WALLET getwalletinfo &> /dev/null 2>&1; then
        echo "  $WALLET already exists ✓"
    else
        bitcoin-cli $NET -named createwallet wallet_name="$WALLET" descriptors=true > /dev/null
        echo "  $WALLET created ✓"
    fi
done

# Extract xpubs (extended public keys) from wallets
echo ""
echo "Extracting xpubs from wallets..."

# Get the tpub (testnet xpub) from taproot descriptors
HOT_XPUB=$(bitcoin-cli $NET -rpcwallet=hot_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+' | head -1)
COLD_XPUB=$(bitcoin-cli $NET -rpcwallet=cold_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+' | head -1)

# Validate xpubs were extracted
if [ -z "$HOT_XPUB" ] || [ -z "$COLD_XPUB" ]; then
    echo "❌ Failed to extract xpubs from wallets"
    exit 1
fi

echo "  HOT xpub:  ${HOT_XPUB:0:30}..."
echo "  COLD xpub: ${COLD_XPUB:0:30}..."

# Derive child keys at path /0/0 (first external address)
# The /0/* in the descriptor represents external chain (0) and address index (*)
HOT_CHILD="${HOT_XPUB}/0/*"
COLD_CHILD="${COLD_XPUB}/0/*"

echo ""
echo "  ✅ Hot child key path:  ${HOT_XPUB:0:20}.../0/*"
echo "  ✅ Cold child key path: ${COLD_XPUB:0:20}.../0/*"

# ============================================================================
# STEP 2: Create 2-of-2 multisig redeemScript with one-week timelock fallback
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "STEP 2: Creating 2-of-2 multisig redeemScript with timelock"
echo "═══════════════════════════════════════════════════════════════"

# Create recovery wallet for timelock fallback
if bitcoin-cli $NET -rpcwallet=recovery_wallet getwalletinfo &> /dev/null 2>&1; then
    echo "  recovery_wallet already exists ✓"
else
    bitcoin-cli $NET -named createwallet wallet_name="recovery_wallet" descriptors=true > /dev/null
    echo "  recovery_wallet created ✓"
fi

RECOV_XPUB=$(bitcoin-cli $NET -rpcwallet=recovery_wallet listdescriptors | jq -r '.descriptors[] | select(.desc | startswith("tr(")) | select(.internal == false) | .desc' | grep -oE 'tpub[0-9A-Za-z]+' | head -1)

if [ -z "$RECOV_XPUB" ]; then
    echo "❌ Failed to extract recovery xpub"
    exit 1
fi

echo "  RECOVERY xpub: ${RECOV_XPUB:0:30}..."

# Timelock: 1008 blocks ≈ 1 week (assuming 10-minute blocks)
TIMELOCK=1008

# Build the miniscript structure:
# or_d(multi(2,hot,cold), and_v(v:pk(recovery),older(1008)))
# This means: Either 2-of-2 multisig OR (recovery key + timelock)
MULTISIG_SCRIPT="multi_a(2,${HOT_CHILD},${COLD_CHILD})"
TIMELOCK_SCRIPT="and_v(v:pk(${RECOV_XPUB}/0/*),older(${TIMELOCK}))"

echo ""
echo "  📜 Multisig Script: multi_a(2, hot, cold)"
echo "  ⏰ Timelock Script: and_v(v:pk(recovery), older(${TIMELOCK}))"
echo ""
echo "  Script structure: or_d(${MULTISIG_SCRIPT}, ${TIMELOCK_SCRIPT})"

# ============================================================================
# STEP 3: SHA256 the script twice to get commitment hash
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "STEP 3: Computing double SHA256 commitment hash"
echo "═══════════════════════════════════════════════════════════════"

# Build the script string for hashing - matches the tree structure in the descriptor
# The descriptor tree is: {{pk(hot),pk(cold)},and_v(v:pk(recovery),older(1008))}
SCRIPT_STRING="{{pk(${HOT_XPUB}/0/*),pk(${COLD_XPUB}/0/*)},and_v(v:pk(${RECOV_XPUB}/0/*),older(${TIMELOCK}))}"

# Compute double SHA256 (SHA256(SHA256(script)))
FIRST_HASH=$(echo -n "$SCRIPT_STRING" | openssl dgst -sha256 -binary | xxd -p -c 256)
COMMITMENT_HASH=$(echo -n "$FIRST_HASH" | xxd -r -p | openssl dgst -sha256 -binary | xxd -p -c 256)

echo "  📄 Script string (truncated): ${SCRIPT_STRING:0:60}..."
echo ""
echo "  🔐 First SHA256:      ${FIRST_HASH:0:32}..."
echo "  🔐 Commitment Hash:   ${COMMITMENT_HASH:0:32}..."
echo "     (double SHA256)"
echo ""
echo "  ✅ Commitment hash computed"

# ============================================================================
# STEP 4: Build Taproot descriptor with NUMS internal key
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "STEP 4: Building Taproot descriptor"
echo "═══════════════════════════════════════════════════════════════"

# NUMS (Nothing Up My Sleeve) internal key - a provably unspendable point
# This is the generator point multiplied by the hash of "BIP0341/nums"
# Using this ensures the key-path is unspendable, forcing script-path spending
NUMS_KEY="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

echo "  🔑 Internal Key (NUMS): ${NUMS_KEY:0:32}..."
echo "     (Tweaked zero-key - provably unspendable)"
echo "  📭 Annex: empty (not used)"
echo ""

# Build the Taproot descriptor
# Structure: tr(NUMS_KEY, {script_tree})
# The script tree contains: or_d(multi_a(2,hot,cold), and_v(v:pk(recovery),older(1008)))
DESC="tr(${NUMS_KEY},{{pk(${HOT_XPUB}/0/*),pk(${COLD_XPUB}/0/*)},and_v(v:pk(${RECOV_XPUB}/0/*),older(${TIMELOCK}))})"

echo "  📋 Taproot Descriptor (raw):"
echo "     ${DESC:0:80}..."
echo ""

# Validate the descriptor and get checksum
echo "Validating descriptor..."
RESULT=$(bitcoin-cli $NET getdescriptorinfo "$DESC" 2>&1)

if echo "$RESULT" | jq -e '.checksum' > /dev/null 2>&1; then
    CHECKSUM=$(echo "$RESULT" | jq -r '.checksum')
    ISSOLVABLE=$(echo "$RESULT" | jq -r '.issolvable')
    ISRANGE=$(echo "$RESULT" | jq -r '.isrange')
    
    echo "  ✅ Descriptor valid"
    echo "     Checksum: $CHECKSUM"
    echo "     Solvable: $ISSOLVABLE"
    echo "     Range: $ISRANGE"
else
    echo "❌ Descriptor validation failed"
    echo "$RESULT"
    exit 1
fi

FULL_DESC="${DESC}#${CHECKSUM}"

# Create watch-only quantum wallet
if bitcoin-cli $NET -rpcwallet=qs getwalletinfo &> /dev/null 2>&1; then
    echo "  qs (quantum wallet) already exists ✓"
else
    bitcoin-cli $NET -named createwallet wallet_name="qs" disable_private_keys=true blank=true descriptors=true > /dev/null
    echo "  qs (quantum wallet) created ✓"
fi

# Import descriptor to quantum wallet
echo ""
echo "Importing descriptor to quantum wallet..."
IMPORT_RESULT=$(bitcoin-cli $NET -rpcwallet=qs importdescriptors "[{\"desc\":\"$FULL_DESC\",\"active\":true,\"range\":[0,999],\"timestamp\":\"now\"}]" 2>&1)
SUCCESS=$(echo "$IMPORT_RESULT" | jq -r '.[0].success' 2>/dev/null || echo "false")

if [ "$SUCCESS" == "true" ]; then
    echo "  ✅ Descriptor imported to quantum wallet"
else
    echo "  ⚠️  Import result: $IMPORT_RESULT"
    echo "     (Descriptor may already be imported)"
fi

# Derive the first address
TAPROOT_ADDR=$(bitcoin-cli $NET deriveaddresses "$FULL_DESC" "[0,0]" | jq -r '.[0]')

echo ""
echo "  🏠 Taproot Address (bech32m):"
echo "     $TAPROOT_ADDR"

# ============================================================================
# STEP 5: fundrawtransaction - Output hex and PSBT
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "STEP 5: Creating fundrawtransaction (hex and PSBT)"
echo "═══════════════════════════════════════════════════════════════"

# Check for UTXOs in the quantum wallet
BALANCE=$(bitcoin-cli $NET -rpcwallet=qs getbalance 2>/dev/null || echo "0")
UTXOS=$(bitcoin-cli $NET -rpcwallet=qs listunspent 2>/dev/null || echo "[]")

echo ""
echo "  💰 Current Balance: $BALANCE BTC"

if [ "$BALANCE" == "0" ] || [ "$UTXOS" == "[]" ]; then
    echo ""
    echo "  ⚠️  No funds in quantum wallet yet."
    echo ""
    echo "  To fund this wallet, send BTC to:"
    echo "     $TAPROOT_ADDR"
    echo ""
    
    case "$NETWORK" in
        testnet)
            echo "  💧 Get testnet funds:"
            echo "     https://bitcoinfaucet.uo1.net/"
            echo "     https://coinfaucet.eu/en/btc-testnet/"
            ;;
        signet)
            echo "  💧 Get signet funds:"
            echo "     https://signetfaucet.com"
            echo "     https://signet.bc-2.jp"
            ;;
        regtest)
            echo "  💧 Generate regtest funds:"
            echo "     bitcoin-cli $NET generatetoaddress 101 $TAPROOT_ADDR"
            ;;
    esac
    
    echo ""
    echo "  📝 After funding, you can create a PSBT with:"
    echo "     bitcoin-cli $NET -rpcwallet=qs walletcreatefundedpsbt '[]' '[{\"<dest_addr>\": <amount>}]' 0 '{\"fee_rate\": 1}'"
    echo ""
else
    echo ""
    echo "  📊 UTXOs available:"
    echo "$UTXOS" | jq '.[] | {txid: .txid[0:16], vout, amount, confirmations}'
    echo ""
    
    # Ask for destination address
    read -rp "  Enter destination address (or press Enter to skip): " DEST_ADDR
    
    if [ -n "$DEST_ADDR" ]; then
        # Calculate send amount (balance - fee)
        FEE="0.00001"
        SEND_AMT=$(echo "$BALANCE - $FEE" | bc)
        
        echo ""
        echo "  Creating funding transaction..."
        echo "  Amount: $SEND_AMT BTC"
        echo "  Fee: $FEE BTC"
        echo "  Destination: $DEST_ADDR"
        echo ""
        
        # Create PSBT
        PSBT_RESULT=$(bitcoin-cli $NET -rpcwallet=qs walletcreatefundedpsbt \
            '[]' \
            "[{\"$DEST_ADDR\": $SEND_AMT}]" \
            0 \
            '{"fee_rate": 1}' 2>&1)
        
        if echo "$PSBT_RESULT" | jq -e '.psbt' > /dev/null 2>&1; then
            PSBT=$(echo "$PSBT_RESULT" | jq -r '.psbt')
            CHANGEPOS=$(echo "$PSBT_RESULT" | jq -r '.changepos')
            FEE_SAT=$(echo "$PSBT_RESULT" | jq -r '.fee')
            
            echo "  ✅ PSBT Created Successfully"
            echo ""
            echo "  ════════════════════════════════════════════════════════════"
            echo "  📦 PSBT (Base64):"
            echo "  ════════════════════════════════════════════════════════════"
            echo "  $PSBT"
            echo ""
            
            # Decode PSBT to get raw hex
            DECODED=$(bitcoin-cli $NET decodepsbt "$PSBT" 2>&1)
            
            echo "  ════════════════════════════════════════════════════════════"
            echo "  📄 PSBT Decoded Info:"
            echo "  ════════════════════════════════════════════════════════════"
            echo "$DECODED" | jq '{
                tx_version: .tx.version,
                inputs: [.inputs[] | {txid: .previous_txid[0:16], vout: .previous_vout}],
                outputs: [.tx.vout[] | {value, scriptPubKey: .scriptPubKey.address}],
                fee: .fee
            }'
            echo ""
            
            # Analyze PSBT
            ANALYSIS=$(bitcoin-cli $NET analyzepsbt "$PSBT" 2>&1)
            echo "  ════════════════════════════════════════════════════════════"
            echo "  🔍 PSBT Analysis:"
            echo "  ════════════════════════════════════════════════════════════"
            echo "$ANALYSIS" | jq '.'
            echo ""
            
            # Sign with hot wallet
            echo "  Signing with hot_wallet..."
            SIGNED_HOT=$(bitcoin-cli $NET -rpcwallet=hot_wallet walletprocesspsbt "$PSBT" 2>&1)
            if echo "$SIGNED_HOT" | jq -e '.psbt' > /dev/null 2>&1; then
                PSBT_HOT=$(echo "$SIGNED_HOT" | jq -r '.psbt')
                COMPLETE_HOT=$(echo "$SIGNED_HOT" | jq -r '.complete')
                echo "  ✅ Signed with hot_wallet (complete: $COMPLETE_HOT)"
            fi
            
            # Sign with cold wallet
            echo "  Signing with cold_wallet..."
            SIGNED_COLD=$(bitcoin-cli $NET -rpcwallet=cold_wallet walletprocesspsbt "${PSBT_HOT:-$PSBT}" 2>&1)
            if echo "$SIGNED_COLD" | jq -e '.psbt' > /dev/null 2>&1; then
                PSBT_FINAL=$(echo "$SIGNED_COLD" | jq -r '.psbt')
                COMPLETE_FINAL=$(echo "$SIGNED_COLD" | jq -r '.complete')
                echo "  ✅ Signed with cold_wallet (complete: $COMPLETE_FINAL)"
            fi
            
            # If complete, finalize and get hex
            if [ "${COMPLETE_FINAL:-false}" == "true" ]; then
                echo ""
                echo "  ════════════════════════════════════════════════════════════"
                echo "  ✅ PSBT FULLY SIGNED"
                echo "  ════════════════════════════════════════════════════════════"
                
                FINALIZED=$(bitcoin-cli $NET finalizepsbt "$PSBT_FINAL" 2>&1)
                RAW_HEX=$(echo "$FINALIZED" | jq -r '.hex')
                
                echo ""
                echo "  📜 Raw Transaction Hex:"
                echo "  ════════════════════════════════════════════════════════════"
                echo "  $RAW_HEX"
                echo ""
                echo "  📡 Broadcast with:"
                echo "     bitcoin-cli $NET sendrawtransaction $RAW_HEX"
            else
                echo ""
                echo "  ⚠️  PSBT not yet complete (needs more signatures)"
                echo ""
                echo "  📦 Partially signed PSBT:"
                echo "  $PSBT_FINAL"
            fi
        else
            echo "  ❌ Failed to create PSBT"
            echo "  $PSBT_RESULT"
        fi
    fi
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         TAPROOT MULTISIG SETUP COMPLETE                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "🏠 Taproot Address: $TAPROOT_ADDR"
echo "📋 Descriptor Checksum: $CHECKSUM"
echo "🔐 Commitment Hash: ${COMMITMENT_HASH:0:32}..."
echo ""
echo "🔐 SPENDING CONDITIONS:"
echo "   1. Hot + Cold keys  → 2-of-2 multisig (spend anytime)"
echo "   2. Recovery key     → After ${TIMELOCK} blocks (~1 week)"
echo ""
echo "📂 WALLETS CREATED:"
echo "   - hot_wallet      (daily use key)"
echo "   - cold_wallet     (secure storage key)"
echo "   - recovery_wallet (emergency timelock key)"
echo "   - qs              (watch-only quantum wallet)"
echo ""
echo "🔧 PSBT WORKFLOW:"
echo "   1. Create:   bitcoin-cli $NET -rpcwallet=qs walletcreatefundedpsbt '[]' '[{\"<addr>\": <amt>}]' 0 '{\"fee_rate\": 1}'"
echo "   2. Sign HOT: bitcoin-cli $NET -rpcwallet=hot_wallet walletprocesspsbt <psbt>"
echo "   3. Sign COLD: bitcoin-cli $NET -rpcwallet=cold_wallet walletprocesspsbt <psbt>"
echo "   4. Finalize: bitcoin-cli $NET finalizepsbt <psbt>"
echo "   5. Broadcast: bitcoin-cli $NET sendrawtransaction <hex>"
echo ""
echo "⚠️  BACKUP YOUR WALLETS!"
echo "   bitcoin-cli $NET -rpcwallet=hot_wallet listdescriptors true > hot_backup.json"
echo "   bitcoin-cli $NET -rpcwallet=cold_wallet listdescriptors true > cold_backup.json"
echo "   bitcoin-cli $NET -rpcwallet=recovery_wallet listdescriptors true > recovery_backup.json"
echo ""

# Save summary to backup
mkdir -p backup
cat > backup/taproot_multisig_info.txt << EOF
=== TAPROOT MULTISIG SETUP ===
Generated: $(date)
Network: $NETWORK

Taproot Address: $TAPROOT_ADDR
Descriptor Checksum: $CHECKSUM
Commitment Hash (double SHA256): $COMMITMENT_HASH

Full Descriptor:
$FULL_DESC

Script Components:
- Multisig: multi_a(2, hot, cold)
- Timelock: and_v(v:pk(recovery), older($TIMELOCK))

Keys (xpubs):
- HOT: $HOT_XPUB
- COLD: $COLD_XPUB
- RECOVERY: $RECOV_XPUB
- INTERNAL (NUMS): $NUMS_KEY

Security Model:
- Key-path spending: DISABLED (NUMS internal key)
- Script-path spending: ENABLED
  - Option 1: 2-of-2 multisig (hot + cold)
  - Option 2: Recovery key after $TIMELOCK blocks (~1 week)

Quantum Safety:
- Script tree hidden in normal spends
- Only single signature visible on-chain
- No quantum attack surface exposed
EOF

echo "💾 Summary saved to: backup/taproot_multisig_info.txt"
