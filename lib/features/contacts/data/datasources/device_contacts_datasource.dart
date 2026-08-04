import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../../core/utils/phone_utils.dart';

/// Thin wrapper around `flutter_contacts` — the only place in the
/// app that touches the device address book.
class DeviceContactsDataSource {
  /// Whether we currently hold the Contacts permission, without
  /// prompting.
  Future<bool> hasPermission() {
    return FlutterContacts.requestPermission(readonly: true).then(
      (_) => true,
      onError: (_) => false,
    );
  }

  /// Prompts the OS contacts-permission dialog if needed. Returns
  /// whether permission is now granted.
  Future<bool> requestPermission() {
    return FlutterContacts.requestPermission(readonly: true);
  }

  /// Reads every phone number from the device address book and
  /// returns a `normalizedPhone -> contactDisplayName` map. A
  /// single contact can contribute multiple numbers; a single
  /// normalized number keeps whichever display name was seen last
  /// (good enough — collisions here are rare and cosmetic only).
  Future<Map<String, String>> readContactPhoneNumbers() async {
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
    );

    final Map<String, String> phoneToName = {};

    for (final contact in contacts) {
      final displayName =
          contact.displayName.trim().isEmpty ? 'Unknown' : contact.displayName;

      for (final phone in contact.phones) {
        final normalized = PhoneUtils.matchKey(phone.number);
        if (normalized.length == 10) {
          phoneToName[normalized] = displayName;
        }
      }
    }

    return phoneToName;
  }
}
