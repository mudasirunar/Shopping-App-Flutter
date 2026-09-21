const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let initialized = false;

function initFirebaseAdmin() {
  if (initialized || admin.apps.length > 0) {
    return admin;
  }

  let credential;

  if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
    const decoded = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf8');
    const serviceAccount = JSON.parse(decoded);
    credential = admin.credential.cert(serviceAccount);
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    const resolvedPath = path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
    if (fs.existsSync(resolvedPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(resolvedPath, 'utf8'));
      credential = admin.credential.cert(serviceAccount);
    }
  }

  if (!credential) {
    try {
      credential = admin.credential.applicationDefault();
    } catch (e) {
      console.warn('[FirebaseAdmin] Warning: No service account configured yet. Running in uncredentialed state.');
    }
  }

  if (credential) {
    admin.initializeApp({ credential });
    initialized = true;
  }

  return admin;
}

module.exports = { initFirebaseAdmin, admin };
