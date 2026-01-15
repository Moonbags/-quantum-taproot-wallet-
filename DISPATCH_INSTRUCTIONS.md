# Dispatch Taproot Instructions

This script (`dispatch_taproot_instructions.sh`) is a development workflow tool that helps dispatch Taproot multisig setup instructions to both GitHub Issues and Cursor IDE.

## Purpose

The script defines specific instructions for creating a Taproot-based wallet with:
1. Deriving hot and cold child keys from an xpub
2. Creating a 2-of-2 multisig redeemScript with 1-week timelock fallback
3. Double SHA256 hashing for commitment
4. Taproot descriptor with tweaked zero-key internal pubkey
5. `fundrawtransaction` call for hex and PSBT generation

## Usage

### Prerequisites

- **For GitHub Issues**: Install and authenticate with GitHub CLI
  ```bash
  gh auth login
  ```

- **For Cursor**: Install [Cursor IDE](https://cursor.sh)

### Running the Script

```bash
./dispatch_taproot_instructions.sh
```

### What It Does

1. **Creates GitHub Issue**: Opens a new issue with title "Dev: Taproot Multisig Setup with Timelock" and the detailed instructions
2. **Creates Local File**: Generates `CURSOR_PROMPT.md` with the same instructions
3. **Opens in Cursor**: Launches Cursor IDE with the prompt file (if `cursor` command is available)

### Output

- A new GitHub Issue labeled "enhancement"
- If the repository has a `copilot/allow-code-execution-on-terminal` label, the issue includes it to allow Copilot Workspace terminal execution
- A local file `CURSOR_PROMPT.md` (ignored by git)
- Confirmation message: "✅ Instructions dispatched to GitHub Issue and local file."

## Instructions Content

The script dispatches the following technical requirements:

1. From my xpub, derive two child keys—one hot, one cold.
2. Bake a two-of-two multisig redeemScript with a one-week timelock fallback.
3. SHA256 that script, then SHA256 again, get a commitment hash.
4. Build a Taproot descriptor where internal pubkey is a tweaked zero-key, annex is empty, tree leaf is wsh(or_d(multisig,timelock)) locked behind that hash.
5. fundrawtransaction call—give me the hex, the PSBT, everything.

## Notes

- The generated `CURSOR_PROMPT.md` file is automatically ignored by git (see `.gitignore`)
- Requires GitHub CLI (`gh`) to be installed and authenticated for issue creation
- To enable Copilot Workspace terminal commands, create the `copilot/allow-code-execution-on-terminal` label in the repo
- Requires Cursor IDE to be installed for the IDE integration
- The script can be run multiple times; it will create new issues each time

## Integration with Existing Scripts

This is a development workflow tool and complements the existing scripts:
- `setup.sh` - Creates the actual quantum wallet
- `deploy_signet.sh` - Deploys to signet network
- `spend.sh` - Spends from the wallet
- `recovery.sh` - Uses timelock recovery path
