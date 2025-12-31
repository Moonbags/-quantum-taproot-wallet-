# Copyright Registration Guide
# quantum-taproot-wallet - Part of sha256sol 2025 Projects v1

**Registration Date**: December 31, 2025  
**Cost**: $45 (Group Registration)  
**Processing Time**: ~30 minutes to file

---

## Registration Information

### Work Title
sha256sol 2025 Projects v1 - quantum-taproot-wallet

### Type of Work
Computer Program (Literary Work)

### Author Information
- **Name**: sha256sol
- **Citizenship**: United States
- **Year of Birth**: [To be filled]
- **Author Created**: Computer program code, documentation, shell scripts, testing framework

### Claimant Information
- **Name**: sha256sol (same as author)
- **Address**: [To be filled at filing]

### Rights and Permissions
All rights reserved. © 2025 sha256sol

---

## Work Description

### Nature of Authorship
Computer program consisting of:
- Shell scripts for Bitcoin wallet operations
- Python scripts for testing and automation
- Technical documentation in Markdown format
- Configuration files and deployment scripts
- Multi-network testing framework

### Title of Work Being Registered
quantum-taproot-wallet: A Bitcoin Taproot wallet with quantum-resistant features and time-locked recovery options

### Year of Completion
2025

### Date of First Publication
December 2025

### Nation of First Publication
United States (published via GitHub)

---

## Work Contents

### Source Code Files

#### Shell Scripts (.sh)
1. `setup.sh` - Wallet initialization and configuration
2. `check_balance.sh` - Balance checking utility
3. `spend.sh` - Transaction spending functionality
4. `recovery.sh` - Time-locked recovery mechanism
5. `deploy_testnet.sh` - Testnet deployment script
6. `restart_testnet.sh` - Testnet restart utility
7. `fix_testnet_sync.sh` - Synchronization repair tool
8. `check_rpc_port.sh` - RPC connectivity checker
9. `test_regtest.sh` - Regtest network testing
10. `test_custom_signet.sh` - Custom signet testing
11. `test_public_signet.sh` - Public signet testing
12. `test_testnet4.sh` - Testnet4 network testing
13. `test_runner.sh` - Multi-network test orchestration
14. `fix_sync_manual.sh` - Manual synchronization repair

#### Python Scripts (.py)
1. `faucet.py` - Testnet faucet functionality for automated testing

#### Documentation Files (.md)
1. `README.md` - Main project documentation with architecture and usage
2. `TESTING.md` - Comprehensive testing guide
3. `VERIFICATION.md` - Testnet verification report
4. `VERIFICATION_STATUS.md` - Current verification status
5. `TEST_RESULTS.md` - Testing results documentation

#### Additional Files
1. `LICENSE` - MIT License
2. `.gitignore` - Git configuration
3. `project_hash_2025-12-31.txt` - SHA256 timestamp file

---

## Technical Description

### What the Software Does

The quantum-taproot-wallet is a Bitcoin wallet implementation that provides:

1. **Quantum-Resistant Architecture**: Uses Taproot's privacy features to minimize quantum attack surface by hiding unused public keys in a Merkle tree structure.

2. **Multi-Path Spending**: Supports three independent spending paths:
   - HOT wallet for daily transactions
   - COLD wallet for secure storage
   - RECOVERY path with 1008-block timelock for emergency access

3. **Time-Locked Recovery**: Implements CheckSequenceVerify (CSV) based timelocks enabling fund recovery after ~1 week without exposing hot/cold keys.

4. **Privacy Preservation**: When spending, only reveals the single script path being used, keeping other spending conditions hidden.

5. **Multi-Network Testing**: Comprehensive testing framework supporting:
   - REGTEST for rapid local development
   - CUSTOM SIGNET for edge-case testing
   - PUBLIC SIGNET for stable integration testing
   - TESTNET4 for pre-production validation

### Key Innovations

1. **NUMS Internal Key**: Uses a provably unspendable Nothing Up My Sleeve (NUMS) point as the Taproot internal key, forcing all spends through script paths.

2. **Hidden Script Tree**: Organizes spending conditions in a Taproot Merkle tree where unused branches remain private.

3. **Selective Revelation**: Exposes only one public key per transaction, minimizing quantum attack vectors.

4. **Testnet Verified**: Successfully deployed and tested on Bitcoin Testnet with verified transactions.

### Technical Specifications

- **Bitcoin Version**: Requires Bitcoin Core 28.0+
- **Taproot Support**: Full BIP 341/342 implementation
- **Script Language**: Tapscript with OP_CHECKSIG and OP_CHECKSEQUENCEVERIFY
- **Key Generation**: HD wallet compatible
- **Networks Supported**: Mainnet, Testnet, Testnet4, Signet, Regtest
- **Dependencies**: Bitcoin Core, BDK (Bitcoin Development Kit)

---

## Files to Include in Copyright ZIP

### Required Files
✅ All `.sh` shell scripts (14 files)  
✅ All `.py` Python scripts (1 file)  
✅ All `.md` documentation files (5 files)  
✅ `LICENSE` file  
✅ `.gitignore` file  
✅ `project_hash_2025-12-31.txt` timestamp file

