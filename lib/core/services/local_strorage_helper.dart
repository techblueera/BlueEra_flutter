import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/services/chat_local_storage_logger.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../features/chat/auth/model/GetChatListModel.dart';
import '../../features/chat/auth/model/GetListOfMessageData.dart';

class LocalStorageHelper {
  static final LocalStorageHelper _instance = LocalStorageHelper._internal();

  factory LocalStorageHelper() => _instance;

  LocalStorageHelper._internal();

  // ── Cached box references (avoid repeated openBox calls) ──
  Box<String>? _conversationBox;
  Box<String>? _userImagesBox;
  Box<String>? _messagesBox;
  Box<String>? _chatListBox;
  Box<String>? _contactsBox;

  // ── Cached app documents directory ──
  Directory? _appDocDir;

  Future<Directory> get _appDocDirectory async {
    _appDocDir ??= await getApplicationDocumentsDirectory();
    return _appDocDir!;
  }

  Future<Box<String>> get _conversationBoxRef async {
    if (_conversationBox != null && _conversationBox!.isOpen) return _conversationBox!;
    _conversationBox = Hive.isBoxOpen('conversationBox')
        ? Hive.box<String>('conversationBox')
        : await Hive.openBox<String>('conversationBox');
    return _conversationBox!;
  }

  Future<Box<String>> get _userImagesBoxRef async {
    if (_userImagesBox != null && _userImagesBox!.isOpen) return _userImagesBox!;
    _userImagesBox = Hive.isBoxOpen('userImages')
        ? Hive.box<String>('userImages')
        : await Hive.openBox<String>('userImages');
    return _userImagesBox!;
  }

  Future<Box<String>> get _messagesBoxRef async {
    if (_messagesBox != null && _messagesBox!.isOpen) return _messagesBox!;
    _messagesBox = Hive.isBoxOpen('messagesBox')
        ? Hive.box<String>('messagesBox')
        : await Hive.openBox<String>('messagesBox');
    return _messagesBox!;
  }

  Future<Box<String>> get _chatListBoxRef async {
    if (_chatListBox != null && _chatListBox!.isOpen) return _chatListBox!;
    _chatListBox = Hive.isBoxOpen('chatListJsonBox')
        ? Hive.box<String>('chatListJsonBox')
        : await Hive.openBox<String>('chatListJsonBox');
    return _chatListBox!;
  }

  Future<Box<String>> get _contactsBoxRef async {
    if (_contactsBox != null && _contactsBox!.isOpen) return _contactsBox!;
    _contactsBox = Hive.isBoxOpen('contactsBox')
        ? Hive.box<String>('contactsBox')
        : await Hive.openBox<String>('contactsBox');
    return _contactsBox!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSATION TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> putConversation(String newMessage) async {
    final box = await _conversationBoxRef;

    final jsonString = box.get('openedConversationList');
    List<String> conversationList = [];

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        conversationList = decoded.cast<String>();
      } catch (e) {
        ChatStorageLogger.error('putConversation', 'Error decoding openedConversationList', error: e);
      }
    }

