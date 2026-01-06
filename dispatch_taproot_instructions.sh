#!/bin/bash
# Dispatch Taproot Instructions to GitHub Issues and Cursor IDE
set -euo pipefail

# 1. Define the exact Space Instructions
read -r -d '' PROMPT_BODY << 'EOF' || true
1) From my xpub, derive two child keys—one hot, one cold. 
2) Bake a two-of-two multisig redeemScript with a one-week timelock fallback. 
3) SHA256 that script, then SHA256 again, get a commitment hash. 
4) Build a Taproot descriptor where internal pubkey is a tweaked zero-key, annex is empty, tree leaf is wsh(or_d(multisig,timelock)) locked behind that hash. 
5) fundrawtransaction call—give me the hex, the PSBT, everything.
EOF

# 2. Send to GitHub Copilot (Creates an Issue to start a Workspace session)
# Requires: gh auth login
if command -v gh &> /dev/null; then
    echo "Creating GitHub Issue..."
    if gh issue create \
      --title "Dev: Taproot Multisig Setup with Timelock" \
      --body "$PROMPT_BODY" \
      --label "enhancement"; then
        echo "✅ GitHub Issue created successfully"
    else
        echo "⚠️  GitHub Issue creation failed. Make sure you're authenticated: gh auth login"
    fi
else
    echo "⚠️  GitHub CLI (gh) not found. Install from https://cli.github.com"
    echo "   Skipping GitHub Issue creation..."
fi

# 3. Send to Cursor (Creates file and opens it for Composer)
echo "$PROMPT_BODY" > CURSOR_PROMPT.md
echo "✅ Created CURSOR_PROMPT.md"

if command -v cursor &> /dev/null; then
    echo "Opening in Cursor IDE..."
    cursor CURSOR_PROMPT.md
    # Action: In Cursor, press Ctrl+I (Composer) and reference @CURSOR_PROMPT.md
    echo "✅ Opened in Cursor IDE"
else
    echo "⚠️  Cursor IDE not found in PATH"
    echo "   CURSOR_PROMPT.md created - open it manually in Cursor"
    echo "   In Cursor, press Ctrl+I (Composer) and reference @CURSOR_PROMPT.md"
fi

echo ""
echo "✅ Instructions dispatched to GitHub Issue and local file."
