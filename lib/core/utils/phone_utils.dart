/// ===========================================================
/// Velora — Phone Number Utilities
/// -----------------------------------------------------------
/// Lightweight phone normalization for contact matching. Not a
/// full E.164/libphonenumber implementation — deliberately simple
/// so it has no extra dependency. Strategy: strip everything but
/// digits, then match on the last 10 digits (covers the common
/// case of the same number being saved with/without a country
/// code, spaces, dashes, or parentheses).
/// ===========================================================
library;

class PhoneUtils {
  const PhoneUtils._();

  /// Digits only (keeps a leading `+` off — country codes vary too
  /// much to normalize reliably without a full phone-number lib).
  static String digitsOnly(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// The value actually stored on `UserModel.phoneNumber` and used
  /// as the Firestore match key: digits only, capped to the last
  /// 10 digits so "+91 98765 43210", "9876543210", and
  /// "098765 43210" all normalize to the same key.
  static String matchKey(String raw) {
    final digits = digitsOnly(raw);
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  static bool isValid(String raw) => matchKey(raw).length == 10;
}
