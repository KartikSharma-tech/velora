import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../../core/utils/phone_normalizer.dart';
import '../../domain/entities/device_contact.dart';

class DeviceContactsDataSource {
  /// Permission check — without prompting
  Future<bool> hasPermission() async {
    try {
      return await FlutterContacts.requestPermission(readonly: true);
    } catch (_) {
      return false;
    }
  }

  /// Permission prompt
  Future<bool> requestPermission() {
    return FlutterContacts.requestPermission(readonly: true);
  }

  /// Device contacts read karo — normalized E.164 numbers ke saath
  Future<List<DeviceContact>> getContacts() async {
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    final result = <DeviceContact>[];

    for (final contact in contacts) {
      final displayName = contact.displayName.trim().isEmpty
          ? 'Unknown'
          : contact.displayName.trim();

      final rawNumbers = contact.phones.map((p) => p.number).toList();

      final normalizedPhones = PhoneNormalizer.normalizeAll(rawNumbers);

      // Koi valid number nahi — skip
      if (normalizedPhones.isEmpty) continue;

      result.add(DeviceContact(
        displayName: displayName,
        normalizedPhones: normalizedPhones,
      ));
    }

    return result;
  }
}