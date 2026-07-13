import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/auth/service/call_activity_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Live call ongoing" banner shown at the top of the Chat/Inquiry tabs while a
/// voice/video call is connected — mirroring the customer "Your Ongoing
/// Ride/Booking" card placement.
///
/// A connected call may run in Android's separate CallActivity engine, so the
/// reactive [CallController] state isn't reachable from the Connect screen's
/// isolate. Instead this reads the cross-isolate active-call record published by
/// [CallController.saveActiveCallSession] (the same source the in-chat
/// [OngoingCallMessageCard] uses) and polls it so the banner appears/disappears
/// as the call starts/ends. Tapping it re-enters the call room. The banner
/// collapses to nothing when there is no ongoing call.
class OngoingCallBanner extends StatefulWidget {
  const OngoingCallBanner({super.key});

  @override
  State<OngoingCallBanner> createState() => _OngoingCallBannerState();
}

class _OngoingCallBannerState extends State<OngoingCallBanner> {
  Timer? _timer;
  Map<String, dynamic>? _session; // active call record, or null when idle
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Tick every second to advance the displayed duration, re-polling the
    // cross-isolate record every few ticks to catch call start/end.
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
    if (!mounted) return;
    setState(() {
      _session = session;
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
    // Self-hide the moment the call ends, even before the next poll.
    if (_session == null) return const SizedBox.shrink();

    final isVideo = _session!['isVideo'] == true;
    final remoteName = (_session!['remoteName'] ?? '').toString();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size12, SizeConfig.size10, SizeConfig.size12, SizeConfig.size4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _enterCallRoom,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                  color: Colors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      'Live call ongoing',
                      fontSize: SizeConfig.size16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (remoteName.isNotEmpty) ...[
                          Flexible(
                            child: CustomText(
                              remoteName,
                              fontSize: SizeConfig.size13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          CustomText(
                            '  |  ',
                            fontSize: SizeConfig.size13,
                            color: AppColors.grayText,
                          ),
                        ],
                        CustomText(
                          _formattedDuration,
                          fontSize: SizeConfig.size13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                        CustomText(
                          '  ·  Tap to return',
                          fontSize: SizeConfig.size12,
                          color: AppColors.grayText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
