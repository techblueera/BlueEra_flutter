import 'dart:math';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/joining_bounce/model/joining_bounce_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/repo/joining_bounce_repo.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Congrats! You have won a scratch card" claim popup. Shown once per app
/// launch when the profile API's `joining_bounce.show_card` is true.
///
/// The reward stays hidden behind a blue scratch surface — the user must
/// scratch it open. Only then does the amount reveal (with a burst of
/// confetti) and the "Claim Bonus" button become active. Claiming credits the
/// bonus to the wallet via the joining-bounce API.
class ClaimBonusDialog extends StatefulWidget {
  final JoiningBounce bounce;

  const ClaimBonusDialog({super.key, required this.bounce});

  @override
  State<ClaimBonusDialog> createState() => _ClaimBonusDialogState();
}

class _ClaimBonusDialogState extends State<ClaimBonusDialog> {
  final JoiningBounceRepo _repo = JoiningBounceRepo();
  bool _claiming = false;

  /// True once the user has scratched enough of the card to reveal the reward.
  /// Gates the confetti burst and the Claim button.
  bool _revealed = false;

  /// Terms & Conditions accepted — required (with [_revealed]) before claiming.
  bool _agreed = false;

  void _onRevealed() {
    if (_revealed) return;
    setState(() => _revealed = true);
  }

