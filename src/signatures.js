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

function deriveSigningKey(secretKey, label) {
  if (!secretKey || typeof secretKey !== 'string' || !secretKey.trim()) {
    throw new Error('Invalid secretKey for signing key derivation');
  }
  const salt = Buffer.from(label || 'pq');
  return crypto.hkdfSync('sha256', Buffer.from(String(secretKey)), salt, Buffer.from('signing-key'), 32);
}

function generateKeypair(label) {
  const secretKey = crypto.randomBytes(32).toString('hex');
  return { publicKey: derivePublicKey(secretKey, label), secretKey };
}

function signMessage(message, secretKey, label) {
  const msg = Buffer.isBuffer(message) ? message : Buffer.from(String(message));
  const signingKey = deriveSigningKey(secretKey, label);
  const mac = crypto.createHmac('sha512', signingKey).update(msg).digest('base64');
  const pub = derivePublicKey(secretKey, label);
  return `${label}:${pub}:${mac}`;
}

function verifyMessage(message, signature, secretKey, label, expectedPublicKey) {
  if (!signature || typeof signature !== 'string') return false;
  const [sigLabel, sigPub, sigPayload] = signature.split(':');
  if (sigLabel !== label || !sigPayload) return false;
  const derivedPub = expectedPublicKey || derivePublicKey(secretKey, label);
  if (sigPub && derivedPub && sigPub !== derivedPub) return false;
  const msg = Buffer.isBuffer(message) ? message : Buffer.from(String(message));
  const signingKey = deriveSigningKey(secretKey, label);
  const expected = crypto.createHmac('sha512', signingKey).update(msg).digest('base64');
  return expected === sigPayload;
}

function generateMlDsaKeypair() {
  return generateKeypair('ml-dsa');
}

function signMlDsa(message, secretKey) {
  return signMessage(message, secretKey, 'ml-dsa');
}

function verifyMlDsa(message, signature, secretKey) {
  return verifyMessage(message, signature, secretKey, 'ml-dsa');
}

function generateFalconKeypair() {
  return generateKeypair('falcon');
}

function signFalcon(message, secretKey) {
  return signMessage(message, secretKey, 'falcon');
}

function verifyFalcon(message, signature, secretKey) {
  return verifyMessage(message, signature, secretKey, 'falcon');
}

function selftest() {
  const ml = generateMlDsaKeypair();
  const sigMl = signMlDsa('hello', ml.secretKey);
  const okMl = verifyMlDsa('hello', sigMl, ml.secretKey);

  const falcon = generateFalconKeypair();
  const sigFa = signFalcon('world', falcon.secretKey);
  const okFa = verifyFalcon('world', sigFa, falcon.secretKey);
  return okMl && okFa;
}

if (require.main === module) {
  const result = selftest();
  console.log(result ? 'PQ signature stubs OK' : 'PQ signature stubs failed');
}

module.exports = {
  derivePublicKey,
  deriveSigningKey,
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
