const { initFirebaseAdmin } = require('../lib/firebaseAdmin');
const sendResetOtp = require('./send-reset-otp');
require('dotenv').config();

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization'
  );

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  const { email, otp, newPassword } = req.body || {};

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
    let storedOtpData = null;

    if (admin.apps.length > 0) {
      try {
        const db = admin.firestore();
        const docRef = db.collection('_auth_resets').doc(trimmedEmail);
        const doc = await docRef.get();
        if (doc.exists) {
          storedOtpData = doc.data();
          // Verify
          if (storedOtpData.otp !== trimmedOtp) {
            return res.status(400).json({ error: 'Invalid verification code.' });
          }
          const expiryMillis = storedOtpData.expiresAt.toMillis ? storedOtpData.expiresAt.toMillis() : storedOtpData.expiresAt;
          if (Date.now() > expiryMillis) {
            return res.status(400).json({ error: 'Verification code has expired. Please request a new one.' });
          }

          // Update password in Firebase Auth
          const userRecord = await admin.auth().getUserByEmail(trimmedEmail);
          await admin.auth().updateUser(userRecord.uid, { password: newPassword });

          // Clean up OTP
          await docRef.delete();

          return res.status(200).json({
            success: true,
            message: 'Password successfully updated. You can now log in with your new password.',
          });
        }
      } catch (dbError) {
        console.warn('[verify-reset-otp] Firestore lookup error:', dbError.message);
      }
    }

    // Fallback to memory store if Firestore was not available
    const memoryOtp = sendResetOtp._memoryOtpStore?.get(trimmedEmail);
    if (!memoryOtp) {
      return res.status(400).json({ error: 'No active OTP request found for this email.' });
    }

    if (memoryOtp.otp !== trimmedOtp) {
      return res.status(400).json({ error: 'Invalid verification code.' });
    }

    if (Date.now() > memoryOtp.expiresAt) {
      sendResetOtp._memoryOtpStore.delete(trimmedEmail);
      return res.status(400).json({ error: 'Verification code has expired. Please request a new one.' });
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