  Future<void> _onClaim() async {
    if (_claiming || !_revealed) return;
    if (!_agreed) {
      commonSnackBar(message: 'Please agree to the Terms & Conditions first.');
      return;
    }
    // `tag_id` is the only required field for /createclaim; without it the
    // backend can't resolve the plan.
    final tagId = widget.bounce.tagId;
    if (tagId == null || tagId.isEmpty) {
      commonSnackBar(
          message: 'Bonus details are missing. Please try again later.');
      return;
    }
    setState(() => _claiming = true);
    try {
      // POST /joining-bounce/createclaim { tag_id, account_type? }.
      // account_type is optional (resolved from the JWT) — sent when known.
      final res = await _repo.createClaim(
        tagId: tagId,
        accountType: widget.bounce.accountType,
      );
      if (res.isSuccess) {
        final serverMsg = res.message?.toString();
        commonSnackBar(
            message: (serverMsg != null && serverMsg.isNotEmpty)
                ? serverMsg
                : 'Joining bonus activated 🎉');
        if (mounted) Navigator.of(context).maybePop();
      } else {
        commonSnackBar(
            message: res.message ?? 'Could not claim the bonus right now.');
      }
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _openTnc() async {
    final uri = Uri.tryParse(tncLink);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    customBorder: const CircleBorder(),
                    child: Icon(Icons.close_rounded,
                        size: 20, color: AppColors.secondaryTextColor),
                  ),
                ),
                CustomText(
                  'Congrats!',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 4),
                CustomText(
                  'You have won a scratch card',
                  fontSize: 14,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 16),

                // ── Scratch card: reward hidden behind a scratchable cover ──
                // Fixed height so the card is the SAME size before and after
                // scratching. The revealed surface is white with a primary
                // border (shown once the cover is scratched away).
                _ScratchCard(
                  revealed: _revealed,
                  onRevealed: _onRevealed,
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 1.4,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    child: _revealedReward(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── T&C agreement (required before claiming) ──────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreed,
                        activeColor: AppColors.primaryColor,
                        checkColor: AppColors.white,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                          ),
                          children: [
                            const TextSpan(text: 'Agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _openTnc,
                            ),
                            const TextSpan(text: ' before claiming.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Active only once the card is scratched AND the T&C is agreed.
                CustomBtn(
                  width: double.infinity,
                  height: SizeConfig.size40,
                  radius: 10,
                  isValidate: _revealed && _agreed,
                  bgColor: (_revealed && _agreed)
                      ? AppColors.primaryColor
                      : AppColors.whiteF3,
                  textColor: (_revealed && _agreed)
                      ? AppColors.white
                      : AppColors.grey9B,
                  isLoading: _claiming,
                  title: 'Claim Bonus',
                  onTap: (_revealed && _agreed) ? _onClaim : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The reward hidden under the scratch surface — amount + congrats copy.
  Widget _revealedReward() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DashedBorderContainer(
          borderRadius: 14,
          borderColor: AppColors.primaryColor.withValues(alpha: 0.5),
          strokeWidth: 1.4,
          dashLength: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            child: CustomText(
              '₹${widget.bounce.bonusInr}',
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: AppColors.mainTextColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        CustomText(
          "Yay! You've won",
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 8),
        CustomText(
          'This will be credited to your wallet. You can use it at '
          'the time of order payment.',
          fontSize: 14,
          color: AppColors.secondaryTextColor,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Guest variant of the scratch-card popup.
///
/// A guest can scratch the card, but the reward amount is NEVER exposed — the
/// surface under the cover is only a "sign up to claim" teaser. Once they've
/// scratched ~30%, the **Create Profile** CTA activates, nudging them to sign
/// up (where the real, claimable card lives). Shown instead of
/// [ClaimBonusDialog] when [isGuestUser] is true.
class GuestClaimBonusDialog extends StatefulWidget {
  const GuestClaimBonusDialog({super.key});

  @override
  State<GuestClaimBonusDialog> createState() => _GuestClaimBonusDialogState();
}

class _GuestClaimBonusDialogState extends State<GuestClaimBonusDialog> {
  /// True once the guest has scratched enough to enable the Create Profile CTA.
  bool _scratchedEnough = false;

  void _onScratched() {
    if (_scratchedEnough) return;
    setState(() => _scratchedEnough = true);
  }

  void _onCreateProfile() {
    Navigator.of(context).maybePop();
    createProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: Icon(Icons.close_rounded,
                    size: 20, color: AppColors.secondaryTextColor),
              ),
            ),
            CustomText(
              'Congrats!',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
            const SizedBox(height: 4),
            CustomText(
              'You have won a scratch card',
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
            const SizedBox(height: 16),

            // Scratch card — `revealed: false` always, so the cover never fades
            // and the amount is never exposed. Scratching only fires the
            // threshold callback; the surface beneath is a neutral teaser.
            _ScratchCard(
              revealed: false,
              threshold: 0.3,
              onRevealed: _onScratched,
              child: Container(
                height: 250,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryColor, width: 1.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard_rounded,
                        size: 48, color: AppColors.primaryColor),
                    const SizedBox(height: 12),
                    CustomText(
                      'Sign up to reveal\n& claim your reward',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            CustomText(
              _scratchedEnough
                  ? 'Create your profile to claim this reward.'
                  : 'Scratch the card to continue.',
              fontSize: 12,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Disabled until the guest has scratched ~30% of the card.
            CustomBtn(
              width: double.infinity,
              height: SizeConfig.size40,
              radius: 10,
              isValidate: _scratchedEnough,
              bgColor:
                  _scratchedEnough ? AppColors.primaryColor : AppColors.whiteF3,
              textColor: _scratchedEnough ? AppColors.white : AppColors.grey9B,
              title: 'Create Profile',
              onTap: _scratchedEnough ? _onCreateProfile : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Scratch card
// ─────────────────────────────────────────────────────────────────────────

/// Lays [child] (the reward) under a blue scratchable cover. As the user drags
/// across it, circular holes are punched into the cover (via [BlendMode.clear])
/// revealing the child. Once ~40% is scratched, [onRevealed] fires and the
/// remaining cover fades away. Pass [revealed] back so the cover stays gone
/// after the parent rebuilds.
class _ScratchCard extends StatefulWidget {
  final Widget child;

  /// Fires once the scratched area crosses [threshold]. The parent decides what
  /// happens (reveal the reward, or — for guests — just enable a CTA).
  final VoidCallback onRevealed;

  /// When true the cover fades away (full reveal). Parent-controlled, so a guest
  /// card can keep the cover on screen while still reacting to [onRevealed].
  final bool revealed;

  /// Fraction of the card that must be scratched before [onRevealed] fires.
  final double threshold;

  const _ScratchCard({
    required this.child,
    required this.onRevealed,
    required this.revealed,
    this.threshold = 0.4,
  });

  @override
  State<_ScratchCard> createState() => _ScratchCardState();
}

class _ScratchCardState extends State<_ScratchCard> {
  /// Scratch path — `null` marks a break between separate drags.
  final List<Offset?> _points = [];

  /// Coarse grid of touched cells, used to estimate the scratched fraction.
  final Set<int> _cells = {};
  static const int _cols = 14;
  static const int _rows = 9;

  Size _size = Size.zero;

  void _addPoint(Offset p) {
    if (widget.revealed) return;
    _points.add(p);
    if (_size.width > 0 && _size.height > 0) {
      final cx = (p.dx / _size.width * _cols).floor().clamp(0, _cols - 1);
      final cy = (p.dy / _size.height * _rows).floor().clamp(0, _rows - 1);
      _cells.add(cy * _cols + cx);
    }
    setState(() {});
    if (_cells.length >= (_cols * _rows * widget.threshold)) {
      widget.onRevealed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          widget.child,
          // Confetti — clipped to the card (so it stays inside the primary
          // border) and falling from the card's top once revealed.
          if (widget.revealed)
            const Positioned.fill(
              child: IgnorePointer(child: _Confetti()),
            ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: widget.revealed,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 450),
                opacity: widget.revealed ? 0 : 1,
                child: LayoutBuilder(
                  builder: (context, c) {
                    _size = Size(c.maxWidth, c.maxHeight);
                    return GestureDetector(
                      onPanStart: (d) {
                        _points.add(null);
                        _addPoint(d.localPosition);
                      },
                      onPanUpdate: (d) => _addPoint(d.localPosition),
                      onTapDown: (d) => _addPoint(d.localPosition),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _ScratchCoverPainter(points: List.of(_points)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the blue scratch cover (gradient + faint coin pattern + a gift badge)
/// and erases circular holes along [points] so the reward shows through.
class _ScratchCoverPainter extends CustomPainter {
  final List<Offset?> points;
  static const double brush = 22;

  _ScratchCoverPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Isolate the cover in its own layer so BlendMode.clear erases only the
    // cover (revealing the child below) instead of punching through to white.
    canvas.saveLayer(rect, Paint());
    _paintCover(canvas, size);

    final clear = Paint()
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = brush * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true;

    Offset? prev;
    for (final p in points) {
      if (p == null) {
        prev = null;
        continue;
      }
      canvas.drawCircle(p, brush, dot);
      if (prev != null) canvas.drawLine(prev, p, clear);
      prev = p;
    }
    canvas.restore();
  }

  void _paintCover(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D7BF0), Color(0xFF1A66D6)],
        ).createShader(rect),
    );

    // Faint coin pattern.
    final coin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.10);
    const step = 52.0;
    for (double y = 24; y < size.height; y += step) {
      for (double x = 24; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 11, coin);
      }
    }

    // Centre gift badge — dark disc + a simple white gift drawn with strokes
    // (no icon font, so it survives release icon tree-shaking).
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, 42, Paint()..color = const Color(0xFF0E3E7E));
    final w = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Box body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, 8), width: 38, height: 26),
        const Radius.circular(4),
      ),
      w,
    );
    // Lid.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, -8), width: 46, height: 13),
        const Radius.circular(4),
      ),
      w,
    );
    // Ribbon.
    canvas.drawLine(c.translate(0, -14), c.translate(0, 21), w);
    // Bow.
    canvas.drawCircle(c.translate(-7, -18), 5, w);
    canvas.drawCircle(c.translate(7, -18), 5, w);
  }

  @override
  bool shouldRepaint(_ScratchCoverPainter old) =>
      old.points.length != points.length;
}

// ─────────────────────────────────────────────────────────────────────────
// Confetti
// ─────────────────────────────────────────────────────────────────────────

/// One-shot confetti burst that falls from the top — played once when the
/// scratch card is revealed.
class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    const colors = [
      Color(0xFFEF4444),
      Color(0xFF2D7BF0),
      Color(0xFF34C77B),
      Color(0xFFFFC93C),
      Color(0xFF8B5CF6),
      Color(0xFFFF7A00),
    ];
    // Falling burst — drop through and off the bottom.
    final falling = List.generate(55, (_) {
      return _Particle(
        x0: rnd.nextDouble(),
        drift: (rnd.nextDouble() - 0.5) * 0.5,
        delay: rnd.nextDouble() * 0.25,
        color: colors[rnd.nextInt(colors.length)],
        w: 4 + rnd.nextDouble() * 6,
        h: 7 + rnd.nextDouble() * 8,
        rot0: rnd.nextDouble() * pi * 2,
        rotSpeed: (rnd.nextDouble() - 0.5) * 5,
      );
    });
    // Resting sparkles — settle near the top and STAY after the burst ends,
    // spread across the width so a few bits sit on top for a nicer finish.
    final resting = List.generate(14, (i) {
      return _Particle(
        x0: (i + 0.5 + (rnd.nextDouble() - 0.5) * 0.6) / 14,
        drift: 0,
        delay: rnd.nextDouble() * 0.1,
        color: colors[rnd.nextInt(colors.length)],
        w: 5 + rnd.nextDouble() * 5,
        h: 8 + rnd.nextDouble() * 6,
        rot0: rnd.nextDouble() * pi * 2,
        rotSpeed: (rnd.nextDouble() - 0.5) * 1.2,
        resting: true,
        restY: 0.02 + rnd.nextDouble() * 0.10,
      );
    });
    _particles = [...falling, ...resting];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        // Keep painting after completion (value stays at 1.0) so the resting
        // sparkles remain sitting on top.
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  final double x0; // 0..1 start x
  final double drift; // horizontal drift over life
  final double delay; // 0..1 staggered start
  final Color color;
  final double w;
  final double h;
  final double rot0;
  final double rotSpeed;

  /// A "resting" particle settles near the top and STAYS after the burst, so a
  /// few sparkles remain sitting on top once the animation ends. A normal
  /// (falling) particle drops through and off the bottom.
  final bool resting;
  final double restY; // 0..1 target y for resting particles

  const _Particle({
    required this.x0,
    required this.drift,
    required this.delay,
    required this.color,
    required this.w,
    required this.h,
    required this.rot0,
    required this.rotSpeed,
    this.resting = false,
    this.restY = 0,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final double x, y, angle, opacity;
      if (p.resting) {
        // Drop from above to the rest position over the first ~40% of the
        // timeline, then hold there (stays at the end).
        final prog = ((t - p.delay) / 0.4).clamp(0.0, 1.0);
        final eased = Curves.easeOut.transform(prog);
        x = p.x0 * size.width;
        y = (-0.1 + (p.restY + 0.1) * eased) * size.height;
        angle = p.rot0 + p.rotSpeed * eased;
        opacity = 1.0;
      } else {
        final life = (t - p.delay) / (1 - p.delay);
        if (life <= 0 || life > 1) continue;
        x = (p.x0 + p.drift * life) * size.width;
        y = (-0.1 + 1.3 * life) * size.height;
        angle = p.rot0 + p.rotSpeed * life * pi * 2;
        opacity =
            (life < 0.8 ? 1.0 : (1 - (life - 0.8) / 0.2)).clamp(0.0, 1.0);
      }
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
