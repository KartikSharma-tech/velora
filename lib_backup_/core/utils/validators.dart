class Validators {
  Validators._();

  // ===========================================================
  // Required
  // ===========================================================

  static String? required(
    String? value, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ===========================================================
  // Email
  // ===========================================================

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final regex = RegExp(
      r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
    );

    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // ===========================================================
  // Password
  // ===========================================================

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }

    return null;
  }

  // ===========================================================
  // Confirm Password
  // ===========================================================

  static String? confirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ===========================================================
  // Name
  // ===========================================================

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name is too short';
    }

    return null;
  }

  // ===========================================================
  // Username
  // ===========================================================

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

    if (!regex.hasMatch(value.trim())) {
      return 'Username must be 3-20 characters';
    }

    return null;
  }

  // ===========================================================
  // Phone
  // ===========================================================

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final regex = RegExp(r'^[0-9]{10}$');

    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  // ===========================================================
  // OTP
  // ===========================================================

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }

    if (value.trim().length != 6) {
      return 'OTP must be 6 digits';
    }

    return null;
  }

  // ===========================================================
  // URL
  // ===========================================================

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final regex = RegExp(
      r'^(https?:\/\/)?([\w\-]+\.)+[\w\-]+(\/[\w\-./?%&=]*)?$',
    );

    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid URL';
    }

    return null;
  }

  // ===========================================================
  // Bio
  // ===========================================================

  static String? bio(String? value) {
    if (value == null) return null;

    if (value.length > 250) {
      return 'Bio cannot exceed 250 characters';
    }

    return null;
  }
}