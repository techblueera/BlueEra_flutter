import 'dart:async';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Snap-search scan loader — framed AI-scan GIF inside a brand-tinted
/// panel with a breathing halo, a cycling helper-subtitle, and an
/// indeterminate brand-blue progress strip. Used wherever the merchant
/// is waiting for an AI image-recognition API to return (grocery, food,
/// product snap search).
///
/// The defaults are tuned for the snap-search flow; pass [title] and
/// [phrases] to retune the copy for a different domain.
class SnapScanLoader extends StatefulWidget {
  /// Title text rendered between the GIF and the rotating phrases.
  final String title;

  /// Helper-subtitle phrases cycled in order, one shown every
  /// [phraseInterval]. The list is treated as a loop.
  final List<String> phrases;

  /// How long each phrase stays on-screen before cross-fading.
  final Duration phraseInterval;

  /// Path to the GIF asset that sits inside the frame. Defaults to the
  /// existing grocery scan GIF that all three callers already ship.
  final String gifAsset;

  const SnapScanLoader({
    super.key,
    this.title = 'Scanning your snapshot…',
    this.phrases = const [
      'Detecting items',
      'Matching our catalog',
      'Reading labels & sizes',
      'Almost there',
    ],
    this.phraseInterval = const Duration(milliseconds: 1600),
    this.gifAsset = 'assets/images/grocery_loading_indicator.gif',
  });

  @override
  State<SnapScanLoader> createState() => _SnapScanLoaderState();
}

class _SnapScanLoaderState extends State<SnapScanLoader>
    with TickerProviderStateMixin {
  // Halo behind the GIF — slow breathing pulse signals "alive,
  // working" without competing with the GIF's own motion.
  late final AnimationController _halo;
  // Indeterminate progress strip — separate controller, faster
  // sweep so the eye reads it as a different cue from the halo.
  late final AnimationController _strip;

  int _phraseIndex = 0;
  Timer? _phraseTimer;

  @override
  void initState() {
    super.initState();
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _strip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    if (widget.phrases.length > 1) {
      _phraseTimer = Timer.periodic(widget.phraseInterval, (_) {
        if (!mounted) return;
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % widget.phrases.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _halo.dispose();
    _strip.dispose();
    _phraseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size20,
        vertical: SizeConfig.size24,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        // Whisper of brand color over white — seats the GIF without
        // letting the panel compete with it.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGifWithHalo(),
          SizedBox(height: SizeConfig.size18),
          CustomText(
            widget.title,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            letterSpacing: -0.2,
          ),
          SizedBox(height: SizeConfig.size6),
          // Cross-fade between phrases so the panel keeps moving but
          // doesn't strobe. ValueKey on the inner widget so
          // AnimatedSwitcher actually swaps it out.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            child: CustomText(
              widget.phrases.isEmpty ? '' : widget.phrases[_phraseIndex],
              key: ValueKey(_phraseIndex),
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              height: 1.4,
            ),
          ),
          SizedBox(height: SizeConfig.size20),
          _buildProgressStrip(),
        ],
      ),
    );
  }

  /// Centered GIF with a soft radial halo behind it. The halo pulses
  /// slowly to suggest "still working" — visible mostly in the corners
  /// where the GIF doesn't paint.
  Widget _buildGifWithHalo() {
    return AnimatedBuilder(
      animation: _halo,
      builder: (_, __) {
        final t = _halo.value; // 0..1
        final haloScale = 1.0 + 0.18 * t;
        final haloAlpha = (0.18 - 0.12 * t).clamp(0.0, 1.0);
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo — radial brand glow that breathes.
              Transform.scale(
                scale: haloScale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryColor.withValues(alpha: haloAlpha),
                        AppColors.primaryColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
              ),
              // GIF frame — rounded square with a subtle inner border
              // and primary-tinted backdrop so the asset reads as
              // "framed" rather than full-bleed.
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.22),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  widget.gifAsset,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Indeterminate progress strip — a short brand-blue band sweeps
  /// across a soft brand-tinted track. Less aggressive than the OS
  /// indeterminate bar and matches the panel's palette.
  Widget _buildProgressStrip() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _strip,
          builder: (_, __) {
            return CustomPaint(
              painter: _ScanStripPainter(
                progress: _strip.value,
                track: AppColors.primaryColor.withValues(alpha: 0.10),
                band: AppColors.primaryColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScanStripPainter extends CustomPainter {
  final double progress; // 0..1
  final Color track;
  final Color band;

  _ScanStripPainter({
    required this.progress,
    required this.track,
    required this.band,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Track
    final trackPaint = Paint()..color = track;
    canvas.drawRect(Offset.zero & size, trackPaint);

    // Band — width is 35% of track, sweeps from -bandWidth → width.
    final bandWidth = size.width * 0.35;
    final totalTravel = size.width + bandWidth;
    final dx = -bandWidth + totalTravel * progress;

    // Soft gradient band so the leading/trailing edges fade into the
    // track instead of cutting hard.
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        band.withValues(alpha: 0.0),
        band,
        band.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final rect = Rect.fromLTWH(dx, 0, bandWidth, size.height);
    final bandPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, bandPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanStripPainter old) =>
      old.progress != progress || old.track != track || old.band != band;
}
