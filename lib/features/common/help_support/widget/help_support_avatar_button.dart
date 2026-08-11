import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/help_support/controller/help_support_controller.dart';
import 'package:BlueEra/features/common/help_support/widget/help_questions_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Customer-care entry point for the Discover header — a photo of a support
/// agent rather than an icon.
///
/// ## Why a face
///
/// An icon has to be decoded: a headset glyph could be audio settings, a
/// speech bubble could be comments. A person reads as "there is somebody on the
/// other end of this" before any label does, which is the whole proposition —
/// the button opens a real conversation with the BlueEra team, answered by
/// people over the same socket as any other chat. The headset badge sits on top
/// to name the role, so the photo isn't mistaken for the user's own profile.
///
/// Behaviour is identical to the floating [HelpBubble]: a returning user goes
/// straight back into their existing thread, everyone else gets the
/// server-tailored question list. The panel is the same widget
/// ([HelpQuestionsPanel]) — presented in a bottom sheet here, because a header
/// button has nothing to anchor a popover to.
class HelpSupportAvatarButton extends StatefulWidget {
  const HelpSupportAvatarButton({super.key, this.size = 44});

  /// Outer diameter, including the ring. Sized to sit level with the header's
  /// other circular chips by default.
  final double size;

  @override
  State<HelpSupportAvatarButton> createState() =>
      _HelpSupportAvatarButtonState();
}

class _HelpSupportAvatarButtonState extends State<HelpSupportAvatarButton>
    with SingleTickerProviderStateMixin {
  final HelpSupportController _controller =
      getOrPut(() => HelpSupportController());

  /// Halo pulse, carried over from the floating bubble — it is what stops a
  /// small avatar in a busy header reading as decoration.
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    // Been here before → straight back into the same thread, no questions.
    final existing = _controller.existingConversationId.value;
    if (existing != null && existing.isNotEmpty) {
      await _controller.openSupportChat(existing);
      return;
    }
    // A failed prefetch retries here rather than opening an empty sheet.
    if (_controller.questions.isEmpty) await _controller.prefetch();
    if (!mounted) return;
    _openSheet();
  }

  void _openSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          // Lifts the composer clear of the keyboard when the user taps
          // "Other inquiry" and starts typing.
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size16,
              SizeConfig.size10,
              SizeConfig.size16,
              SizeConfig.size16 + MediaQuery.of(sheetContext).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: EdgeInsets.only(bottom: SizeConfig.size12),
                  decoration: BoxDecoration(
                    color: AppColors.greyE5,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                HelpQuestionsPanel(
                  // The handle above already says "drag me down", so the panel
                  // drops its own close button here.
                  showCloseButton: false,
                  onClose: () => Navigator.of(sheetContext).maybePop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Nothing to offer and no thread to reopen — stay out of the way entirely
      // rather than opening an empty sheet. Same rule as the floating bubble.
      final hasSomething = _controller.questions.isNotEmpty ||
          (_controller.existingConversationId.value?.isNotEmpty ?? false);
      if (!hasSomething) return const SizedBox.shrink();

      return InkWell(
        onTap: _onTap,
        customBorder: const CircleBorder(),
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_glow.value);
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor
                        .withValues(alpha: 0.22 + (0.26 * t)),
                    blurRadius: 8 + (8 * t),
                    spreadRadius: 0.5 + (2 * t),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            // Clip.none: the headset badge deliberately overhangs the avatar's
            // circle, and a Stack clips to its own bounds by default.
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _avatar(),
                Positioned(right: -1, bottom: -1, child: _roleBadge()),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _avatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // A tint behind the cut-out PNG, so the agent sits on brand colour
        // rather than on whatever background the user picked.
        color: AppColors.primaryColor.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset(
          AppImageAssets.sampleGirlImage,
          fit: BoxFit.cover,
          // Top-aligned, NOT centred. The source is a waist-up shot with the
          // head in the upper third, so centring a circular crop on it frames
          // her torso and cuts the face off — the one part that has to be in
          // frame for this to read as a person at 44px.
          alignment: const Alignment(0, -0.72),
          errorBuilder: (_, __, ___) => Icon(
            Icons.support_agent_rounded,
            size: widget.size * 0.6,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  /// Small headset disc naming the role. Without it the photo is just a face,
  /// and a face in a header is read as "my account".
  Widget _roleBadge() {
    final d = widget.size * 0.42;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryColor,
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      child: Icon(
        Icons.headset_mic_rounded,
        size: d * 0.58,
        color: AppColors.white,
      ),
    );
  }
}
