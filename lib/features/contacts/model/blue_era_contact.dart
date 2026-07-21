/// One row of `GET contact-service/api/contacts/on-blueera`.
///
/// [name] is the user's OWN phonebook name for this person — render it as-is,
/// that's what makes the list feel like Telegram/WhatsApp. [userId] is the
/// BlueEra user id and feeds straight into the existing profile / chat
/// navigation.
class BlueEraContact {
  final String phone;
  final String name;
  final bool isOnBlueEra;
  final String? userId;
  final String? matchedAt;
  final String? addedAt;

  BlueEraContact({
    required this.phone,
    required this.name,
    required this.isOnBlueEra,
    this.userId,
    this.matchedAt,
    this.addedAt,
  });

  factory BlueEraContact.fromJson(Map<String, dynamic> json) => BlueEraContact(
        phone: json['phone']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        isOnBlueEra: json['is_on_blueera'] == true,
        userId: json['user_id']?.toString(),
        matchedAt: json['matched_at']?.toString(),
        addedAt: json['added_at']?.toString(),
      );
}

/// `GET contact-service/api/contacts/sync-state` — lets the app skip an upload
/// when nothing in the phonebook changed (see [ContactSyncController.syncPhonebook]).
class ContactSyncState {
  final bool hasSynced;
  final String? lastSyncAt;
  final int contactsCount;
  final int matchedCount;
  final String? digest;
  final int syncVersion;

  ContactSyncState({
    required this.hasSynced,
    this.lastSyncAt,
    required this.contactsCount,
    required this.matchedCount,
    this.digest,
    required this.syncVersion,
  });

  factory ContactSyncState.fromJson(Map<String, dynamic> json) =>
      ContactSyncState(
        hasSynced: json['has_synced'] == true,
        lastSyncAt: json['last_sync_at']?.toString(),
        contactsCount: (json['contacts_count'] as num?)?.toInt() ?? 0,
        matchedCount: (json['matched_count'] as num?)?.toInt() ?? 0,
        digest: json['digest']?.toString(),
        syncVersion: (json['sync_version'] as num?)?.toInt() ?? 0,
      );

  /// Parsed [lastSyncAt], or null when never synced / unparseable.
  DateTime? get lastSyncedAt {
    final raw = lastSyncAt;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
