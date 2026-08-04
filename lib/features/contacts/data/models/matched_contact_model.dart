import '../../../user/data/models/user_model.dart';

/// A device contact that matched a registered Velora user.
class MatchedContact {
  const MatchedContact({
    required this.contactName,
    required this.user,
  });

  /// The name saved in the *device's* address book (may differ
  /// from the user's Velora display name).
  final String contactName;
  final UserModel user;
}
