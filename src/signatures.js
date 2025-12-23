#!/usr/bin/env node
/**
 * Lightweight placeholders for post-quantum signature flows (ML-DSA/Falcon).
 * These are NOT production-ready cryptography; they provide deterministic,
 * test-friendly signing/verification semantics without external deps.
 */
const crypto = require('crypto');

function derivePublicKey(secretKey, label) {
  return crypto.createHash('sha256').update(`${label}:${secretKey}`).digest('hex');
}

function generateKeypair(label) {
  const secretKey = crypto.randomBytes(32).toString('hex');
  return { publicKey: derivePublicKey(secretKey, label), secretKey };
}

function signMessage(message, publicKey, label) {
  const msg = Buffer.isBuffer(message) ? message : Buffer.from(String(message));
  const signature = crypto.createHmac('sha512', publicKey).update(msg).digest('base64');
  return `${label}:${signature}`;
}

function verifyMessage(message, signature, publicKey, label) {
  if (!signature || typeof signature !== 'string') return false;
  const [sigLabel, sigPayload] = signature.split(':');
  if (sigLabel !== label || !sigPayload) return false;
  const expected = signMessage(message, publicKey, label);
  return expected === signature;
}

function generateMlDsaKeypair() {
  return generateKeypair('ml-dsa');
}

function signMlDsa(message, publicKey) {
  return signMessage(message, publicKey, 'ml-dsa');
}

function verifyMlDsa(message, signature, publicKey) {
  return verifyMessage(message, signature, publicKey, 'ml-dsa');
}

function generateFalconKeypair() {
  return generateKeypair('falcon');
}

function signFalcon(message, publicKey) {
  return signMessage(message, publicKey, 'falcon');
}

function verifyFalcon(message, signature, publicKey) {
  return verifyMessage(message, signature, publicKey, 'falcon');
}

function selftest() {
  const ml = generateMlDsaKeypair();
  const sigMl = signMlDsa('hello', ml.publicKey);
  const okMl = verifyMlDsa('hello', sigMl, ml.publicKey);

  const falcon = generateFalconKeypair();
  const sigFa = signFalcon('world', falcon.publicKey);
  const okFa = verifyFalcon('world', sigFa, falcon.publicKey);
  return okMl && okFa;
}

if (require.main === module) {
  const result = selftest();
  console.log(result ? 'PQ signature stubs OK' : 'PQ signature stubs failed');
}

module.exports = {
  derivePublicKey,
  generateKeypair,
  signMessage,
  verifyMessage,
  generateMlDsaKeypair,
  signMlDsa,
  verifyMlDsa,
  generateFalconKeypair,
  signFalcon,
  verifyFalcon,
  selftest,
};
