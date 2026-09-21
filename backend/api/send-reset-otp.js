const { initFirebaseAdmin } = require('../lib/firebaseAdmin');
const { sendEmail } = require('../lib/brevoClient');
require('dotenv').config();

// In-memory fallback if Firestore isn't connected yet during local verification
const memoryOtpStore = new Map();

module.exports = async (req, res) => {
  // CORS
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

  const { email } = req.body || {};
  if (!email || !email.includes('@')) {
    return res.status(400).json({ error: 'A valid email address is required.' });
  }

  const trimmedEmail = email.trim().toLowerCase();

  try {
    const admin = initFirebaseAdmin();
    let userRecord = null;

    if (admin.apps.length > 0) {
      try {
        userRecord = await admin.auth().getUserByEmail(trimmedEmail);
      } catch (authError) {
        if (authError.code === 'auth/user-not-found') {
          return res.status(404).json({ error: 'No account found with this email address.' });
        }
        console.warn('[send-reset-otp] Auth check warning:', authError.message);
      }
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes

    // Store in Firestore if available, otherwise memory
    let savedToFirestore = false;
    if (admin.apps.length > 0) {
      try {
        const db = admin.firestore();
        await db.collection('_auth_resets').doc(trimmedEmail).set({
          otp,
          expiresAt: admin.firestore.Timestamp.fromMillis(expiresAt),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          uid: userRecord ? userRecord.uid : null,
        });
        savedToFirestore = true;
      } catch (dbError) {
        console.warn('[send-reset-otp] Firestore write warning:', dbError.message);
      }
    }

    if (!savedToFirestore) {
      memoryOtpStore.set(trimmedEmail, { otp, expiresAt });
    }

    // Send email via Brevo
    const emailSubject = 'Your Shopping App Password Reset Code';
    const emailHtml = `
      <div style="font-family: Arial, sans-serif; max-width: 540px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 8px;">
        <h2 style="color: #0f172a; margin-top: 0;">Password Reset Request</h2>
        <p style="color: #475569; font-size: 15px; line-height: 1.5;">
          We received a request to reset your password for your <strong>Shopping App</strong> account.
        </p>
        <div style="margin: 24px 0; text-align: center;">
          <span style="display: inline-block; font-size: 32px; font-weight: bold; letter-spacing: 6px; padding: 12px 24px; background-color: #f1f5f9; color: #0f172a; border-radius: 6px;">
            ${otp}
          </span>
        </div>
        <p style="color: #64748b; font-size: 13px;">
          This code is valid for 10 minutes. If you did not request a password reset, please ignore this email.
        </p>
        <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 24px 0;" />
        <p style="color: #94a3b8; font-size: 12px; margin: 0;">
          Shopping App • Anas Technologies Flutter Internship Task 04
        </p>
      </div>
    `;

    await sendEmail({
      toEmail: trimmedEmail,
      subject: emailSubject,
      htmlContent: emailHtml,
    });

    return res.status(200).json({
      success: true,
      message: 'Password reset OTP dispatched to your email.',
    });
  } catch (error) {
    console.error('[send-reset-otp] Internal Error:', error);
    return res.status(500).json({ error: error.message || 'Internal server error' });
  }
};

module.exports._memoryOtpStore = memoryOtpStore;
