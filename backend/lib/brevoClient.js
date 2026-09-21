const Brevo = require('@getbrevo/brevo');

async function sendEmail({ toEmail, toName, subject, htmlContent }) {
  const apiKey = process.env.BREVO_API_KEY;
  const senderEmail = process.env.SENDER_EMAIL || 'no-reply@shoppingapp.demo';
  const senderName = process.env.SENDER_NAME || 'Shopping App';

  if (!apiKey || apiKey.includes('your_brevo_api_key_here')) {
    console.log(`[Brevo Simulation] Email to ${toEmail} with subject "${subject}"`);
    console.log(`[Brevo Simulation Content]:\n${htmlContent}`);
    return { success: true, simulated: true };
  }

  const apiInstance = new Brevo.TransactionalEmailsApi();
  apiInstance.setApiKey(Brevo.TransactionalEmailsApiApiKeys.apiKey, apiKey);

  const sendSmtpEmail = new Brevo.SendSmtpEmail();
  sendSmtpEmail.subject = subject;
  sendSmtpEmail.htmlContent = htmlContent;
  sendSmtpEmail.sender = { name: senderName, email: senderEmail };
  sendSmtpEmail.to = [{ email: toEmail, name: toName || toEmail }];

  const response = await apiInstance.sendTransacEmail(sendSmtpEmail);
  return { success: true, messageId: response.body?.messageId };
}

module.exports = { sendEmail };
