import '../../data/models/matched_contact_model.dart';

abstract class ContactsRepository {
  Future<bool> hasContactsPermission();

  Future<bool> requestContactsPermission();

  /// Reads the device address book, matches numbers against
  /// registered Velora users (who've opted into phone
  /// discoverability), and returns the matches.
  Future<List<MatchedContact>> getMatchedContacts({
    required String currentUserId,
  });
}
