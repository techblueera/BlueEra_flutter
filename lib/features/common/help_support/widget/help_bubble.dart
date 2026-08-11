import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/help_support/controller/help_support_controller.dart';
import 'package:BlueEra/features/common/help_support/widget/help_questions_panel.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
    // Drops the keyboard too: the panel's composer lives inside the subtree
    // this tears down, so its focus node goes with it.
    FocusScope.of(context).unfocus();
    setState(() => _expanded = false);
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
              // The app's own chat glyph, not the Material bubble — tapping
              // this opens a real conversation with the BlueEra team, and it
              // should look like every other chat entry point in the app.
              child: Center(
                child: LocalAssets(
                  imagePath: AppIconAssets.chat,
                  height: 24,
                  width: 24,
                  imgColor: Colors.white,
                ),
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
        // Body shared with the header's customer-care button, so the two
        // entry points can't drift into two different support experiences.
        child: HelpQuestionsPanel(onClose: _collapse),
      ),
    );
  }
}
