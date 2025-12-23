# Security Policy

## Overview

This project implements quantum-resistant cryptographic primitives for Bitcoin Taproot wallets. This document outlines security considerations, threat models, and responsible disclosure practices.

## ⚠️ Status: Reference Implementation

**This is a reference/educational implementation and should NOT be used with real funds without:**

1. Professional security audit
2. Integration of NIST-standardized post-quantum algorithms
3. Extensive testing on testnet/signet
4. Hardware security module integration for key management
5. Independent code review

## Threat Model

### Protected Against

✅ **Quantum Computer Attacks (Shor's Algorithm)**
- ECDSA/Schnorr signatures vulnerable to polynomial-time breaking
- Our hash-based signatures (W-OTS) are quantum-resistant
- Merkle tree commitments hide public keys until spend time

✅ **Long-Term Storage Attacks**
- Coins stored for years may face future quantum threats
- Vault structure protects keys via hash commitments
- SHA-256 provides ~128-bit quantum security (Grover's algorithm)

✅ **Key Reuse Attacks**
- Winternitz OTS keys are ONE-TIME use only
- Automatic tracking prevents accidental reuse
- Reuse would completely break signature security

### NOT Protected Against

❌ **Private Key Compromise**
- If attacker obtains private keys, quantum resistance is irrelevant
- Quantum computers provide no advantage for stealing stored keys
- **Mitigation**: Encrypt private keys, use HSMs, secure backup

❌ **Implementation Vulnerabilities**
- This code is NOT audited for production use
- May contain bugs, side-channel vulnerabilities, or logic errors
- **Mitigation**: Professional audit required before real funds

❌ **Social Engineering / Phishing**
- Quantum resistance doesn't protect against user errors
- Attacker tricking user into revealing keys or signing transactions
- **Mitigation**: User education, multi-signature schemes

❌ **Malware / Supply Chain Attacks**
- Compromised dependencies or build environment
- Keyloggers, screen capture, memory dumps
- **Mitigation**: Verify dependencies, use isolated signing environments

## Cryptographic Details

### Hash Function Security

We use **SHA-256** which provides:
- **Classical security**: 2^256 operations to break (infeasible)
- **Quantum security**: 2^128 operations via Grover's algorithm (still infeasible)

This is considered adequate for long-term security even against quantum computers.

### Signature Scheme: Winternitz OTS

**Properties:**
- Hash-based one-time signature
- Security based on SHA-256 preimage resistance
- Quantum-resistant (no known quantum speedup for hash preimages)

**Critical Limitation:**
- ⚠️ **Each key pair can sign ONLY ONE message**
- ⚠️ **Reusing a key completely breaks security**
- ⚠️ **Never use the same key for multiple signatures**

Our implementation tracks used keys to prevent accidental reuse.

### Merkle Tree Commitments

**Purpose:**
- Commit to 256 public keys via single Merkle root
- Reveal only specific key + proof when spending (~256-512 bytes)
- Provides privacy (unrevealed keys remain hidden)

**Security:**
- Relies on SHA-256 collision resistance
- Quantum computers provide no significant advantage against hash functions
- Proof verification is efficient and deterministic

## Known Limitations

### 1. Not Production-Ready

This is a **reference implementation** for educational purposes:
- No formal security analysis
- No peer review or audit
- Not integration tested with Bitcoin Core
- Simplified W-OTS (real systems should use XMSS or SPHINCS+)

### 2. Standardization Gap

For production, use **NIST-standardized** post-quantum algorithms:
- **ML-DSA (Dilithium)** - lattice-based signatures
- **XMSS/LMS** - stateful hash-based signatures
- **SPHINCS+** - stateless hash-based signatures

Our W-OTS is conceptually sound but simplified.

### 3. Bitcoin Protocol Limitations

Current Bitcoin doesn't have native support for:
- Merkle proof verification in script
- Post-quantum signature verification
- Large script witnesses (proofs are ~1.5KB)

Real deployment requires:
- Soft fork for new opcodes, OR
- Optimistic verification via covenant emulation, OR
- Layer 2 solutions (Lightning, sidechains)

### 4. Key Management Complexity

- 256 one-time keys per vault
- Must track which keys are used
- After exhaustion, must create new vault and migrate funds
- Private key backup is critical (encrypted!)

### 5. Transaction Size & Fees

Quantum-secure spends are larger:
- Merkle proof: ~256-512 bytes (depth 8 for 256 leaves)
- W-OTS signature: ~1-2KB (depends on parameters)
- Total overhead: ~1.5-2.5KB vs ~64 bytes for Schnorr

Higher transaction fees are required.

## Quantum Computing Timeline

**Current Estimates:**
- **2025-2030**: Research phase, small-scale quantum computers
- **2030-2035**: Potential for cryptographically relevant quantum computers
- **2035+**: Widespread quantum threat to current cryptography

**Recommendation:**
- Start migrating high-value, long-term storage NOW
- Monitor NIST PQ standardization (ongoing)
- Plan migration strategy for existing Bitcoin holdings

## Responsible Disclosure

If you discover a security vulnerability:

### DO:
1. **Email privately** to the maintainer (see GitHub profile)
2. Provide detailed description of vulnerability
3. Include proof-of-concept if possible
4. Allow reasonable time for fix before public disclosure

### DO NOT:
1. Open public GitHub issues for security bugs
2. Disclose vulnerability publicly before fix
3. Exploit vulnerability against real funds

### Timeline:
- We aim to respond within **48 hours**
- Fixes for critical issues: **7 days**
- Public disclosure after fix is deployed

## Security Checklist for Users

Before using this code:

- [ ] Read and understand all security warnings
- [ ] Test on testnet/signet only (never mainnet)
- [ ] Verify dependencies with `npm audit`
- [ ] Use hardware security module for key storage
- [ ] Encrypt all private key backups
- [ ] Never reuse one-time signature keys
- [ ] Monitor remaining key count in vault
- [ ] Have migration plan for vault exhaustion
- [ ] Keep abreast of quantum computing developments
- [ ] Plan to upgrade to NIST-standardized PQ algorithms

## Additional Resources

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/Projects/post-quantum-cryptography)
- [Quantumroot Proposal](https://blog.bitjson.com/quantumroot/)
- [Bitcoin Quantum Vulnerability](https://www.youtube.com/watch?v=l9xC81Z0UDQ)
- [Hash-Based Signatures](https://en.wikipedia.org/wiki/Hash-based_cryptography)

## License

This security policy is released under the same MIT license as the project.

---

**Last Updated**: December 2025
