import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/services/local_strorage_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Watches connectivity and retries messages that were saved locally with
/// `sendStatus: "pending"`. Runs independently of any open UI — pending
/// messages persisted across app kill will flush as soon as the network
/// comes back, then show up on next chat open via the local-first load.
class PendingMessageDrainer {
  PendingMessageDrainer._();
  static final PendingMessageDrainer instance = PendingMessageDrainer._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _started = false;
  bool _draining = false;

  /// Call once after auth is ready (app start, /loop after login flow).
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _sub = _connectivity.onConnectivityChanged.listen((result) {
      if (_isOnlineResult(result)) {
        drainNow();
      }
    });

    // Best-effort initial drain if already online at startup.
    if (await _isCurrentlyOnline()) {
      drainNow();
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }

  bool _isOnlineResult(List<ConnectivityResult> result) {
    if (result.isEmpty) return false;
    if (result.contains(ConnectivityResult.none)) return false;
    return result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.ethernet) ||
        result.contains(ConnectivityResult.vpn);
  }

  Future<bool> _isCurrentlyOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isOnlineResult(result);
    } catch (_) {
      return false;
    }
  }

  /// Drains every conversation that has pending messages. Safe to call
  /// repeatedly — it short-circuits if another drain is already running.
  Future<void> drainNow() async {
    if (_draining) return;
    _draining = true;
    try {
      final convIds =
          await LocalStorageHelper().getConversationIdsWithPending();
      for (final convId in convIds) {
        await _drainConversation(convId);
      }
    } catch (e, st) {
      debugPrint('[PendingMessageDrainer] drain error: $e\n$st');
    } finally {
      _draining = false;
    }
  }

  Future<void> _drainConversation(String conversationId) async {
    final pending =
        await LocalStorageHelper().getUnsentMessages(conversationId);
    if (pending.isEmpty) return;

    // Oldest first — same order as persisted.
    for (final msg in pending) {
      final tempId = msg['_id']?.toString() ?? '';
      final type = msg['message_type']?.toString() ?? '';
      final paramsRaw = msg['sendPendingMsgParams'];
      if (tempId.isEmpty || paramsRaw is! Map) continue;

      // Only text-like types are safe to retry from the drainer — media
      // needs the upload-URL pre-sign flow. Media retries still happen
      // when the user reopens the chat (ChatViewController.sendOfflineMessage).
      if (type != 'text' &&
          type != 'contact' &&
          type != 'location' &&
          type != 'document' &&
          type != 'live_location') {
        continue;
      }

      final params = Map<String, dynamic>.from(paramsRaw);

      try {
        final ResponseModel res =
            await ChatViewRepo().sendMessageToUser(params);
        if (!res.isSuccess) break; // Stop on failure; retry next tick.

        final data = res.response?.data;
        if (data == null) break;

        Messages? serverMessage;
        try {
          serverMessage = Messages.fromJson(data['data']);
        } catch (_) {
          serverMessage = null;
        }

        if (serverMessage != null) {
          await LocalStorageHelper().replacePendingWithServerMessage(
              conversationId, tempId, serverMessage);
          _swapInLiveController(conversationId, tempId, serverMessage);
        } else {
          // Fallback: at least clear pending flag so we don't retry forever.
          await LocalStorageHelper()
              .markMessageAsSent(conversationId, tempId);
        }
      } catch (e) {
        debugPrint(
            '[PendingMessageDrainer] send failed for $tempId in $conversationId: $e');
        break;
      }
    }
  }

  /// If the user happens to have the conversation open, replace the pending
  /// bubble with the server message in-place so the status flips live.
  void _swapInLiveController(
      String conversationId, String tempId, Messages serverMessage) {
    if (!Get.isRegistered<ChatViewController>()) return;
    try {
      final ctrl = Get.find<ChatViewController>();
      final list = ctrl.getListOfMessageData;
      if (list == null) return;
      final idx = list.indexWhere((m) => m.id == tempId);
      if (idx >= 0) {
        list[idx] = serverMessage;
      } else {
        final alreadyExists = serverMessage.id != null &&
            list.any((m) => m.id == serverMessage.id);
        if (!alreadyExists) list.add(serverMessage);
      }
      ctrl.getListOfMessageResponse.value = ApiResponse.complete(list);
    } catch (_) {}
  }
}

