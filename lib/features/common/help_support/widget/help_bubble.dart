import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/help_support/controller/help_support_controller.dart';
import 'package:BlueEra/features/common/help_support/model/help_question.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Floating help bubble pinned to the bottom-right of **Discover only**.
///
/// Collapsed it is a glowing blue circle with a pulsing "Need help?" hint.
/// Tapping it either re-opens the user's existing support thread or expands
/// into a panel of ready-made questions (tailored server-side to their account
/// type / category, bilingual) plus a free-text field. Sending posts the
/// question as the thread's first message and lands the user on the app's
/// normal chat screen, where the BlueEra team replies over the same socket as
/// any other conversation.
///
/// Mount it inside Discover's own [Stack], never app-wide — the guide is
/// explicit that this is a Home/Discovery affordance, and a globally mounted
/// bubble would sit over every chat, camera and map screen in the app.
/// See lib/docs/HELP_WIDGET_FLUTTER_GUIDE.md.
class HelpBubble extends StatefulWidget {
  const HelpBubble({super.key, this.bottom, this.right});

  /// Insets from the bottom-right. Defaults clear the bottom navigation bar,
  /// which the Discover feed scrolls under.
  final double? bottom;
  final double? right;

  @override
  State<HelpBubble> createState() => _HelpBubbleState();
}

class _HelpBubbleState extends State<HelpBubble>
    with SingleTickerProviderStateMixin {
  final HelpSupportController _controller =
      getOrPut(() => HelpSupportController());

  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  bool _expanded = false;

  /// Drives the hint chip in and out every few seconds. A permanently visible
  /// label would just be chrome; the point of the pulse is to catch the eye of
  /// someone who is stuck without competing with the feed the rest of the time.
  bool _showHint = true;
  Timer? _hintTimer;

  /// Halo pulse under the collapsed circle.
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _hintTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted && !_expanded) setState(() => _showHint = !_showHint);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _glow.dispose();
    _textCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  bool get _isHindi => _controller.languageCode == 'hi';

  Future<void> _onTapBubble() async {
    // Been here before → straight back into the same thread, no questions.
    final existing = _controller.existingConversationId.value;
    if (existing != null && existing.isNotEmpty) {
      await _controller.openSupportChat(existing);
      return;
    }
    // A failed prefetch retries here rather than opening an empty panel.
    if (_controller.questions.isEmpty) await _controller.prefetch();
    if (!mounted) return;
    setState(() => _expanded = true);
  }

  void _collapse() {
    _textFocus.unfocus();
    setState(() => _expanded = false);
  }

  Future<void> _send(String text, {String? questionId}) async {
    final opened = await _controller.sendInquiry(text, questionId: questionId);
    if (!mounted || !opened) return;
    // Only clear on success — a failed send keeps what the user typed.
    _textCtrl.clear();
    _collapse();
  }

  void _onQuestionTap(HelpQuestion q) {
    if (q.isOther) {
      // "Other inquiry" isn't a question, it's a prompt to write one.
      _textFocus.requestFocus();
      return;
    }
    _send(q.label(_controller.languageCode), questionId: q.id);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: widget.right ?? SizeConfig.size16,
      bottom: widget.bottom ?? (kBottomNavigationBarHeight + SizeConfig.size24),
      child: Obx(() {
        // Nothing to offer and no thread to reopen — stay out of the way
        // entirely rather than opening an empty panel.
        final hasSomething = _controller.questions.isNotEmpty ||
            (_controller.existingConversationId.value?.isNotEmpty ?? false);
        if (!hasSomething) return const SizedBox.shrink();
        return _expanded ? _panel() : _collapsed();
      }),
    );
  }

  // ─────────────────────────────────────────────────────────── collapsed

  Widget _collapsed() {
    return GestureDetector(
      onTap: _onTapBubble,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            opacity: _showHint ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              margin: EdgeInsets.only(right: SizeConfig.size8),
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size10,
                vertical: SizeConfig.size6,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F101828),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CustomText(
                _isHindi ? 'Koi dikkat? Help chahiye' : 'Need help?',
                fontSize: SizeConfig.small11,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _glow,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_glow.value);
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor
                          .withValues(alpha: 0.30 + (0.35 * t)),
                      blurRadius: 12 + (10 * t),
                      spreadRadius: 1 + (3 * t),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────── expanded

  Widget _panel() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29101828),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    _isHindi
                        ? 'Hum aapki kaise madad karein?'
                        : 'How can we help you?',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                  ),
                ),
                InkWell(
                  onTap: _collapse,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.secondaryTextColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size8),
            // The list is short and server-capped (4 tailored + "Other"), so it
            // is laid out inline; bounded anyway so an unexpectedly long reply
            // scrolls inside the panel instead of overflowing the screen.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final q in _controller.questions) _questionRow(q),
                  ],
                ),
              ),
            ),
            Divider(height: SizeConfig.size20, color: Color(0xFFE0E0E0)),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _questionRow(HelpQuestion q) {
    return InkWell(
      onTap: () => _onQuestionTap(q),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size8,
          horizontal: SizeConfig.size4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: CustomText(
                q.label(_controller.languageCode),
                fontSize: SizeConfig.small,
                fontWeight: q.isOther ? FontWeight.w600 : FontWeight.w500,
                color: q.isOther
                    ? AppColors.primaryColor
                    : AppColors.mainTextColor,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            focusNode: _textFocus,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (v) => _send(v),
            style: TextStyle(fontSize: SizeConfig.small),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: _isHindi
                  ? 'Apna sawaal likhein…'
                  : 'Type your question…',
              hintStyle: TextStyle(
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        Obx(() {
          if (_controller.isSending.value) {
            return const SizedBox(
              width: 34,
              height: 34,
              child: Padding(
                padding: EdgeInsets.all(7),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return InkWell(
            onTap: () => _send(_textCtrl.text),
            customBorder: const CircleBorder(),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 17),
            ),
          );
        }),
      ],
    );
  }
}
