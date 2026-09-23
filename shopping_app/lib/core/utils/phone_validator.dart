/// Validation utility for Pakistani phone numbers (mobile, landline, and international).
class PhoneValidator {
  PhoneValidator._();

  /// Validates a phone number input string.
  /// Accepts:
  /// - Mobile: `03XXXXXXXXX` (11 digits), `+923XXXXXXXXX` / `923XXXXXXXXX` (12 digits), or `3XXXXXXXXX` (10 digits)
  /// - Landline: `021XXXXXXXX`, `042XXXXXXXX`, `051XXXXXXX`, etc. (10-11 digits), or with `+92` (11-12 digits)
  /// Returns `null` if valid, or a descriptive user-facing error message if invalid.
  static String? validate(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Please enter phone number';
    }

    final trimmed = input.trim();

    // Check for allowed characters: optional leading +, digits, spaces, dashes, brackets
    if (!RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(trimmed)) {
      return 'Phone number can only contain digits, +, and hyphens';
    }

    var digits = trimmed.replaceAll(RegExp(r'\D'), '');

    // Normalize international prefix 0092 -> 92
    if (digits.startsWith('0092')) {
      digits = digits.substring(2);
    }

    // International Pakistani format (+92... or 92...)
    if (digits.startsWith('92')) {
      final local = digits.substring(2);
      if (local.startsWith('3')) {
        if (local.length < 10) return 'Mobile number is incomplete';
        if (local.length > 10) return 'Mobile number has too many digits';
        return null;
      }
      if (local.length < 9) return 'Landline number is incomplete';
      if (local.length > 10) return 'Landline number has too many digits';
      return null;
    }

    // Local Pakistani format starting with 0
    if (digits.startsWith('0')) {
      if (digits.startsWith('03')) {
        if (digits.length < 11) return 'Mobile number must be 11 digits (e.g. 03001234567)';
        if (digits.length > 11) return 'Mobile number cannot exceed 11 digits';
        return null;
      }
      // Landline codes (02X, 04X, 05X, 06X, 07X, 08X, 09X)
      if (RegExp(r'^0[2-9]').hasMatch(digits)) {
        if (digits.length < 10) return 'Landline number is incomplete';
        if (digits.length > 11) return 'Landline number has too many digits';
        return null;
      }
      return 'Invalid area code or mobile prefix';
    }

    // User omitted leading 0 on mobile (e.g. 3001234567 - 10 digits)
    if (digits.startsWith('3')) {
      if (digits.length < 10) return 'Mobile number is incomplete';
      if (digits.length > 10) return 'Mobile number has too many digits';
      return null;
    }

    // Fallback for general landlines without leading 0
    if (digits.length >= 9 && digits.length <= 10) {
      return null;
    }

    return 'Please enter a valid mobile or landline number';
  }

  /// Convenience boolean check. Returns `true` only when the phone number is fully valid.
  static bool isValid(String? input) {
    if (input == null || input.trim().isEmpty) return false;
    final trimmed = input.trim();
    if (!RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(trimmed)) return false;

    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0092')) {
      digits = digits.substring(2);
    }

    // International +92 / 92
    if (digits.startsWith('92')) {
      final local = digits.substring(2);
      if (local.startsWith('3')) return local.length == 10;
      return local.length >= 9 && local.length <= 10;
    }

    // Local 0...
    if (digits.startsWith('0')) {
      if (digits.startsWith('03')) return digits.length == 11;
      if (RegExp(r'^0[2-9]').hasMatch(digits)) {
        return digits.length >= 10 && digits.length <= 11;
      }
      return false;
    }

    // Omitted 0 mobile: 3XXXXXXXXX
    if (digits.startsWith('3')) return digits.length == 10;

    return false;
  }

  /// Alias for phone validation supporting mobile & landline prefixes.
  static bool isValidPakistanMobile(String? input) => isValid(input);

  /// Formats raw digits into a readable format when possible.
  static String formatForDisplay(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11 && clean.startsWith('03')) {
      return '${clean.substring(0, 4)}-${clean.substring(4)}';
    }
    if (clean.length == 12 && clean.startsWith('923')) {
      return '+92 ${clean.substring(2, 5)}-${clean.substring(5)}';
    }
    return phone;
  }
}
