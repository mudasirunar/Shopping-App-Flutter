const { initFirebaseAdmin } = require('../lib/firebaseAdmin');
const { sendEmail } = require('../lib/brevoClient');
const { validateAppToken, OTP_COOLDOWN_MS } = require('../lib/security');
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
  const { email } = body || {};
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

    // 2. Anti-Spam Rate Limiting: 60-second cooldown per email
    const now = Date.now();
    let existingRecord = null;

    if (admin.apps.length > 0) {
      try {
        const db = admin.firestore();
        const doc = await db.collection('_auth_resets').doc(trimmedEmail).get();
        if (doc.exists) {
          existingRecord = doc.data();
        }
      } catch (e) {
        console.warn('[send-reset-otp] Check rate limit warning:', e.message);
      }
    } else {
      existingRecord = memoryOtpStore.get(trimmedEmail);
    }

    if (existingRecord && existingRecord.lastRequestedAt) {
      const lastRequested = existingRecord.lastRequestedAt.toMillis
        ? existingRecord.lastRequestedAt.toMillis()
        : existingRecord.lastRequestedAt;
      const diff = now - lastRequested;
      if (diff < OTP_COOLDOWN_MS) {
        const waitSec = Math.ceil((OTP_COOLDOWN_MS - diff) / 1000);
        return res.status(429).json({
          error: `Please wait ${waitSec} seconds before requesting a new code.`,
        });
      }
    }

    // 3. Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = now + 10 * 60 * 1000; // 10 minutes

    // Store in Firestore if available, otherwise memory
    let savedToFirestore = false;
    if (admin.apps.length > 0) {
      try {
        const db = admin.firestore();
        await db.collection('_auth_resets').doc(trimmedEmail).set({
          otp,
          attempts: 0,
          expiresAt: admin.firestore.Timestamp.fromMillis(expiresAt),
          lastRequestedAt: admin.firestore.Timestamp.fromMillis(now),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          uid: userRecord ? userRecord.uid : null,
        });
        savedToFirestore = true;
      } catch (dbError) {
        console.warn('[send-reset-otp] Firestore write warning:', dbError.message);
      }
    }

    if (!savedToFirestore) {
      memoryOtpStore.set(trimmedEmail, {
        otp,
        attempts: 0,
        expiresAt,
        lastRequestedAt: now,
      });
    }

    // 4. Send email via Brevo
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
          Shopping App • Secure Account Recovery
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
