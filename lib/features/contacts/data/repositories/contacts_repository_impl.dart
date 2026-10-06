// import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/device_contact.dart';
import '../../domain/entities/velora_contact.dart';
import '../../domain/repositories/contact_repository.dart';
import '../datasources/device_contacts_datasource.dart';
import '../datasources/firestore_contacts_match_datasource.dart';
import '../datasources/hive_contacts_datasource.dart';

class ContactsRepositoryImpl implements ContactRepository {
  final DeviceContactsDataSource _deviceDataSource;
  final FirestoreContactsMatchDataSource _firestoreDataSource;
  final HiveContactsDataSource _hiveDataSource;

  ContactsRepositoryImpl({
    required this._deviceDataSource,
    required FirestoreContactsMatchDataSource firestoreDataSource,
    required this._hiveDataSource,
  })  : _firestoreDataSource = firestoreDataSource;

  @override
  Future<bool> requestPermission() => _deviceDataSource.requestPermission();

  @override
  Future<bool> hasPermission() => _deviceDataSource.hasPermission();

  @override
  Future<List<DeviceContact>> getDeviceContacts() =>
      _deviceDataSource.getContacts();

  @override
  Future<Map<String, VeloraContact>> fetchVeloraUsers(
    List<String> normalizedPhones,
  ) =>
      _firestoreDataSource.fetchVeloraUsers(normalizedPhones);

  @override
  Future<void> cacheContacts(List<VeloraContact> contacts) =>
      _hiveDataSource.cacheContacts(contacts);

  @override
  Future<List<VeloraContact>> getCachedContacts() =>
      _hiveDataSource.getCachedContacts();

  @override
  Future<bool> isCacheValid() => _hiveDataSource.isCacheValid();

  @override
  Future<void> clearCache() => _hiveDataSource.clearCache();

  @override
  Future<DateTime?> lastSyncTime() => _hiveDataSource.lastSyncTime();
}