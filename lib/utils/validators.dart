/// 🔹 Validators - Professional input validation for entire app
class AppValidators {
  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENT VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validate payment amount
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    try {
      final amount = double.parse(value);
      if (amount <= 0) {
        return 'Amount must be greater than 0';
      }
      if (amount > 1000000) {
        return 'Amount exceeds maximum limit';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid amount';
    }
  }

  /// Validate payment method is selected
  static String? validatePaymentMethod(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a payment method';
    }
    return null;
  }

  /// Validate card number (basic Luhn check)
  static String? validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    final cardNumber = value.replaceAll(' ', '').replaceAll('-', '');
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return 'Card number must be 13-19 digits';
    }

    if (!_luhnCheck(cardNumber)) {
      return 'Invalid card number';
    }

    return null;
  }

  /// Validate card expiry
  static String? validateCardExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }

    try {
      final parts = value.split('/');
      if (parts.length != 2) {
        return 'Use MM/YY format';
      }

      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);

      if (month < 1 || month > 12) {
        return 'Invalid month';
      }

      final now = DateTime.now();
      final expiry = DateTime(2000 + year, month);

      if (expiry.isBefore(now)) {
        return 'Card has expired';
      }

      return null;
    } catch (e) {
      return 'Invalid expiry date format';
    }
  }

  /// Validate CVV
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }

    if (!RegExp(r'^[0-9]{3,4}$').hasMatch(value)) {
      return 'CVV must be 3-4 digits';
    }

    return null;
  }

  /// Validate cardholder name
  static String? validateCardholderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Cardholder name is required';
    }

    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTHENTICATION VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain number';
    }

    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain special character';
    }

    return null;
  }

  /// Confirm password matches
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Pakistan phone number validation (flexible)
    final phoneRegex = RegExp(
      r'^[+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$',
    );

    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
      return 'Phone number must have at least 10 digits';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERAL VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    if (value.length < minLength) {
      return 'Must be at least $minLength characters';
    }

    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    if (value.length > maxLength) {
      return 'Must not exceed $maxLength characters';
    }

    return null;
  }

  /// Validate numeric input
  static String? validateNumeric(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Please enter only numbers';
    }

    return null;
  }

  /// Validate alphanumeric input
  static String? validateAlphanumeric(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return 'Only letters and numbers allowed';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Luhn algorithm for card number validation
  static bool _luhnCheck(String cardNumber) {
    int sum = 0;
    int isEven = 0;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);

      if (isEven == 1) {
        n *= 2;
        if (n > 9) {
          n -= 9;
        }
      }

      sum += n;
      isEven ^= 1;
    }

    return sum % 10 == 0;
  }

  /// Get password strength indicator
  static String getPasswordStrength(String password) {
    if (password.isEmpty) return 'No password';
    if (password.length < 8) return 'Weak';
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'))) {
      return 'Strong';
    }
    return 'Medium';
  }

  /// Get password strength color
  static int getPasswordStrengthColor(String password) {
    switch (getPasswordStrength(password)) {
      case 'Weak':
        return 0xFFDC2626; // Red
      case 'Medium':
        return 0xFFF59E0B; // Amber
      case 'Strong':
        return 0xFF10B981; // Green
      default:
        return 0xFF6B7280; // Gray
    }
  }
}
