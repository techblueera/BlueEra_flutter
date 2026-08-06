import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Live-photo lightbox, opened from a store's logo.
///
/// ## Why this is a [PageRoute] and not a bottom sheet
///
/// It used to be a `showModalBottomSheet`, and the [Hero] on the avatar could
/// never have animated into it: Flutter's `HeroController` only runs a flight
/// when BOTH the outgoing and incoming routes are `PageRoute`s, and a modal
/// sheet is a `PopupRoute`. A [PageRouteBuilder] with `opaque: false` gives the
/// same floating-over-the-list look while being a real PageRoute, so the logo
/// actually flies into the first photo.
class StoreLivePhotosViewer extends StatefulWidget {
  const StoreLivePhotosViewer({
    super.key,
    required this.images,
    required this.heroTag,
    required this.title,
    this.initialIndex = 0,
  });

  final List<String> images;

  /// Shared with the avatar that opened this. Only the page at [initialIndex]
  /// carries it — a PageView keeps neighbouring pages alive, and two live
  /// widgets sharing one tag is a Hero assertion, not a nicer animation.
  final String heroTag;
  final String title;
  final int initialIndex;

  /// Pushes the viewer. No-op when there is nothing to show, so callers don't
  /// each have to guard.
  static void open(
    BuildContext context, {
    required List<String> images,
    required String heroTag,
    required String title,
    int initialIndex = 0,
  }) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.88),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => StoreLivePhotosViewer(
          images: images,
          heroTag: heroTag,
          title: title,
          initialIndex: initialIndex,
        ),
        // The chrome fades; the photo itself arrives on the Hero flight, so
        // sliding the page as well would drag the image away from it.
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<StoreLivePhotosViewer> createState() =>
      _StoreLivePhotosViewerState();
}

class _StoreLivePhotosViewerState extends State<StoreLivePhotosViewer> {
  late final PageController _controller;
  late int _index;
  final Map<int, TransformationController> _transformers = {};
  TapDownDetails? _lastDoubleTap;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final t in _transformers.values) {
      t.dispose();
    }
    super.dispose();
  }

  TransformationController _transformerFor(int i) =>
      _transformers.putIfAbsent(i, TransformationController.new);

  void _toggleZoom(int i) {
    final t = _transformerFor(i);
    final details = _lastDoubleTap;
    if (t.value != Matrix4.identity()) {
      t.value = Matrix4.identity();
    } else if (details != null) {
      const scale = 2.5;
      final pos = details.localPosition;
      t.value = Matrix4.identity()
        ..translate(-pos.dx * (scale - 1), -pos.dy * (scale - 1))
        ..scale(scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent over the route barrier, so the list stays faintly visible
      // behind the photos and the lightbox reads as floating on it.
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _pages()),
            _dots(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              widget.title,
              fontSize: SizeConfig.medium,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: CustomText(
              '${_index + 1} / ${widget.images.length}',
              fontSize: SizeConfig.small,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pages() {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.images.length,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (_, i) {
        final image = ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: widget.images[i],
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.contain,
            ),
          ),
        );

        return GestureDetector(
          onDoubleTapDown: (d) => _lastDoubleTap = d,
          onDoubleTap: () => _toggleZoom(i),
          child: InteractiveViewer(
            transformationController: _transformerFor(i),
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                // Only the page the avatar flew into carries the tag — see the
                // note on [StoreLivePhotosViewer.heroTag].
                child: i == widget.initialIndex
                    ? Hero(tag: widget.heroTag, child: image)
                    : image,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dots() {
    if (widget.images.length < 2) return SizedBox(height: SizeConfig.size20);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.images.length, (i) {
          final active = i == _index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryColor
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}
