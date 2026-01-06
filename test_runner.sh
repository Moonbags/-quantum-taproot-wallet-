#!/bin/bash
# Copyright (c) 2025 sha256sol (Moonbags). All rights reserved.
# Patent pending. Private repository. IP timestamp: 2025-12-31
# Multi-network test runner for quantum taproot wallet
# Supports: regtest, custom signet, public signet, testnet4
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         QUANTUM TAPROOT WALLET - TEST RUNNER              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Select test network:"
echo "  1) REGTEST      - Isolated script iteration (fastest)"
echo "  2) CUSTOM SIGNET - Edge case testing (docker required)"
echo "  3) PUBLIC SIGNET - Stable PSBT finalization"
echo "  4) TESTNET4     - Adversarial spam (final pre-mainnet)"
echo ""
read -rp "Choice [1-4]: " CHOICE

case "$CHOICE" in
    1)
        echo ""
        ./test_regtest.sh
        ;;
    2)
        echo ""
        ./test_custom_signet.sh
        ;;
    3)
        echo ""
        ./test_public_signet.sh
        ;;
    4)
        echo ""
        ./test_testnet4.sh
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

