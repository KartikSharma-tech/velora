/// ===========================================================
/// Velora — Privacy Enums
/// -----------------------------------------------------------
/// Backing values are stored as plain strings in Firestore so
/// old/unknown values never crash a `fromMap()` — they just fall
/// back to a safe default via [orDefault].
/// ===========================================================
library;

enum WhoCanMessage {
  anyone('anyone'),
  contacts('contacts'),
  contactsAndRequests('contacts_and_requests'),
  nobody('nobody');

  const WhoCanMessage(this.storageValue);

  final String storageValue;

  static WhoCanMessage fromStorage(String? value) {
    return WhoCanMessage.values.firstWhere(
      (e) => e.storageValue == value,
      orElse: () => WhoCanMessage.contactsAndRequests,
    );
  }

  String get label => switch (this) {
        WhoCanMessage.anyone => 'Anyone',
        WhoCanMessage.contacts => 'Contacts only',
        WhoCanMessage.contactsAndRequests => 'Contacts + Accepted Requests',
        WhoCanMessage.nobody => 'Nobody',
      };

  String get description => switch (this) {
        WhoCanMessage.anyone =>
          'Any registered user can message you directly.',
        WhoCanMessage.contacts =>
          'Only people who have your number saved as a contact can message you.',
        WhoCanMessage.contactsAndRequests =>
          'Contacts can message you directly. Everyone else must send a request first.',
        WhoCanMessage.nobody => 'No one can start a new conversation with you.',
      };
}

enum Discoverability {
  username('username'),
  phoneNumber('phone_number'),
  hidden('hidden');

  const Discoverability(this.storageValue);

  final String storageValue;

  static Discoverability fromStorage(String? value) {
    return Discoverability.values.firstWhere(
      (e) => e.storageValue == value,
      orElse: () => Discoverability.username,
    );
  }

  String get label => switch (this) {
        Discoverability.username => 'Username',
        Discoverability.phoneNumber => 'Phone Number',
        Discoverability.hidden => 'Hidden',
      };

  String get description => switch (this) {
        Discoverability.username =>
          'People can find you by searching your username.',
        Discoverability.phoneNumber =>
          'People who have your number in their contacts can find you.',
        Discoverability.hidden => "You won't show up in search or contacts.",
      };
}
