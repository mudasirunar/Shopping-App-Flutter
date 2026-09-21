/// Validation utility for Pakistani mobile numbers.
/// Required format: Local 11-digit number beginning with 03 (e.g. 03001234567).
class PhoneValidator {
  PhoneValidator._();

  /// Regex enforcing exactly 11 digits starting with '03'.
  static final RegExp pakistaniPhoneRegex = RegExp(r'^03\d{9}$');

  /// Validates a phone number input string.
  /// Returns `null` if valid, or a descriptive user-facing error message if invalid.
  static String? validate(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Please enter your mobile number';
    }

    final trimmed = input.trim();

    // Check for non-digit characters
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Mobile number must contain digits only';
    }

    // Check prefix
    if (!trimmed.startsWith('03')) {
      return 'Number must start with 03 (e.g., 03001234567)';
    }

    // Check exact length
    if (trimmed.length != 11) {
      return 'Number must be exactly 11 digits (e.g., 03001234567)';
    }

    if (!pakistaniPhoneRegex.hasMatch(trimmed)) {
      return 'Invalid Pakistani mobile number format';
    }

    return null;
  }

  /// Convenience boolean check.
  static bool isValid(String? input) {
    return validate(input) == null;
  }

  /// Formats raw digits into a readable format: `0300-1234567`.
  static String formatForDisplay(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 4)}-${clean.substring(4)}';
    }
    return phone;
  }
}
