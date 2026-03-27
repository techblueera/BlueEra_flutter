import 'dart:developer' as dev;

/// Structured logger for chat local storage operations.
///
/// All logs are tagged with `[ChatStorage]` and include the operation name,
/// relevant IDs, and timing information. Logs are only emitted in debug mode.
class ChatStorageLogger {
  static const String _tag = 'ChatStorage';

  // ── Log levels ──────────────────────────────────────────────────────────

  static void info(String operation, String message, {Map<String, dynamic>? data}) {
    _log('INFO', operation, message, data: data);
  }

  static void success(String operation, String message, {Map<String, dynamic>? data}) {
    _log('OK', operation, message, data: data);
  }

  static void warn(String operation, String message, {Map<String, dynamic>? data}) {
    _log('WARN', operation, message, data: data);
  }

  static void error(String operation, String message, {Object? error, StackTrace? stack, Map<String, dynamic>? data}) {
    final buffer = StringBuffer();
    buffer.write('[$_tag] ERROR $operation: $message');
    if (data != null && data.isNotEmpty) buffer.write(' | $data');
    if (error != null) buffer.write('\n  Exception: $error');

    dev.log(
      buffer.toString(),
      name: _tag,
      level: 1000,
      error: error,
      stackTrace: stack,
    );
  }

  // ── Convenience: Chat List operations ───────────────────────────────────

  static void chatListSaved(String type, int count) {
    success('saveChatList', 'Saved $count chats', data: {'type': type});
  }

  static void chatListLoaded(String type, int count) {
    success('getChatList', 'Loaded $count chats from cache', data: {'type': type});
  }

  static void chatListEmpty(String type) {
    info('getChatList', 'No cached chats found', data: {'type': type});
  }

  // ── Convenience: Message operations ─────────────────────────────────────

  static void messagesSaved(String conversationId, int count) {
    success('saveMessages', 'Saved $count messages', data: {'conversationId': _short(conversationId)});
  }

  static void singleMessageSaved(String conversationId, String messageId, String sendStatus) {
    success('saveSingleMessage', 'Appended message', data: {
      'conversationId': _short(conversationId),
      'messageId': _short(messageId),
      'sendStatus': sendStatus.isEmpty ? 'sent' : sendStatus,
    });
  }

  static void messagesLoaded(String conversationId, int count) {
    success('loadMessages', 'Loaded $count messages from cache', data: {'conversationId': _short(conversationId)});
  }

  static void messagesEmpty(String conversationId) {
    info('loadMessages', 'No cached messages', data: {'conversationId': _short(conversationId)});
  }

  // ── Convenience: Offline queue ──────────────────────────────────────────

  static void pendingFound(String conversationId, int count) {
    info('getUnsent', 'Found $count pending messages', data: {'conversationId': _short(conversationId)});
  }

  static void messageSentMarked(String conversationId, String messageId) {
    success('markSent', 'Marked message as sent', data: {
      'conversationId': _short(conversationId),
      'messageId': _short(messageId),
    });
  }

  static void messageIdReplaced(String conversationId, String oldId, String newId) {
    info('markSent', 'Replaced temp ID', data: {
      'conversationId': _short(conversationId),
      'oldId': _short(oldId),
      'newId': _short(newId),
    });
  }

  // ── Convenience: Media ──────────────────────────────────────────────────

  static void mediaMessagesLoaded(String conversationId, int count) {
    success('loadMediaMessages', 'Loaded $count media messages', data: {'conversationId': _short(conversationId)});
  }

  // ── Internal ────────────────────────────────────────────────────────────

  static void _log(String level, String operation, String message, {Map<String, dynamic>? data}) {
    final buffer = StringBuffer();
    buffer.write('[$_tag] $level $operation: $message');
    if (data != null && data.isNotEmpty) buffer.write(' | $data');

    dev.log(buffer.toString(), name: _tag);
  }

  /// Truncate long IDs for readable logs.
  static String _short(String id) {
    if (id.length <= 10) return id;
    return '${id.substring(0, 6)}..${id.substring(id.length - 4)}';
  }
}
