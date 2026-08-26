import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/auth/model/call_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The outgoing call from the moment Call is tapped until it either becomes a
/// real call or dies — currently, dies busy.
///
/// ## Why it goes up at t = 0
///
/// Every call site used to `await initiateCall()` and only navigate on success,
/// so a busy callee produced no screen at all: the user tapped Call, waited,
/// and got a snackbar over the chat they were already looking at. A busy line is
/// a call OUTCOME, not a request failure (backend spec rev 3 §7), and it is owed
/// a call screen the way a phone gives one.
///
/// So [CallController.initiateCall] pushes this BEFORE the network request and
/// navigation left the call sites entirely. On success it is replaced by the
/// real call screen; on a busy 409 it stays and turns into the outcome.
///
/// ## Why it is not the live call screen
///
/// The obvious move is to reuse `/CallRoomScreen`. That screen reads
/// `callStatus` throughout, so putting it up before the call exists means faking
/// `CallStatus.outgoing` — which makes [CallController.isCallLive] true, and a
/// live call is exactly what makes the next INCOMING call auto-decline as busy.
/// Turning "placing a call" into a state that rejects other people's calls is
/// not a trade worth making to reuse a widget tree. This owns its own tree and
/// touches no call state.
///
/// ## The 700 ms dwell, measured from the tap
///
/// A 409 can come back in 200 ms. Landing straight on "on another call" makes
/// the screen flash and read as a crash. It holds "Calling…" until [_dwell] has
/// passed **since this screen opened**, which is the moment the user tapped —
/// so the hold is 700 ms total, not 700 ms after whatever the network took.
///
/// Auto-dismisses [_lingerAfterOutcome] later, unless the user has touched the
/// screen: someone reaching for "Call again" must not have it pulled away.
class CallBusyScreen extends StatefulWidget {
  const CallBusyScreen({
    super.key,
    required this.peerName,
    required this.peerImage,
    this.otherUserId,
    this.conversationId,
    this.callType = CallType.audio,
  });

  final String peerName;
  final String peerImage;

  /// Carried so "Call again" can re-place the same call.
  final String? otherUserId;
  final String? conversationId;
  final CallType callType;

  /// How long "Calling…" holds, from the tap, before an outcome may replace it.
  static const Duration _dwell = Duration(milliseconds: 700);

  /// How long the outcome stays before the screen closes itself.
  static const Duration _lingerAfterOutcome = Duration(seconds: 2);

  @override
  State<CallBusyScreen> createState() => _CallBusyScreenState();
}

class _CallBusyScreenState extends State<CallBusyScreen> {
  final CallController _controller = Get.find<CallController>();

  /// The busy tone. Same asset the outgoing ring-back uses — we have no
  /// dedicated busy tone, and a familiar call sound beats silence or a wrong
  /// one. Stopped by [_lingerAfterOutcome], so it plays for the life of the
  /// outcome and no longer.
  final AudioPlayer _tonePlayer = AudioPlayer();

  Worker? _ringingWorker;
  Timer? _dwellTimer;
  Timer? _dismissTimer;

  /// Set once an outcome has actually been rendered — the gate for the actions
  /// and the auto-dismiss.
  bool _outcomeShown = false;
  bool _userTouched = false;

  /// Held so an outcome that arrives before [_dwell] is shown WHEN the dwell
  /// ends rather than being dropped.
  CallRingingState? _pendingOutcome;
  bool _dwellElapsed = false;

  @override
  void initState() {
    super.initState();

    _dwellTimer = Timer(CallBusyScreen._dwell, () {
      if (!mounted) return;
      _dwellElapsed = true;
      final pending = _pendingOutcome;
      if (pending != null) _showOutcome(pending);
    });

    // The controller is the only thing that knows how the attempt went.
    // `markRingingFailedLocally` sets this on a 409, and a real `call:ringing`
    // drives it once the call is live.
    _ringingWorker = ever<CallRingingState>(_controller.ringingState, (state) {
      if (!mounted || !state.isTerminal) return;
      if (_dwellElapsed) {
        _showOutcome(state);
      } else {
        _pendingOutcome = state;
      }
    });
  }

