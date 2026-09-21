/**
 * Backend Security & Anti-Bot Protection Layer
 */

function validateAppToken(req) {
  const expectedToken = process.env.APP_SECURITY_TOKEN;
  if (!expectedToken) {
    // If not configured in environment, allow for backward compatibility during setup
    return { valid: true };
  }

  const incomingToken =
    req.headers['x-app-security-token'] ||
    (req.headers['authorization'] && req.headers['authorization'].startsWith('Bearer ')
      ? req.headers['authorization'].slice(7).trim()
      : null);

  if (!incomingToken || incomingToken !== expectedToken) {
    return {
      valid: false,
      error: 'Unauthorized: Missing or invalid application security token.',
    };
  }

  return { valid: true };
}

const OTP_COOLDOWN_MS = 60 * 1000; // 60 seconds
const MAX_VERIFY_ATTEMPTS = 5;

module.exports = {
  validateAppToken,
  OTP_COOLDOWN_MS,
  MAX_VERIFY_ATTEMPTS,
};
