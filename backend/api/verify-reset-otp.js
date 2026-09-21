const { initFirebaseAdmin } = require('../lib/firebaseAdmin');
const { validateAppToken, MAX_VERIFY_ATTEMPTS } = require('../lib/security');
const sendResetOtp = require('./send-reset-otp');
require('dotenv').config();

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization, x-app-security-token'
  );

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  // 1. Validate App Security Handshake Token
  const tokenCheck = validateAppToken(req);
  if (!tokenCheck.valid) {
    return res.status(401).json({ error: tokenCheck.error });
  }

  let body = req.body;
  if (typeof body === 'string') {
    try { body = JSON.parse(body); } catch (e) {}
  }
  const { email, otp, newPassword } = body || {};

  if (!email || !otp || !newPassword) {
    return res.status(400).json({ error: 'Email, OTP, and newPassword are required fields.' });
  }

  if (newPassword.length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters long.' });
  }

  const trimmedEmail = email.trim().toLowerCase();
  const trimmedOtp = otp.trim();

  try {
    const admin = initFirebaseAdmin();

    if (admin.apps.length > 0) {
      try {
        const db = admin.firestore();
        const docRef = db.collection('_auth_resets').doc(trimmedEmail);
        const doc = await docRef.get();

        if (!doc.exists) {
          return res.status(400).json({ error: 'No active OTP request found for this email.' });
        }

        const storedOtpData = doc.data();
        const attempts = (storedOtpData.attempts || 0) + 1;

        // Check if brute force limit exceeded
        if (attempts > MAX_VERIFY_ATTEMPTS) {
          await docRef.delete();
          return res.status(429).json({
            error: 'Too many incorrect attempts. This code has been invalidated. Please request a new one.',
          });
        }

        // Check expiry
        const expiryMillis = storedOtpData.expiresAt.toMillis
          ? storedOtpData.expiresAt.toMillis()
          : storedOtpData.expiresAt;
        if (Date.now() > expiryMillis) {
          await docRef.delete();
          return res.status(400).json({ error: 'Verification code has expired. Please request a new one.' });
        }

        // Verify OTP code
        if (storedOtpData.otp !== trimmedOtp) {
          await docRef.update({ attempts });
          const remaining = MAX_VERIFY_ATTEMPTS - attempts;
          return res.status(400).json({
            error: `Invalid verification code. ${remaining} attempt(s) remaining.`,
          });
        }

        // Update password in Firebase Auth
        const userRecord = await admin.auth().getUserByEmail(trimmedEmail);
        await admin.auth().updateUser(userRecord.uid, { password: newPassword });

        // Clean up OTP on success
        await docRef.delete();

        return res.status(200).json({
          success: true,
          message: 'Password successfully updated. You can now log in with your new password.',
        });
      } catch (dbError) {
        console.warn('[verify-reset-otp] Firestore lookup error:', dbError.message);
      }
    }

    // Fallback to memory store if Firestore is unavailable
    const memoryOtp = sendResetOtp._memoryOtpStore?.get(trimmedEmail);
    if (!memoryOtp) {
      return res.status(400).json({ error: 'No active OTP request found for this email.' });
    }

    memoryOtp.attempts = (memoryOtp.attempts || 0) + 1;
    if (memoryOtp.attempts > MAX_VERIFY_ATTEMPTS) {
      sendResetOtp._memoryOtpStore.delete(trimmedEmail);
      return res.status(429).json({
        error: 'Too many incorrect attempts. This code has been invalidated. Please request a new one.',
      });
    }

    if (Date.now() > memoryOtp.expiresAt) {
      sendResetOtp._memoryOtpStore.delete(trimmedEmail);
      return res.status(400).json({ error: 'Verification code has expired. Please request a new one.' });
    }

    if (memoryOtp.otp !== trimmedOtp) {
      const remaining = MAX_VERIFY_ATTEMPTS - memoryOtp.attempts;
      return res.status(400).json({
        error: `Invalid verification code. ${remaining} attempt(s) remaining.`,
      });
    }

    if (admin.apps.length > 0) {
      const userRecord = await admin.auth().getUserByEmail(trimmedEmail);
      await admin.auth().updateUser(userRecord.uid, { password: newPassword });
    }

    sendResetOtp._memoryOtpStore.delete(trimmedEmail);

    return res.status(200).json({
      success: true,
      message: 'Password successfully updated. You can now log in with your new password.',
    });
  } catch (error) {
    console.error('[verify-reset-otp] Internal Error:', error);
    return res.status(500).json({ error: error.message || 'Internal server error' });
  }
};
