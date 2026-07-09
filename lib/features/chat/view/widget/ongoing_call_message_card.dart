import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/call_controller.dart';
import '../../auth/service/call_activity_service.dart';

/// In-chat "Ongoing call" message. Rendered as a synthetic message
/// (`message_type == "callongoing"`) at the bottom of the thread while a
/// voice/video call for THIS conversation is live. It reads the cross-isolate
/// active-call record published by [CallController] (the call may be running in
/// Android's separate CallActivity engine, so we can't rely on reactive
/// controller state here) and ticks a local timer to show the running duration.
/// Tapping it re-enters the call room.
class OngoingCallMessageCard extends StatefulWidget {
  const OngoingCallMessageCard({
    super.key,
    required this.conversationId,
    this.userId,
  });

  final String conversationId;

  /// The conversation partner's user id. Used as a fallback match for the
  /// active-call record when its conversationId is empty (incoming calls don't
  /// always carry the conversation id on the receiver side).
  final String? userId;

  /// True when [session] belongs to this chat — matched by conversationId, or
  /// by the remote user id when the conversationId is missing/mismatched.
  static bool sessionMatches(
    Map<String, dynamic> session, {
    required String conversationId,
    String? userId,
  }) {
    final sessionCid = (session['conversationId'] ?? '').toString();
    final sessionUid = (session['remoteUserId'] ?? '').toString();
    if (conversationId.isNotEmpty && sessionCid == conversationId) return true;
    if ((userId ?? '').isNotEmpty && sessionUid == userId) return true;
    return false;
  }

  @override
  State<OngoingCallMessageCard> createState() => _OngoingCallMessageCardState();
}

class _OngoingCallMessageCardState extends State<OngoingCallMessageCard> {
  Timer? _timer;
  Map<String, dynamic>? _session; // active call record for THIS conversation
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Tick every second: recompute the displayed duration from the stored start
    // time, and re-poll the record every few ticks to catch call start/end.
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _recomputeElapsed();
      if (t.tick % 3 == 0) _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final session = await CallController.readActiveCallSession();
    final matches = session != null &&
        OngoingCallMessageCard.sessionMatches(
          session,
          conversationId: widget.conversationId,
          userId: widget.userId,
        );
    if (!mounted) return;
    setState(() {
      _session = matches ? session : null;
      _recomputeElapsedValue();
    });
  }

  void _recomputeElapsed() {
    if (_session == null) return;
    setState(_recomputeElapsedValue);
  }

  void _recomputeElapsedValue() {
    if (_session == null) {
      _elapsedSeconds = 0;
      return;
    }
    final startedAt = (_session!['startedAtMs'] as num?)?.toInt() ?? 0;
    final elapsed =
        ((DateTime.now().millisecondsSinceEpoch - startedAt) / 1000).floor();
    _elapsedSeconds = elapsed < 0 ? 0 : elapsed;
  }

  String get _formattedDuration {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _enterCallRoom() async {
    // Android non-fare calls run in the separate CallActivity task — bring it
    // back to the front. Fare-calls (Android) and all iOS calls run in the main
    // engine, so fall back to navigating to the in-app call room.
    if (Platform.isAndroid) {
      final brought = await CallActivityService.bringCallActivityToFront();
      if (brought) return;
    }
    if (Get.currentRoute != '/CallRoomScreen') {
      Get.toNamed('/CallRoomScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Self-hide the moment the call ends, even before the parent list rebuilds.
    if (_session == null) return const SizedBox.shrink();
    final isVideo = _session!['isVideo'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _enterCallRoom,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF128C7E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ongoing call',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_formattedDuration · Tap to return to call room',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