    if (!conversationList.contains(newMessage)) {
      conversationList.add(newMessage);
      await box.put('openedConversationList', jsonEncode(conversationList));
    }
  }

  Future<List<String>> getConversation() async {
    final box = await _conversationBoxRef;
    final jsonString = box.get('openedConversationList');

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      ChatStorageLogger.error('getConversation', 'Error decoding openedConversationList', error: e);
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT LIST PERSISTENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save chat list for a given type (PERSONAL_CHAT, BUSINESS_CHAT, GROUP).
  /// Stores as JSON in chatListJsonBox with key = "{type}_chat_list".
  Future<void> saveChatList(List<ChatList?> chats, String type) async {
    if (type.isEmpty) {
      ChatStorageLogger.warn('saveChatList', 'Empty type, skipping save');
      return;
    }
    try {
      final box = await _chatListBoxRef;
      final key = '${type}_chat_list';

      // Filter out nulls and convert to JSON
      final nonNullChats = chats.whereType<ChatList>().toList();
      final jsonList = nonNullChats.map((c) => c.toJson()).toList();
      final encoded = jsonEncode(jsonList);

      await box.put(key, encoded);
      ChatStorageLogger.chatListSaved(type, nonNullChats.length);
    } catch (e, stack) {
      ChatStorageLogger.error('saveChatList', 'Failed to save chat list',
          error: e, stack: stack, data: {'type': type});
    }
  }

  /// Retrieve cached chat list for a given type.
  Future<List<ChatList>> getChatListFromLocal(String type) async {
    if (type.isEmpty) return [];
    try {
      final box = await _chatListBoxRef;
      final key = '${type}_chat_list';
      final jsonString = box.get(key);

      if (jsonString == null || jsonString.isEmpty) {
        ChatStorageLogger.chatListEmpty(type);
        return [];
      }

      final decoded = jsonDecode(jsonString) as List<dynamic>;
      final chatList = decoded
          .map((item) => ChatList.fromJson(item as Map<String, dynamic>))
          .toList();

      ChatStorageLogger.chatListLoaded(type, chatList.length);
      return chatList;
    } catch (e, stack) {
      ChatStorageLogger.error('getChatListFromLocal', 'Failed to load chat list',
          error: e, stack: stack, data: {'type': type});
      return [];
    }
  }

  /// Retrieve all cached chat lists (all types).
  Future<Map<String, List<ChatList>>> getAllChatListsFromLocal() async {
    final result = <String, List<ChatList>>{};
    try {
      const types = [
        AppConstants.personal_Chat_Type,
        AppConstants.business_Chat_Type,
        AppConstants.group_Chat_Type,
      ];

      for (final type in types) {
        final chats = await getChatListFromLocal(type);
        if (chats.isNotEmpty) {
          result[type] = chats;
        }
      }

      ChatStorageLogger.info('getAllChatLists',
          'Loaded ${result.length} chat types from cache',
          data: result.map((k, v) => MapEntry(k, v.length)));
    } catch (e, stack) {
      ChatStorageLogger.error('getAllChatLists', 'Failed to load all chat lists',
          error: e, stack: stack);
    }
    return result;
  }

  /// Search all cached chat lists for a conversation with a specific userId.
  /// Returns the matching ChatList or null if not found.
  Future<ChatList?> findChatByUserId(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final allChats = await getAllChatListsFromLocal();
      for (final chats in allChats.values) {
        for (final chat in chats) {
          if (chat.sender?.id == userId) {
            ChatStorageLogger.info('findChatByUserId',
                'Found cached conversation for user',
                data: {'userId': userId, 'conversationId': chat.conversationId});
            return chat;
          }
        }
      }
      ChatStorageLogger.info('findChatByUserId',
          'No cached conversation found for user',
          data: {'userId': userId});
    } catch (e, stack) {
      ChatStorageLogger.error('findChatByUserId', 'Failed to search cached chats',
          error: e, stack: stack, data: {'userId': userId});
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTACTS PERSISTENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save synced contacts API response to Hive.
  Future<void> saveContacts(Map<String, dynamic> data) async {
    try {
      final box = await _contactsBoxRef;
      await box.put('synced_contacts', jsonEncode(data));
      ChatStorageLogger.success('saveContacts', 'Contacts saved to Hive');
    } catch (e, stack) {
      ChatStorageLogger.error('saveContacts', 'Failed to save contacts',
          error: e, stack: stack);
    }
  }

  /// Load cached contacts from Hive. Returns null if no cache.
  Future<Map<String, dynamic>?> getContacts() async {
    try {
      final box = await _contactsBoxRef;
      final jsonString = box.get('synced_contacts');
      if (jsonString == null || jsonString.isEmpty) {
        ChatStorageLogger.info('getContacts', 'No cached contacts found');
        return null;
      }
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      ChatStorageLogger.success('getContacts', 'Contacts loaded from Hive');
      return decoded;
    } catch (e, stack) {
      ChatStorageLogger.error('getContacts', 'Failed to load contacts',
          error: e, stack: stack);
      return null;
    }
  }

  /// Check if contacts are cached in Hive.
  Future<bool> hasContacts() async {
    try {
      final box = await _contactsBoxRef;
      final data = box.get('synced_contacts');
      return data != null && data.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE PERSISTENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bulk-merge server messages into the local conversation cache.
  /// Server pages arrive one at a time (page 1 is latest 30, page 2 is older
  /// 30, etc.) so a REPLACE strategy would clobber previously-cached pages
  /// whenever the user scrolls. Instead we merge by message id and sort
  /// chronologically. Pending messages are preserved untouched.
  Future<void> saveMessagesByConversationId(
      String conversationId, List<Messages> messages) async {
    if (conversationId.isEmpty) {
      ChatStorageLogger.warn('saveMessages', 'Empty conversationId, skipping');
      return;
    }
    try {
      final box = await _messagesBoxRef;
      final existing = await _getRawMessages(conversationId, box);

      // Index existing by id for O(1) dedup/replace.
      final byId = <String, Map<String, dynamic>>{};
      final pendingWithoutId = <Map<String, dynamic>>[];
      for (final m in existing) {
        final id = m['_id']?.toString() ?? '';
        if (id.isEmpty) {
          // Pending temp messages may land here if their temp id was ever empty;
          // keep them as-is since we can't key them.
          if (m['sendStatus'] == 'pending') pendingWithoutId.add(m);
          continue;
        }
        byId[id] = m;
      }

      // Merge in server messages — server data wins for any overlapping id.
      for (final m in messages) {
        final id = m.id ?? '';
        if (id.isEmpty) continue;
        byId[id] = _messageToStorableJson(m);
      }

      // Combine + sort by createdAt ascending (oldest first) so the UI, which
      // reverses the list itself, renders newest-at-bottom consistently.
      final merged = <Map<String, dynamic>>[
        ...byId.values,
        ...pendingWithoutId,
      ];
      merged.sort((a, b) {
        final aT = a['createdAt']?.toString() ?? '';
        final bT = b['createdAt']?.toString() ?? '';
        return aT.compareTo(bT);
      });

      await box.put(conversationId, jsonEncode(merged));
      ChatStorageLogger.messagesSaved(conversationId, merged.length);
    } catch (e, stack) {
      ChatStorageLogger.error('saveMessages', 'Failed to save messages',
          error: e, stack: stack, data: {'conversationId': conversationId});
    }
  }

  /// Append a single message to the local conversation cache.
  Future<void> saveSingleMessageToConversationId(
      String conversationId,
      Messages newMessage, {
        String sendStatus = "",
      }) async {
    if (conversationId.isEmpty) {
      ChatStorageLogger.warn('saveSingleMessage', 'Empty conversationId, skipping');
      return;
    }
    try {
      final box = await _messagesBoxRef;
      final existing = await _getRawMessages(conversationId, box);

      // Check for duplicate by ID
      final msgId = newMessage.id ?? '';
      if (msgId.isNotEmpty) {
        final alreadyExists = existing.any((m) => m['_id']?.toString() == msgId);
        if (alreadyExists) {
          ChatStorageLogger.info('saveSingleMessage',
              'Message already cached, skipping duplicate',
              data: {'messageId': msgId});
          return;
        }
      }

      // Convert to storable JSON
      final msgJson = _messageToStorableJson(newMessage);

      // Override sendStatus if specified
      if (sendStatus.isNotEmpty) {
        msgJson['sendStatus'] = sendStatus;
      }

      existing.add(msgJson);
      await box.put(conversationId, jsonEncode(existing));

      ChatStorageLogger.singleMessageSaved(
          conversationId, msgId, sendStatus);
    } catch (e, stack) {
      ChatStorageLogger.error('saveSingleMessage', 'Failed to save message',
          error: e, stack: stack, data: {'conversationId': conversationId});
    }
  }

  /// Get all unsent (pending) messages for a conversation.
  /// Returns raw JSON maps so the controller can access sendPendingMsgParams.
  Future<List<Map<String, dynamic>>> getUnsentMessages(String conversationId) async {
    if (conversationId.isEmpty) return [];
    try {
      final box = await _messagesBoxRef;
      final messages = await _getRawMessages(conversationId, box);

      final pending = messages
          .where((m) => m['sendStatus'] == 'pending')
          .toList();

      ChatStorageLogger.pendingFound(conversationId, pending.length);
      return pending;
    } catch (e, stack) {
      ChatStorageLogger.error('getUnsent', 'Failed to get unsent messages',
          error: e, stack: stack, data: {'conversationId': conversationId});
      return [];
    }
  }

  /// Mark a pending message as sent and optionally replace its temp ID.
  Future<void> markMessageAsSent(String conversationId, String messageId) async {
    if (conversationId.isEmpty || messageId.isEmpty) return;
    try {
      final box = await _messagesBoxRef;
      final messages = await _getRawMessages(conversationId, box);

      bool found = false;
      for (int i = 0; i < messages.length; i++) {
        if (messages[i]['_id']?.toString() == messageId) {
          messages[i]['sendStatus'] = '';
          // Clear retry params once sent
          messages[i].remove('sendPendingMsgParams');
          messages[i].remove('pendingFilePaths');
          found = true;
          break;
        }
      }

      if (found) {
        await box.put(conversationId, jsonEncode(messages));
        ChatStorageLogger.messageSentMarked(conversationId, messageId);
      } else {
        ChatStorageLogger.warn('markSent',
            'Message not found in local cache',
            data: {'conversationId': conversationId, 'messageId': messageId});
      }
    } catch (e, stack) {
      ChatStorageLogger.error('markSent', 'Failed to mark message as sent',
          error: e, stack: stack,
          data: {'conversationId': conversationId, 'messageId': messageId});
    }
  }

  /// Replace a local pending message (identified by temp id) with the server-side
  /// authoritative message. Keeps chronological order stable by replacing in place.
  Future<void> replacePendingWithServerMessage(
      String conversationId, String tempId, Messages serverMessage) async {
    if (conversationId.isEmpty || tempId.isEmpty) return;
    try {
      final box = await _messagesBoxRef;
      final messages = await _getRawMessages(conversationId, box);

      final serverJson = _messageToStorableJson(serverMessage);
      final serverId = serverMessage.id ?? '';

      // If the server message is already present (socket beat us), just remove the pending.
      final serverAlreadyExists = serverId.isNotEmpty &&
          messages.any((m) => m['_id']?.toString() == serverId);

      int replacedAt = -1;
      for (int i = 0; i < messages.length; i++) {
        if (messages[i]['_id']?.toString() == tempId) {
          replacedAt = i;
          break;
        }
      }

      if (replacedAt >= 0) {
        if (serverAlreadyExists) {
          messages.removeAt(replacedAt);
        } else {
          messages[replacedAt] = serverJson;
        }
        await box.put(conversationId, jsonEncode(messages));
      } else if (!serverAlreadyExists) {
        messages.add(serverJson);
        await box.put(conversationId, jsonEncode(messages));
      }
    } catch (e, stack) {
      ChatStorageLogger.error('replacePending',
          'Failed to replace pending with server message',
          error: e, stack: stack,
          data: {'conversationId': conversationId, 'tempId': tempId});
    }
  }

  /// List every conversationId that currently has at least one pending message.
  /// Used by the drainer on app start / connectivity restore.
  Future<List<String>> getConversationIdsWithPending() async {
    try {
      final box = await _messagesBoxRef;
      final result = <String>[];
      for (final k in box.keys) {
        final convId = k.toString();
        final raw = await _getRawMessages(convId, box);
        if (raw.any((m) => m['sendStatus'] == 'pending')) {
          result.add(convId);
        }
      }
      return result;
    } catch (e, stack) {
      ChatStorageLogger.error('listPendingConvs',
          'Failed to list conversations with pending messages',
          error: e, stack: stack);
      return [];
    }
  }

  /// Load all cached messages for a conversation as Messages objects.
  Future<List<Messages>> getMessagesByConversationId(String conversationId) async {
    if (conversationId.isEmpty) return [];
    try {
      final box = await _messagesBoxRef;
      final rawList = await _getRawMessages(conversationId, box);

      if (rawList.isEmpty) {
        ChatStorageLogger.messagesEmpty(conversationId);
        return [];
      }

      final messages = rawList
          .map((json) {
            try {
              return Messages.fromJson(json);
            } catch (e) {
              ChatStorageLogger.warn('loadMessages',
                  'Skipping malformed message',
                  data: {'id': json['_id'], 'error': e.toString()});
              return null;
            }
          })
          .whereType<Messages>()
          .toList();

      ChatStorageLogger.messagesLoaded(conversationId, messages.length);
      return messages;
    } catch (e, stack) {
      ChatStorageLogger.error('loadMessages', 'Failed to load messages',
          error: e, stack: stack, data: {'conversationId': conversationId});
      return [];
    }
  }

  /// Load only media messages (image, video, audio, document) for a conversation.
  Future<List<Messages>> getMediaMessagesByConversationId(String conversationId) async {
    if (conversationId.isEmpty) return [];
    try {
      final allMessages = await getMessagesByConversationId(conversationId);
      const mediaTypes = {'image', 'video', 'audio', 'document'};

      final mediaMessages = allMessages
          .where((m) => mediaTypes.contains(m.messageType))
          .toList();

      ChatStorageLogger.mediaMessagesLoaded(conversationId, mediaMessages.length);
      return mediaMessages;
    } catch (e, stack) {
      ChatStorageLogger.error('loadMediaMessages', 'Failed to load media messages',
          error: e, stack: stack, data: {'conversationId': conversationId});
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER IMAGE CACHING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> _downloadAndSaveImage(String imageUrl, String userId) async {
    try {
      if (userId.trim().isEmpty) {
        throw Exception('Invalid userId for image filename');
      }

      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final directory = await _appDocDirectory;

        final originalPath = '${directory.path}/$userId-original.jpg';
        final compressedPath = '${directory.path}/$userId-compressed.jpg';

        final originalFile = File(originalPath);
        await originalFile.writeAsBytes(response.bodyBytes);

        final compressedBytes = await FlutterImageCompress.compressWithFile(
          originalFile.path,
          quality: 60,
          minWidth: 300,
          minHeight: 300,
          format: CompressFormat.jpeg,
        );

        if (compressedBytes != null) {
          final compressedFile = File(compressedPath);
          await compressedFile.writeAsBytes(compressedBytes);

          if (await originalFile.exists()) {
            await originalFile.delete();
          }

          return compressedPath;
        } else {
          return originalPath;
        }
      }
    } catch (e) {
      ChatStorageLogger.error('downloadImage', 'Failed to download/compress image',
          error: e, data: {'userId': userId});
    }

    return '';
  }

  Future<String> getOrDownloadUserImage(String url, String userId) async {
    if (userId.isEmpty || url.isEmpty) return url;
    final box = await _userImagesBoxRef;
    return _getOrDownloadUserImageWithBox(url, userId, box);
  }

  Future<String> _getOrDownloadUserImageWithBox(String url, String userId, Box<String> box) async {
    if (userId.isEmpty || url.isEmpty) return url;

    final existing = box.get(userId);
    if (existing != null && existing.isNotEmpty && File(existing).existsSync()) {
      return existing;
    }

    final savedPath = await _downloadAndSaveImage(url, userId);

    if (savedPath.isNotEmpty) {
      await box.put(userId, savedPath);
      return savedPath;
    }

    return url;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Read raw JSON message list from Hive box.
  Future<List<Map<String, dynamic>>> _getRawMessages(
      String conversationId, Box<String> box) async {
    final jsonString = box.get(conversationId);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      ChatStorageLogger.error('_getRawMessages', 'Corrupted cache, returning empty',
          error: e, data: {'conversationId': conversationId});
      return [];
    }
  }

  /// Convert a Messages object to a JSON map safe for Hive storage.
  /// Strips non-serializable fields like File objects.
  Map<String, dynamic> _messageToStorableJson(Messages m) {
    final json = m.toJson();
    // Remove File objects that can't be JSON-encoded
    json.remove('sendLoadingFile');
    // Ensure nested objects are serializable
    if (json['parentMessage'] != null && json['parentMessage'] is! Map) {
      try {
        json['parentMessage'] = (json['parentMessage'] as dynamic).toJson();
      } catch (_) {
        json.remove('parentMessage');
      }
    }
    if (json['conversation'] != null && json['conversation'] is! Map) {
      try {
        json['conversation'] = (json['conversation'] as dynamic).toJson();
      } catch (_) {
        json.remove('conversation');
      }
    }
    return json;
  }
}

class AiChatLocalStorage {
  static const String _boxName = "aiChatBox";

  static const String keyPersonalConversationId = "personalConversationId";
  static const String keyBusinessConversationId = "businessConversationId";
  static const String keyAiSearchConversationId = "keyAiSearchConversationId";
  static const String keyInventoryConversationId = "keyInventoryConversationId";
  static const String keyFoodConversationId = "keyFoodConversationId";
  static const String keyServicesConversationId = "keyServicesConversationId";
  static const String keyHealthCareConversationId = "keyHealthCareConversationId";
  static const String keyEducationConversationId = "keyEducationConversationId";
  static const String keyHomeServiceConversationId = "keyHomeServiceConversationId";
  static const String keyTravelStayConversationId = "keyTravelStayConversationId";
  static const String keyConsultingTalkConversationId = "keyConsultingTalkConversationId";

  static Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    } else {
      return await Hive.openBox<String>(_boxName);
    }
  }

  /// Save Conversation ID for given type (personal/business)
  static Future<void> saveConversationIdIfEmpty({
    required String type,
    required String id,
  }) async {
    final box = await _openBox();

    String key = _getKey(type);
    String? existingId = box.get(key);

    if (existingId == null || existingId.isEmpty) {
      await box.put(key, id);
    }
  }

  /// Get Conversation ID for given type
  static Future<String?> getConversationId(String type) async {
    final box = await _openBox();
    String key = _getKey(type);
    return box.get(key);
  }

  /// Clear Conversation ID for given type
  static Future<void> clearConversationId(String type) async {
    final box = await _openBox();
    String key = _getKey(type);
    await box.delete(key);
  }

  /// Internal: Map type to storage key
  static String _getKey(String type) {
    switch (type) {
      case AppConstants.personal_Chat_Type:
        return keyPersonalConversationId;
      case AppConstants.business_Chat_Type:
        return keyBusinessConversationId;
      case AppConstants.search_Chat_Type:
        return keyAiSearchConversationId;
      case AppConstants.askInventory_Chat_Type:
        return keyInventoryConversationId;
      case AppConstants.askFood_Chat_Type:
        return keyFoodConversationId;
      case AppConstants.askService_Chat_Type:
        return keyServicesConversationId;
      case AppConstants.askHealthCare_Chat_Type:
        return keyHealthCareConversationId;
      case AppConstants.askEducation_Chat_Type:
        return keyEducationConversationId;
      case AppConstants.askHomeService_Chat_Type:
        return keyHomeServiceConversationId;
      case AppConstants.askTravelStay_Chat_Type:
        return keyTravelStayConversationId;
      case AppConstants.askConsultingTalk_Chat_Type:
        return keyConsultingTalkConversationId;
      default:
        throw Exception("Invalid type.");
    }
  }
}

class UserImageStorage {
  static const _boxName = "userImagesBox";

  static Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }

  // Save
  static Future<void> saveUserImage(String userId, String filePath) async {
    final box = await _openBox();
    await box.put(userId, filePath);
  }

  // Get
  static Future<String?> getUserImage(String userId) async {
    final box = await _openBox();
    return box.get(userId);
  }
}
