import '../entities/velora_contact.dart';
import '../repositories/contact_repository.dart';
// import '../../../../core/utils/phone_normalizer.dart';

class ContactSyncResult {
  final List<VeloraContact> onVelora;
  final List<VeloraContact> notOnVelora;
  final DateTime syncedAt;
  final bool fromCache;

  const ContactSyncResult({
    required this.onVelora,
    required this.notOnVelora,
    required this.syncedAt,
    required this.fromCache,
  });
}

class ContactSyncEngine {
  final ContactRepository _repository;

  ContactSyncEngine(this._repository);

  Future<ContactSyncResult> sync({bool forceRefresh = false}) async {
    // Step 1 — cache valid hai aur force refresh nahi?
    if (!forceRefresh && await _repository.isCacheValid()) {
      final cached = await _repository.getCachedContacts();
      return _splitContacts(cached, fromCache: true);
    }

    // Step 2 — permission check
    final hasPermission = await _repository.hasPermission();
    if (!hasPermission) {
      final granted = await _repository.requestPermission();
      if (!granted) {
        // Permission nahi mili — cache se return karo
        final cached = await _repository.getCachedContacts();
        return _splitContacts(cached, fromCache: true);
      }
    }

    // Step 3 — device contacts read karo
    final deviceContacts = await _repository.getDeviceContacts();

    // Step 4 — saare numbers collect karo
    final allPhones = deviceContacts
        .expand((c) => c.normalizedPhones)
        .toSet()
        .toList();

    // Step 5 — batch mein Firestore query (30 per batch)
    final veloraUsersMap = <String, VeloraContact>{};
    final batches = _chunk(allPhones, 30);

    for (final batch in batches) {
      final result = await _repository.fetchVeloraUsers(batch);
      veloraUsersMap.addAll(result);
    }

    // Step 6 — device contacts ko VeloraContact mein convert karo
    final allContacts = <VeloraContact>[];

    for (final contact in deviceContacts) {
      // Is contact ka koi number Velora pe hai?
      VeloraContact? matched;
      for (final phone in contact.normalizedPhones) {
        if (veloraUsersMap.containsKey(phone)) {
          matched = veloraUsersMap[phone];
          break;
        }
      }

      if (matched != null) {
        allContacts.add(matched);
      } else {
        // Not on Velora
        allContacts.add(VeloraContact(
          displayName: contact.displayName,
          phone: contact.normalizedPhones.firstOrNull ?? '',
          isOnVelora: false,
        ));
      }
    }

    // Step 7 — cache mein save karo
    await _repository.cacheContacts(allContacts);

    return _splitContacts(allContacts, fromCache: false);
  }

  ContactSyncResult _splitContacts(
    List<VeloraContact> contacts, {
    required bool fromCache,
  }) {
    final onVelora = contacts.where((c) => c.isOnVelora).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    final notOnVelora = contacts.where((c) => !c.isOnVelora).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return ContactSyncResult(
      onVelora: onVelora,
      notOnVelora: notOnVelora,
      syncedAt: DateTime.now(),
      fromCache: fromCache,
    );
  }

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }
}