  @override
  void dispose() {
    _ringingWorker?.dispose();
    _dwellTimer?.cancel();
    _dismissTimer?.cancel();
    _tonePlayer.stop();
    _tonePlayer.dispose();
    super.dispose();
  }

  void _showOutcome(CallRingingState state) {
    if (_outcomeShown) return;
    setState(() => _outcomeShown = true);

    // No vibration, deliberately: the user is holding the phone and looking
    // straight at it. Busy is a normal outcome, not an alarm.
    try {
      _tonePlayer.play(AssetSource('sound/old_phone_ring.mp3'));
    } catch (_) {}

    _dismissTimer = Timer(CallBusyScreen._lingerAfterOutcome, () {
      if (!mounted) return;
      _tonePlayer.stop();
      if (_userTouched) return;
      Get.back();
    });
  }

  /// Any touch cancels the auto-dismiss — the user is reading or reaching for
  /// one of the actions, and closing under their thumb is worse than lingering.
  void _holdOpen() {
    if (_userTouched) return;
    _userTouched = true;
    _dismissTimer?.cancel();
    _tonePlayer.stop();
  }

  String get _name =>
      widget.peerName.trim().isEmpty ? '' : widget.peerName.trim();

  /// The status line. Uses the name when we have one — "Anjali is on another
  /// call" — and falls back to the neutral label otherwise.
  String get _statusText {
    if (!_outcomeShown) return 'Calling…';
    final state = _controller.ringingState.value;
    if (state == CallRingingState.busy) {
      return _name.isEmpty
          ? CallRingingState.busy.label
          : '$_name is on another call';
    }
    return state.label;
  }

  Future<void> _callAgain() async {
    _holdOpen();
    Get.back();
    // A second busy simply replays this screen — initiateCall opens it again.
    await _controller.initiateCall(
      type: widget.callType,
      otherUserId: widget.otherUserId,
      existingConversationId: widget.conversationId,
      userName: widget.peerName,
      userImage: widget.peerImage,
    );
  }

  /// Drops back to the conversation, which is usually what the caller actually
  /// wants once they know the line is busy.
  void _message() {
    _holdOpen();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _holdOpen(),
      onPanDown: (_) => _holdOpen(),
      child: Scaffold(
        // Neutral surface. NOT red, and no warning icon — busy is an ordinary
        // outcome and dressing it as an error blames someone for being on a
        // call.
        backgroundColor: const Color(0xFF10131A),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              _avatar(),
              const SizedBox(height: 20),
              CustomText(
                _name.isEmpty ? 'Unknown' : _name,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              // Cross-fade rather than a swap: the line changes meaning, and a
              // hard cut at 700 ms is the flash the dwell exists to avoid.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Row(
                  key: ValueKey(_outcomeShown),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_outcomeShown) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: CustomText(
                        _statusText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.62),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              // The actions appear WITH the outcome, not before it — offering
              // "Call again" while the screen still says "Calling…" would be
              // nonsense.
              AnimatedOpacity(
                opacity: _outcomeShown ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                child: IgnorePointer(
                  ignoring: !_outcomeShown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _action(
                          icon: Icons.call,
                          label: 'Call again',
                          onTap: _callAgain,
                        ),
                        _action(
                          icon: Icons.chat_bubble_outline,
                          label: 'Message',
                          onTap: _message,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              IconButton(
                onPressed: () {
                  _holdOpen();
                  Get.back();
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    const size = 108.0;
    final url = widget.peerImage.trim();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? Container(
                color: Colors.white.withValues(alpha: 0.10),
                alignment: Alignment.center,
                child: CustomText(
                  _name.isEmpty ? '?' : _name.characters.first.toUpperCase(),
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Icon(icon, color: AppColors.white, size: 24),
            ),
            const SizedBox(height: 10),
            CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }
}
