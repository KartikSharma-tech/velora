import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/device_contacts_datasource.dart';
import '../../data/datasources/firestore_contacts_match_datasource.dart';
import '../../data/models/matched_contact_model.dart';
import '../../data/repositories/contacts_repository_impl.dart';
import '../../domain/repositories/contacts_repository.dart';

final deviceContactsDataSourceProvider =
    Provider<DeviceContactsDataSource>((ref) {
  return DeviceContactsDataSource();
});

final firestoreContactsMatchDataSourceProvider =
    Provider<FirestoreContactsMatchDataSource>((ref) {
  return FirestoreContactsMatchDataSource();
});

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return ContactsRepositoryImpl(
    deviceDataSource: ref.watch(deviceContactsDataSourceProvider),
    matchDataSource: ref.watch(firestoreContactsMatchDataSourceProvider),
  );
});

/// One-shot fetch of matched contacts for the given user. Re-run by
/// invalidating this provider (e.g. pull-to-refresh, or after
/// granting permission).
final matchedContactsProvider =
    FutureProvider.family<List<MatchedContact>, String>((ref, userId) {
  return ref.watch(contactsRepositoryProvider).getMatchedContacts(
        currentUserId: userId,
      );
});

/// Whether we currently hold Contacts permission. A real
/// `FutureProvider` (not an inline `FutureBuilder` calling the
/// repository directly) so its Future is cached instead of being
/// re-created — and its loading spinner re-flashed — on every
/// unrelated parent rebuild. Invalidate after requesting permission
/// to re-check.
final hasContactsPermissionProvider = FutureProvider<bool>((ref) {
  return ref.watch(contactsRepositoryProvider).hasContactsPermission();
});
