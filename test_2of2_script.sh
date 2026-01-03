#!/bin/bash
# Test script to validate create_2of2_taproot_signet.sh
# This validates the script structure and syntax without requiring Bitcoin Core

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     TESTING create_2of2_taproot_signet.sh                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT="./create_2of2_taproot_signet.sh"

# Test 1: File exists and is executable
echo "Test 1: File exists and is executable..."
if [ ! -f "$SCRIPT" ]; then
    echo "❌ FAIL: Script file not found"
    exit 1
fi

if [ ! -x "$SCRIPT" ]; then
    echo "❌ FAIL: Script is not executable"
    exit 1
fi
echo "✅ PASS: File exists and is executable"

# Test 2: Syntax check
echo ""
echo "Test 2: Bash syntax validation..."
if ! bash -n "$SCRIPT"; then
    echo "❌ FAIL: Syntax errors detected"
    exit 1
fi
echo "✅ PASS: No syntax errors"

# Test 3: Shellcheck validation
echo ""
echo "Test 3: Shellcheck validation..."
if command -v shellcheck &> /dev/null; then
    if ! shellcheck "$SCRIPT"; then
        echo "❌ FAIL: Shellcheck found issues"
        exit 1
    fi
    echo "✅ PASS: Shellcheck found no issues"
else
    echo "⚠️  SKIP: Shellcheck not available"
fi

# Test 4: Check for critical fixes
echo ""
echo "Test 4: Verify critical fixes are present..."

# Fix 1: Command substitution with pipe inside
if ! grep -q 'jq -r .descriptor)' "$SCRIPT"; then
    echo "❌ FAIL: Fix #1 (command substitution) not found"
    exit 1
fi
echo "✅ PASS: Fix #1 (command substitution) verified"

# Fix 2 & 4: Proper Taproot descriptor
if ! grep -q 'multi_a(2,' "$SCRIPT"; then
    echo "❌ FAIL: Fix #2/#4 (proper descriptor) not found"
    exit 1
fi
echo "✅ PASS: Fix #2/#4 (proper Taproot descriptor) verified"

# Fix 3: walletcreatefundedpsbt instead of rawtx
if ! grep -q 'walletcreatefundedpsbt' "$SCRIPT"; then
    echo "❌ FAIL: Fix #3 (proper PSBT command) not found"
    exit 1
fi

if grep -q 'rawtx' "$SCRIPT" && ! grep -q 'INCORRECT.*rawtx' "$SCRIPT"; then
    echo "❌ FAIL: Fix #3 - script uses invalid 'rawtx' command"
    exit 1
fi
echo "✅ PASS: Fix #3 (walletcreatefundedpsbt) verified"

# Fix 5: NUMS point instead of zeros
if ! grep -q '0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0' "$SCRIPT"; then
    echo "❌ FAIL: Fix #5 (NUMS point) not found"
    exit 1
fi

if grep -q '^INTERNAL.*="00000000000' "$SCRIPT"; then
    echo "❌ FAIL: Fix #5 - script uses all-zeros key"
    exit 1
fi
echo "✅ PASS: Fix #5 (NUMS point) verified"

# Test 5: Additional improvements
echo ""
echo "Test 5: Verify additional improvements..."

# set -euo pipefail
if ! grep -q 'set -euo pipefail' "$SCRIPT"; then
    echo "❌ FAIL: Missing 'set -euo pipefail'"
    exit 1
fi
echo "✅ PASS: Fail-fast behavior enabled"

# Error handling for bitcoin-cli
if ! grep -q 'command -v bitcoin-cli' "$SCRIPT"; then
    echo "❌ FAIL: Missing bitcoin-cli availability check"
    exit 1
fi
echo "✅ PASS: Bitcoin Core availability check present"

# Input validation
if ! grep -q 'if \[ -z.*XPUB' "$SCRIPT"; then
    echo "❌ FAIL: Missing input validation for xpubs"
    exit 1
fi
echo "✅ PASS: Input validation present"

# Test 6: Check documentation
echo ""
echo "Test 6: Verify documentation exists..."
if [ ! -f "FIXES.md" ]; then
    echo "❌ FAIL: FIXES.md documentation not found"
    exit 1
fi
echo "✅ PASS: FIXES.md documentation exists"

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     ALL TESTS PASSED                                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Script structure validated"
echo "✅ All 5 critical fixes verified"
echo "✅ Additional improvements confirmed"
echo "✅ Documentation complete"
echo ""
echo "Note: This validates the script structure only."
echo "For full testing, run the script with Bitcoin Core on signet."
