import '../../../../shared/enums/privacy_enums.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../datasources/device_contacts_datasource.dart';
import '../datasources/firestore_contacts_match_datasource.dart';
import '../models/matched_contact_model.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  ContactsRepositoryImpl({
    required this._deviceDataSource,
    required this._matchDataSource,
  });

  final DeviceContactsDataSource _deviceDataSource;
  final FirestoreContactsMatchDataSource _matchDataSource;

  @override
  Future<bool> hasContactsPermission() {
    return _deviceDataSource.hasPermission();
  }

  @override
  Future<bool> requestContactsPermission() {
    return _deviceDataSource.requestPermission();
  }

  @override
  Future<List<MatchedContact>> getMatchedContacts({
    required String currentUserId,
  }) async {
    final hasPermission = await _deviceDataSource.hasPermission();
    if (!hasPermission) return [];

    final phoneToName = await _deviceDataSource.readContactPhoneNumbers();

    if (phoneToName.isEmpty) return [];

    final registeredUsers = await _matchDataSource.findRegisteredUsers(
      phoneToName.keys.toList(),
      excludeUid: currentUserId,
    );

    final matches = <MatchedContact>[];

    for (final user in registeredUsers) {
      // Only surface users who've opted into phone-based
      // discoverability — "username" or "hidden" users don't show
      // up here even if their number is in the address book.
      if (user.discoverability != Discoverability.phoneNumber) continue;

      final contactName = phoneToName[user.phoneNumber];
      if (contactName == null) continue;

      matches.add(MatchedContact(contactName: contactName, user: user));
    }

    matches.sort(
      (a, b) => a.contactName.toLowerCase().compareTo(b.contactName.toLowerCase()),
    );

    return matches;
  }
}
