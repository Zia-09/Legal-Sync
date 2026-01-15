/// 🔹 Validation Helper - Email, phone, field validation
class ValidationHelper {
  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number (Pakistan format)
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;

    // Pakistan phone formats:
    // 03XX-XXXXXXX, +92-3XX-XXXXXXX, 92XXXXXXXXXXXX
    final phoneRegex = RegExp(r'^(?:\+92|0)?3\d{2}[-]?\d{7}$|^92\d{10}$');
    return phoneRegex.hasMatch(phone.replaceAll('-', ''));
  }

  /// Validate password strength
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;

    // Check for uppercase, lowercase, number, and special char
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasNumber && hasSpecialChar;
  }

  /// Validate password strength (simple - at least 8 chars with number)
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    return password.contains(RegExp(r'[0-9]'));
  }

  /// Check if field is empty
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Validate name (non-empty, min 2 chars)
  static bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.contains('http://') || url.contains('https://');
    } catch (_) {
      return false;
    }
  }

  /// Validate amount (positive number)
  static bool isValidAmount(String amount) {
    try {
      final value = double.parse(amount);
      return value > 0;
    } catch (_) {
      return false;
    }
  }

  /// Get password strength indicator
  static String getPasswordStrength(String password) {
    if (password.isEmpty) return 'No password';
    if (password.length < 6) return 'Weak';
    if (password.length < 10) return 'Fair';
    if (isStrongPassword(password)) return 'Strong';
    return 'Fair';
  }

  /// Validate form - check multiple fields
  static bool validateForm(Map<String, String?> fields) {
    for (var value in fields.values) {
      if (isEmpty(value)) return false;
    }
    return true;
  }

  /// Get validation error message
  static String? getEmailError(String? email) {
    if (isEmpty(email)) return 'Email is required';
    if (!isValidEmail(email!)) return 'Invalid email format';
    return null;
  }

  static String? getPhoneError(String? phone) {
    if (isEmpty(phone)) return 'Phone is required';
    if (!isValidPhone(phone!)) return 'Invalid phone number';
    return null;
  }

  static String? getPasswordError(String? password) {
    if (isEmpty(password)) return 'Password is required';
    if (!isValidPassword(password!)) {
      return 'Password must be at least 8 characters with numbers';
    }
    return null;
  }

  static String? getNameError(String? name) {
    if (isEmpty(name)) return 'Name is required';
    if (!isValidName(name!)) return 'Name must be at least 2 characters';
    return null;
  }

  /// Check for common weak passwords
  static bool isCommonPassword(String password) {
    final commonPasswords = [
      'password',
      '123456',
      'qwerty',
      'abc123',
      '111111',
      'password123',
      'admin',
      'letmein',
      'welcome',
    ];
    return commonPasswords.contains(password.toLowerCase());
  }
}
