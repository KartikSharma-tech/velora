// import 'package:phone_numbers_parser/phone_numbers_parser.dart';


class PhoneNormalizer {
  PhoneNormalizer._();

  static String? normalize(String raw, {String defaultCountry = 'IN'}) {
    try {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) return null;

      // digits only nikaalo
      final digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');

      // already + se shuru ho raha hai
      if (cleaned.startsWith('+')) {
        if (digitsOnly.length >= 10 && digitsOnly.length <= 15) {
          return '+$digitsOnly';
        }
        return null;
      }

      // 10 digit Indian number
      if (digitsOnly.length == 10) {
        return '+91$digitsOnly';
      }

      // 12 digit — 91 prefix
      if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
        return '+$digitsOnly';
      }

      // 11 digit — 0 prefix
      if (digitsOnly.length == 11 && digitsOnly.startsWith('0')) {
        return '+91${digitsOnly.substring(1)}';
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static List<String> normalizeAll(
    List<String> raws, {
    String defaultCountry = 'IN',
  }) {
    return raws
        .map((r) => normalize(r, defaultCountry: defaultCountry))
        .whereType<String>()
        .toSet()
        .toList();
  }

  static bool isValidIndian(String normalized) {
    return normalized.startsWith('+91') && normalized.length == 13;
  }
}