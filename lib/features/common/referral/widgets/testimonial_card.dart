import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/post/message_post/feed_network_video_preview_widget.dart';
import 'package:BlueEra/features/common/referral/model/referral_testimonial_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Renders one testimonial. A testimonial carries EITHER a [video] OR
/// [images] (or neither): video → tappable poster that opens a full-screen
/// player; images → tappable preview that opens a full-screen viewer; then the
/// title + description below.
class TestimonialCard extends StatelessWidget {
  final ReferralTestimonial testimonial;
  final double? width;

  /// Taller media + more description lines in the full "All testimonials" list.
  final bool expanded;

  const TestimonialCard({
    super.key,
    required this.testimonial,
    this.width,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final t = testimonial;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFEEF1F8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.hasMedia) _media(context, t),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.title.trim().isNotEmpty) ...[
                  CustomText(
                    t.title,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: expanded ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size4),
                ],
                if (t.description.trim().isNotEmpty)
                  CustomText(
                    t.description,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    height: 1.4,
                    maxLines: expanded
                        ? (t.hasMedia ? 6 : 12)
                        : (t.hasMedia ? 2 : 6),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Media (video poster or image preview) ────────────────────────────
  Widget _media(BuildContext context, ReferralTestimonial t) {
    final h = expanded ? 180.0 : 120.0;

    if (t.hasVideo) {
      return GestureDetector(
        onTap: () =>
            Get.to(() => NetworkVideoPreviewScreen(videoUrl: t.video!)),
        child: SizedBox(
          height: h,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (t.poster != null)
                CachedNetworkImage(
                  imageUrl: t.poster!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _videoBg(),
                  errorWidget: (_, __, ___) => _videoBg(),
                )
              else
                _videoBg(),
              Container(color: Colors.black.withValues(alpha: 0.22)),
              const Center(
                child: Icon(Icons.play_circle_fill,
                    color: Colors.white, size: 48),
              ),
            ],
          ),
        ),
      );
    }

    // Image(s)
    return GestureDetector(
      onTap: () => _openImages(context, t.images, 0),
      child: SizedBox(
        height: h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: t.images.first,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.whiteE5),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.whiteE5,
                child: Icon(Icons.image_not_supported_outlined,
                    color: AppColors.secondaryTextColor),
              ),
            ),
            if (t.images.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: _pill(Icons.photo_library_rounded,
                    '1/${t.images.length}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _videoBg() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A2F3A), Color(0xFF11151C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  Widget _pill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            CustomText(text,
                fontSize: SizeConfig.extraSmall,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ],
        ),
      );

  void _openImages(BuildContext context, List<String> images, int initial) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _TestimonialImageViewer(images: images, initialIndex: initial),
      ),
    );
  }
}

/// Full-screen, swipeable, zoomable viewer for a testimonial's images.
class _TestimonialImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _TestimonialImageViewer(
      {required this.images, required this.initialIndex});

  @override
  State<_TestimonialImageViewer> createState() =>
      _TestimonialImageViewerState();
}

class _TestimonialImageViewerState extends State<_TestimonialImageViewer> {
  late final PageController _page =
      PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: CustomText(
          '${_current + 1} / ${widget.images.length}',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _page,
        onPageChanged: (i) => setState(() => _current = i),
        itemCount: widget.images.length,
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.contain,
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
