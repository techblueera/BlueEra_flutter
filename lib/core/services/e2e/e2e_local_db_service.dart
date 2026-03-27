import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../../../features/chat/auth/model/e2e_models.dart';

/// SQLite-backed local database for all E2E encryption state:
///  • Decrypted messages (local-only, long-term storage)
///  • Sync cursors (last seq_num per conversation)
///  • Signal Protocol sessions (serialized binary)
///  • One-time prekey (OPK) records (public + private keys)
class E2ELocalDbService {
  static final E2ELocalDbService _instance = E2ELocalDbService._internal();
  factory E2ELocalDbService() => _instance;
  E2ELocalDbService._internal();

  Database? _db;

  // ─── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = p.join(await getDatabasesPath(), 'blueera_e2e.db');
    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add sender_device_id column (added in v2)
      await db.execute('ALTER TABLE e2e_messages ADD COLUMN sender_device_id TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Decrypted messages
    await db.execute('''
      CREATE TABLE e2e_messages (
        message_id      TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        seq_num         INTEGER NOT NULL,
        sender_id       TEXT NOT NULL,
        sender_device_id TEXT,
        plaintext       TEXT,
        ciphertext      TEXT,
        encrypted_media TEXT,
        expires_at      TEXT NOT NULL,
        status          TEXT NOT NULL,
        created_at      TEXT NOT NULL
      )
    ''');

    // Sync cursors — one row per conversation, cursor only moves forward
    await db.execute('''
      CREATE TABLE sync_cursors (
        conversation_id   TEXT PRIMARY KEY,
        last_synced_seq   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Signal Protocol sessions — keyed by "{userId}:{deviceId}"
    await db.execute('''
      CREATE TABLE signal_sessions (
        address       TEXT PRIMARY KEY,
        session_data  BLOB NOT NULL
      )
    ''');

    // One-time prekeys (OPKs) — private keys stored encrypted at rest
    await db.execute('''
      CREATE TABLE opk_keys (
        key_id      INTEGER PRIMARY KEY,
        public_key  TEXT NOT NULL,
        private_key TEXT NOT NULL,
        uploaded    INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Database get _database {
    if (_db == null) throw StateError('E2ELocalDbService not initialised. Call init() first.');
    return _db!;
  }

  // ─── Messages ──────────────────────────────────────────────────────────────

  /// Insert or replace a local E2E message (idempotent by message_id).
  Future<void> upsertMessage(EncryptedMessageLocal msg) async {
    await _database.insert(
      'e2e_messages',
      msg.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update the plaintext + clear ciphertext after successful decryption.
  Future<void> markDecrypted({
    required String messageId,
    required String plaintext,
  }) async {
    await _database.update(
      'e2e_messages',
      {'plaintext': plaintext, 'ciphertext': null},
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  /// Update message delivery status.
  Future<void> updateMessageStatus({
    required String messageId,
    required String status,
  }) async {
    await _database.update(
      'e2e_messages',
      {'status': status},
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  /// Retrieve messages for a conversation, ordered by seq_num ascending.
  Future<List<EncryptedMessageLocal>> getMessages(String conversationId) async {
    final rows = await _database.query(
      'e2e_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'seq_num ASC',
    );
    return rows.map(EncryptedMessageLocal.fromMap).toList();
  }

  /// Delete a message by its ID (used to remove optimistic temp-ID entries).
  Future<void> deleteMessage(String messageId) async {
    await _database.delete(
      'e2e_messages',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  /// Check if a message already exists (dedup guard during sync).
  Future<bool> messageExists(String messageId) async {
    final rows = await _database.query(
      'e2e_messages',
      columns: ['message_id'],
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ─── Sync Cursors ──────────────────────────────────────────────────────────

  /// Get the last synced seq_num for a conversation (0 if never synced).
  Future<int> getSyncCursor(String conversationId) async {
    final rows = await _database.query(
      'sync_cursors',
      columns: ['last_synced_seq'],
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return rows.first['last_synced_seq'] as int;
  }

  /// Advance the sync cursor (monotonic — only moves forward, never back).
  Future<void> advanceSyncCursor(String conversationId, int seqNum) async {
    await _database.rawInsert(
      '''
      INSERT INTO sync_cursors (conversation_id, last_synced_seq)
      VALUES (?, ?)
      ON CONFLICT(conversation_id)
      DO UPDATE SET last_synced_seq = MAX(last_synced_seq, excluded.last_synced_seq)
      ''',
      [conversationId, seqNum],
    );
  }

  /// Get all tracked conversation IDs (for bulk sync on reconnect).
  Future<List<String>> getAllTrackedConversationIds() async {
    final rows = await _database.query('sync_cursors', columns: ['conversation_id']);
    return rows.map((r) => r['conversation_id'] as String).toList();
  }

  // ─── Signal Protocol Sessions ──────────────────────────────────────────────

  /// Address format: "{userId}:{deviceId}"
  Future<Uint8List?> loadSession(String address) async {
    final rows = await _database.query(
      'signal_sessions',
      columns: ['session_data'],
      where: 'address = ?',
      whereArgs: [address],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['session_data'] as Uint8List;
  }

  Future<void> storeSession(String address, Uint8List sessionData) async {
    await _database.insert(
      'signal_sessions',
      {'address': address, 'session_data': sessionData},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> containsSession(String address) async {
    final rows = await _database.query(
      'signal_sessions',
      columns: ['address'],
      where: 'address = ?',
      whereArgs: [address],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> deleteSession(String address) async {
    await _database.delete(
      'signal_sessions',
      where: 'address = ?',
      whereArgs: [address],
    );
  }

  Future<List<String>> getSubDeviceSessions(String userId) async {
    final rows = await _database.query(
      'signal_sessions',
      columns: ['address'],
      where: 'address LIKE ?',
      whereArgs: ['$userId:%'],
    );
    return rows.map((r) => r['address'] as String).toList();
  }

  // ─── OPK Keys ──────────────────────────────────────────────────────────────

  Future<void> insertOPK(OPKRecord opk) async {
    await _database.insert(
      'opk_keys',
      opk.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertOPKs(List<OPKRecord> opks) async {
    final batch = _database.batch();
    for (final opk in opks) {
      batch.insert('opk_keys', opk.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<OPKRecord?> loadOPK(int keyId) async {
    final rows = await _database.query(
      'opk_keys',
      where: 'key_id = ?',
      whereArgs: [keyId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OPKRecord.fromMap(rows.first);
  }

  Future<void> deleteOPK(int keyId) async {
    await _database.delete('opk_keys', where: 'key_id = ?', whereArgs: [keyId]);
  }

  Future<List<OPKRecord>> getUnuploadedOPKs() async {
    final rows = await _database.query(
      'opk_keys',
      where: 'uploaded = 0',
    );
    return rows.map(OPKRecord.fromMap).toList();
  }

  Future<void> markOPKsUploaded(List<int> keyIds) async {
    if (keyIds.isEmpty) return;
    final placeholders = keyIds.map((_) => '?').join(', ');
    await _database.rawUpdate(
      'UPDATE opk_keys SET uploaded = 1 WHERE key_id IN ($placeholders)',
      keyIds,
    );
  }

  Future<int> getNextOPKId() async {
    final result = await _database.rawQuery('SELECT MAX(key_id) as max_id FROM opk_keys');
    final maxId = result.first['max_id'] as int?;
    return (maxId ?? -1) + 1;
  }

  Future<int> getUploadedOPKCount() async {
    final result = await _database.rawQuery(
      'SELECT COUNT(*) as cnt FROM opk_keys WHERE uploaded = 1',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ─── Dispose ───────────────────────────────────────────────────────────────

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