### Excluded Files
❌ `.git/` directory (version control metadata)  
❌ `.cursor/` directory (editor configuration)  
❌ Binary files or compiled code  
❌ Third-party dependencies

---

## Registration Steps

### Step 1: Prepare ZIP File

```bash
cd /home/runner/work/-quantum-taproot-wallet-/-quantum-taproot-wallet-
zip -r quantum-taproot-wallet-copyright.zip \
  *.sh \
  *.py \
  *.md \
  LICENSE \
  .gitignore \
  project_hash_2025-12-31.txt \
  -x "*.git*" -x "*/.cursor/*"
```

### Step 2: Access Copyright.gov

1. Visit https://copyright.gov
2. Click "Register a Work"
3. Select "Register a Group of Published Works"
4. Choose "Literary Works" → "Computer Program"

### Step 3: Complete Application Form

**Application Type**: Group Registration of Published Works  
**Form**: CO (Copyright Office Form)

#### Section 1: Type of Work
- Work Type: Literary Work
- Computer Program: Yes

#### Section 2: Titles
- Title: sha256sol 2025 Projects v1 - quantum-taproot-wallet
- Alternative Titles: quantum-taproot-wallet, Quantum Taproot Wallet

#### Section 3: Publication
- Published: Yes
- Date of First Publication: December 2025
- Nation: United States
- ISBN/ISSN: N/A

#### Section 4: Author(s)
- Author Name: sha256sol
- Author Contribution: Entire work including code and documentation
- Work Made for Hire: No
- Citizenship: United States

#### Section 5: Claimant(s)
- Claimant Name: sha256sol
- Claimant Address: [Fill in your address]

#### Section 6: Limitation of Claim
- None (registering entire work)

#### Section 7: Rights and Permissions
- Rights Holder: sha256sol
- Email: [Your contact email]

#### Section 8: Correspondence
- Email: [Your email for status updates]

#### Section 9: Certification
- Applicant Name: sha256sol
- Date: December 31, 2025

### Step 4: Upload Deposit Copy

Upload: `quantum-taproot-wallet-copyright.zip`

File Requirements:
- Format: ZIP
- Max Size: 500 MB (our file is much smaller)
- Contains: Source code and documentation

### Step 5: Pay Fee

- Fee Amount: $45
- Payment Method: Credit card or electronic check
- Group Registration discount: Included

### Step 6: Submit Application

Review all information, then click "Submit to Copyright Office"

### Step 7: Receive Confirmation

You will receive:
1. Email confirmation immediately
2. Correspondence ID for tracking
3. Registration certificate (6-8 months)

---

## Copyright Notice

Include in all distributed files:

```
Copyright © 2025 sha256sol
All rights reserved.

This work is registered with the U.S. Copyright Office.
Registration: sha256sol 2025 Projects v1
```

---

## Legal Protection

### What Copyright Protects

✅ The specific code implementation  
✅ Documentation and technical writing  
✅ Original comments and explanations  
✅ Unique architectural designs expressed in code  
✅ Testing frameworks and scripts  
✅ Shell script logic and structure

### What Copyright Does NOT Protect

❌ The underlying algorithms (use patents)  
❌ The general idea of quantum-resistant wallets  
❌ Bitcoin protocol specifications  
❌ Programming language syntax  
❌ Standard coding practices

---

## Additional IP Protection

### Combination with Other Protections

This copyright registration works alongside:

1. **Provisional Patent** (filed separately)
   - Protects: Novel technical methods and systems
   - Cost: $150
   - File by: January 2, 2026

2. **Trademark** (filed separately)
   - Protects: "sha256sol" brand name
   - Cost: $250
   - File by: January 2026

3. **Trade Secret**
   - Protects: Proprietary development processes
   - Cost: Free (maintain confidentiality)

### Benefits of Registration

1. **Public Record**: Establishes date of creation
2. **Legal Standing**: Required to file infringement lawsuit
3. **Statutory Damages**: Eligible for up to $150,000 per infringement
4. **Attorney's Fees**: Can recover legal costs if you win
5. **Customs Protection**: Can stop imports of infringing works

---

## Maintenance

### Copyright Duration
- Term: Life of author + 70 years
- Renewal: Not required
- Maintenance: None

### Updating Registration
If substantial changes are made, file a new registration for the updated version.

---

## Reference Information

### Copyright Office Contact
- Website: https://copyright.gov
- Phone: (202) 707-3000
- Hours: Monday-Friday, 8:30 AM - 5:00 PM ET

### Registration Status
Check status at: https://copyright.gov/eco (using your correspondence ID)

### Certificate Delivery
- Timeline: 6-8 months for standard processing
- Rush service: Available for additional fee
- Electronic certificate: Yes, via email

---

**Document Prepared**: December 31, 2025  
**For**: sha256sol 2025 Projects v1 - quantum-taproot-wallet  
**Cost**: $45  
**Timeline**: 30 minutes to file, 6-8 months for certificate
