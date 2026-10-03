import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/device_contacts_datasource.dart';
import '../../data/datasources/firestore_contacts_match_datasource.dart';
import '../../data/datasources/hive_contacts_datasource.dart';
import '../../data/repositories/contacts_repository_impl.dart';
import '../../domain/entities/velora_contact.dart';
import '../../domain/repositories/contact_repository.dart';
import '../../domain/usecases/contact_sync_engine.dart';

// ── DataSources ─────────────────────────────────────────────────────
final deviceContactsDataSourceProvider =
    Provider<DeviceContactsDataSource>((ref) {
  return DeviceContactsDataSource();
});

final firestoreContactsDataSourceProvider =
    Provider<FirestoreContactsMatchDataSource>((ref) {
  return FirestoreContactsMatchDataSource();
});

final hiveContactsDataSourceProvider =
    Provider<HiveContactsDataSource>((ref) {
  return HiveContactsDataSource();
});

// ── Repository ───────────────────────────────────────────────────────
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactsRepositoryImpl(
    deviceDataSource: ref.watch(deviceContactsDataSourceProvider),
    firestoreDataSource: ref.watch(firestoreContactsDataSourceProvider),
    hiveDataSource: ref.watch(hiveContactsDataSourceProvider),
  );
});

// ── SyncEngine ───────────────────────────────────────────────────────
final contactSyncEngineProvider = Provider<ContactSyncEngine>((ref) {
  return ContactSyncEngine(ref.watch(contactRepositoryProvider));
});

// ── Permission ───────────────────────────────────────────────────────
final hasContactsPermissionProvider = FutureProvider<bool>((ref) {
  return ref.watch(contactRepositoryProvider).hasPermission();
});

// ── Sync ─────────────────────────────────────────────────────────────
final contactSyncProvider =
    FutureProvider.family<ContactSyncResult, bool>((ref, forceRefresh) {
  return ref
      .read(contactSyncEngineProvider)
      .sync(forceRefresh: forceRefresh);
});

// ── Convenience ──────────────────────────────────────────────────────
final veloraContactsProvider = Provider<List<VeloraContact>>((ref) {
  return ref
          .watch(contactSyncProvider(false))
          .value
          ?.onVelora ??
      [];
});

final inviteContactsProvider = Provider<List<VeloraContact>>((ref) {
  return ref
          .watch(contactSyncProvider(false))
          .value
          ?.notOnVelora ??
      [];
});