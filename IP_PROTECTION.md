# IP Protection Documentation - December 31, 2025

This document provides guidance for protecting the intellectual property of the quantum-taproot-wallet project.

## IP Timestamp - December 31, 2025

**Hash File**: `project_hash_2025-12-31.txt`

This file contains SHA256 hashes of all project files as of December 31, 2025, establishing a timestamp for intellectual property purposes.

## Copyright Registration

### Group Registration at copyright.gov

**Title**: "sha256sol 2025 Projects v1"  
**Cost**: $45  
**Timeline**: 30 minutes

#### Materials to Upload

1. **quantum-taproot-wallet** (this project)
   - Type: Computer code and documentation
   - Format: ZIP file
   - Contents: All source code, scripts, and documentation

#### Registration Details

- **Author**: sha256sol
- **Year of Creation**: 2025
- **Publication Status**: Published
- **Rights and Permissions**: All rights reserved
- **Nature of Authorship**: Computer program code, documentation, and technical specifications

#### Files to Include in ZIP

- All `.sh` shell scripts
- All `.md` documentation files
- All Python scripts (`.py`)
- LICENSE file
- Hash timestamp file

### Copyright Registration Process

1. Visit https://copyright.gov
2. Click "Register a Group"
3. Select "Group of Published Works"
4. Fill in the following:
   - **Title of Work**: sha256sol 2025 Projects v1 - quantum-taproot-wallet
   - **Author**: sha256sol
   - **Year of Completion**: 2025
   - **Date of First Publication**: December 2025
   - **Nation of First Publication**: United States
5. Upload ZIP file containing all project files
6. Pay $45 registration fee
7. Submit application

## Provisional Patent Application

### USPTO Provisional Patent

**Cost**: $150 per application  
**Target File Date**: January 2, 2026 (adjust as needed)  
**Keep Private**: Yes (do not publish)

**⚠️ CONFIDENTIALITY WARNING**: The PROVISIONAL_PATENT.md file in this repository is a TEMPLATE. For maximum patent protection, consider keeping your final patent application with specific technical claims in a private document until after filing. Public disclosure of novel claims before filing can compromise patent rights, especially in foreign countries.

#### Patent Title

"Quantum-Resistant Taproot Wallet with Time-Locked Recovery Mechanism"

#### Technical Summary

A Bitcoin wallet implementation utilizing Taproot's script tree structure to provide quantum-resistant security through key-path spending while maintaining time-locked recovery options.

##### Key Innovations

1. **Quantum-Resistant Architecture**
   - Uses NUMS (Nothing Up My Sleeve) internal key to prevent key-path exploitation
   - Hides multi-key structure through key-path spending
   - Minimizes quantum attack surface by not revealing script tree

2. **Time-Locked Recovery System**
   - Implements 1008-block (~1 week) timelock for recovery path
   - Supports HOT, COLD, and RECOVERY spending paths
   - Enables secure fund recovery without exposing hot/cold keys

3. **Taproot Script Tree Structure**
   ```
   Internal Key: NUMS point (unspendable)
   Script Tree:
     ├── HOT key → spend anytime (daily use)
     ├── COLD key → spend anytime (secure storage)
     └── RECOVERY → spend after timelock (~1 week)
   ```

##### Technical Claims

1. A method for creating quantum-resistant Bitcoin addresses using Taproot with NUMS internal keys
2. A system for implementing time-locked recovery in Taproot script trees
3. A wallet architecture that preserves privacy through key-path spending while maintaining recovery options
4. A multi-network testing framework for Bitcoin wallet validation across REGTEST, SIGNET, and TESTNET4

##### Diagrams Required

- System architecture diagram (from README.md security model)
- Script tree structure diagram
- Transaction flow diagram
- Recovery mechanism flowchart

##### Prior Art

- BIP 341 (Taproot)
- BIP 342 (Tapscript)
- Bitcoin Core reference implementation
- BDK (Bitcoin Development Kit)

### Provisional Patent Filing Instructions

1. Visit https://www.uspto.gov/patents/apply
2. Select "File a Provisional Application"
3. Complete USPTO Form SB/16
4. Include:
   - Cover sheet with title and inventor information
   - Detailed description (use this document)
   - Diagrams (create from README security model)
   - Claims (technical claims listed above)
5. Pay $150 filing fee (micro entity)
6. Receive filing receipt and 12-month provisional period

## Trademark Application

### USPTO TEAS Plus Application

**Mark**: "sha256sol"  
**Cost**: $250  
**Timeline**: 30 minutes

#### Trademark Details

- **Mark Type**: Standard Character Mark
- **Literal Element**: sha256sol
- **Goods/Services**: Computer software, cryptocurrency wallet software
- **Class**: 009 (Computer software)
- **First Use in Commerce**: December 2025
- **Description of Goods**: Cryptocurrency wallet software; Bitcoin wallet software; Quantum-resistant cryptographic software

#### Filing Instructions

1. Visit https://www.uspto.gov/trademarks/apply
2. Select "TEAS Plus" application
3. Fill in the following:
   - **Mark**: sha256sol
   - **Owner Name**: [Your name/entity]
   - **Owner Address**: [Your address]
   - **Class**: 009
   - **Goods/Services Description**: "Computer software for cryptocurrency wallets; Bitcoin wallet software featuring quantum-resistant security"
   - **Basis for Filing**: Use in Commerce
   - **Date of First Use Anywhere**: December 2025
   - **Date of First Use in Commerce**: December 2025
4. Upload specimen of use (screenshot of software with mark)
5. Pay $250 filing fee
6. Submit application

## Timeline

| Task | Date | Cost | Status |
|------|------|------|--------|
| **IP Timestamp** | Dec 31, 2025 | Free | ✅ Complete |
| **Copyright Registration** | Dec 31, 2025 | $45 | 📋 Ready to file |
| **Provisional Patent** | Jan 2, 2026 | $150 | 📋 Documentation ready |
| **Trademark Application** | Jan 2026 | $250 | 📋 Documentation ready |

## Important Notes

1. **Keep provisional patent applications PRIVATE** - Do not publish until non-provisional is filed
2. **Hash file serves as timestamp** - Commit to repository for proof of creation date
3. **Copyright registration covers published works** - Can file immediately
4. **Trademark requires use in commerce** - Must have actual use before filing
5. **Provisional patent gives 12 months** - Must file non-provisional within 1 year

## Contact Information

For questions or updates, see the main project repository:
https://github.com/Moonbags/-quantum-taproot-wallet-
