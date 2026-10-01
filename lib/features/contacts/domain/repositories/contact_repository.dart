import '../entities/device_contact.dart';
import '../entities/velora_contact.dart';

abstract class ContactRepository {
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<List<DeviceContact>> getDeviceContacts();
  Future<Map<String, VeloraContact>> fetchVeloraUsers(
    List<String> normalizedPhones,
  );
  Future<void> cacheContacts(List<VeloraContact> contacts);
  Future<List<VeloraContact>> getCachedContacts();
  Future<bool> isCacheValid();
  Future<void> clearCache();
  Future<DateTime?> lastSyncTime();
}