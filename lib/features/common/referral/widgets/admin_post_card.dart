import 'dart:io';
import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/model/admin_post_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Tiny in-process bus that tracks which [AdminPostCard] currently owns
/// playback. When one card starts playing, every other card listens to
/// this notifier and pauses itself — so only one video runs at a time
/// across the whole tab.
class _AdminPostPlaybackBus {
  static final ValueNotifier<String?> activeId = ValueNotifier<String?>(null);
}

/// Stops whichever [AdminPostCard] is currently playing across the
/// app. Call this from screens that are about to open a heavy
/// overlay (e.g. the Add-Link bottom sheet) — without this, the
/// background `VideoPlayer` keeps decoding frames and contends with
/// the main thread, which produces the "Skipped N frames" warnings
/// users see as paste lag.
void pauseAllAdminPostVideos() {
  _AdminPostPlaybackBus.activeId.value = null;
}

/// Shared file cache for generated video thumbnails — keyed by the
/// post id so re-mounting the same card (e.g. on tab switch) reuses
/// the already-computed thumb instead of running ffmpeg again.
final Map<String, File> _videoThumbCache = {};

/// Card used on the Overview / Tutorial / Post tabs to render one
/// admin post from `/earn-service/admin-posts`. The hero zone is a
/// swipeable [PageView] holding [video (if any), ...post.images], so
/// the same widget handles video-only, image-only, mixed and empty
/// posts with no extra branching at the call site. Title, description
/// and link sit underneath in an 8 px gutter.
class AdminPostCard extends StatefulWidget {
  final AdminPost post;
  const AdminPostCard({super.key, required this.post});

  @override
  State<AdminPostCard> createState() => _AdminPostCardState();
}

class _AdminPostCardState extends State<AdminPostCard> {
  VideoPlayerController? _videoCtrl;
  bool _initialising = false;
  File? _generatedThumb;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  // Initialised at declaration so the field is *always* readable from
  // build() — hot-reload can mount the state and run build() before
  // initState() has run, which used to throw a LateInitializationError
  // on `_pages`. initState overwrites this list with the real pages.
  List<_HeroPage> _pages = const [];

  bool get _hasVideo => widget.post.hasVideo;
  bool get _isExternal => widget.post.isExternalMedia;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
    _AdminPostPlaybackBus.activeId.addListener(_onActiveChanged);
    if (_hasVideo) {
      _generatedThumb = _videoThumbCache[widget.post.id];
      if (_generatedThumb == null) {
        _generateVideoThumb();
      }
    }
  }

  /// Hero pages — for native S3 videos: `[video, ...images]`. For
  /// external (Instagram / YouTube / Twitter) posts: a single
  /// `_HeroPage.external()` page that uses the metadata thumbnail and
  /// hands the tap off to `launchUrl`. For image-only posts: just the
  /// image list.
  List<_HeroPage> _buildPages() {
    final pages = <_HeroPage>[];
    if (_hasVideo) {
      pages.add(const _HeroPage.video());
    } else if (_isExternal) {
      pages.add(_HeroPage.external(widget.post.metadata?.thumbnail ?? ''));
    }
    for (final img in widget.post.images) {
      if (img.isNotEmpty) pages.add(_HeroPage.image(img));
    }
    return pages;
  }

  @override
  void dispose() {
    _AdminPostPlaybackBus.activeId.removeListener(_onActiveChanged);
    if (_AdminPostPlaybackBus.activeId.value == widget.post.id) {
      _AdminPostPlaybackBus.activeId.value = null;
    }
    _videoCtrl?.pause();
    _videoCtrl?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onActiveChanged() {
    final active = _AdminPostPlaybackBus.activeId.value;
    if (active != widget.post.id && (_videoCtrl?.value.isPlaying ?? false)) {
      _videoCtrl!.pause();
      if (mounted) setState(() {});
    }
  }

  Future<void> _generateVideoThumb() async {
    try {
      final dir = await getTemporaryDirectory();
      final thumb = await VideoThumbnail.thumbnailFile(
        video: widget.post.video!,
        thumbnailPath: dir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 360,
        quality: 65,
        timeMs: 1000,
      );
      final file = File(thumb.path);
      _videoThumbCache[widget.post.id] = file;
      if (mounted) setState(() => _generatedThumb = file);
    } catch (_) {
      // Network / codec failure — leave the slot blank, the gradient
      // placeholder will take over.
    }
  }

  Future<void> _ensureInitialised() async {
    if (_videoCtrl != null || _initialising || !_hasVideo) return;
    _initialising = true;
    try {
      final ctrl =
          VideoPlayerController.networkUrl(Uri.parse(widget.post.video!));
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.addListener(() {
        if (mounted) setState(() {});
      });
      _videoCtrl = ctrl;
      if (mounted) setState(() {});
    } catch (_) {
      // Network / codec failure — fall back to thumbnail / placeholder.
    } finally {
      _initialising = false;
    }
  }

  Future<void> _togglePlayback() async {
    final ctrl = _videoCtrl;
    if (ctrl == null) {
      await _ensureInitialised();
      final ready = _videoCtrl;
      if (ready != null) {
        _AdminPostPlaybackBus.activeId.value = widget.post.id;
        await ready.play();
        if (mounted) setState(() {});
      }
      return;
    }
    if (ctrl.value.isPlaying) {
      await ctrl.pause();
      if (_AdminPostPlaybackBus.activeId.value == widget.post.id) {
        _AdminPostPlaybackBus.activeId.value = null;
      }
    } else {
      _AdminPostPlaybackBus.activeId.value = widget.post.id;
      await ctrl.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _openLink() => _launch(widget.post.externalLink);

  /// Tap-target for the external-media play badge. Routes to the
  /// platform's native app (or browser) via `url_launcher` — same
  /// pattern X, LinkedIn etc. use for embedded reel previews.
  Future<void> _openExternal() => _launch(widget.post.externalLink);

  Future<void> _launch(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _onPageChanged(int i) {
    setState(() => _currentPage = i);
    // Swiping away from the video page should pause playback so the
    // sound doesn't keep going behind an image.
    final ctrl = _videoCtrl;
    if (ctrl != null && ctrl.value.isPlaying && !_pages[i].isVideo) {
      ctrl.pause();
      if (_AdminPostPlaybackBus.activeId.value == widget.post.id) {
        _AdminPostPlaybackBus.activeId.value = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Instagram's login wall frequently blocks the scrape, so an IG post
    // can land with no thumbnail/title/caption. Rather than render a card
    // that's just a gradient + the word "instagram", show a purposeful
    // fallback that explains why and gives the user a way forward. Other
    // platforms (and IG posts that DID resolve) keep the rich card.
    if (widget.post.isInstagram && !widget.post.hasResolvedMetadata) {
      return _buildUnresolvedInstagramCard();
    }
    return CustomFormCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.displayTitle.isNotEmpty) ...[
                  CustomText(
                    widget.post.displayTitle,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                ],
                if (widget.post.metadata?.uploader != null &&
                    widget.post.metadata!.uploader!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.account_circle_outlined,
                            size: 14,
                            color: AppColors.secondaryTextColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: CustomText(
                            widget.post.metadata!.uploader!,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                _statsRow(),
                if (widget.post.displayDescription.isNotEmpty)
                  CustomText(
                    widget.post.displayDescription,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    height: 1.4,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (widget.post.externalLink.isNotEmpty) ...[
                  SizedBox(height: SizeConfig.paddingXSL),
                  InkWell(
                    onTap: _openLink,
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            size: 12, color: AppColors.primaryColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: CustomText(
                            widget.post.externalLink,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Engagement metrics row — views / likes / comments from the scraped
  /// metadata. Each metric is shown only when present and > 0 (a platform that
  /// doesn't expose a count leaves it null/0, so we skip it). Hidden entirely
  /// when no metric is available.
  Widget _statsRow() {
    final m = widget.post.metadata;
    if (m == null) return const SizedBox.shrink();

    final chips = <Widget>[];
    void add(IconData icon, num? count) {
      final c = count?.toInt() ?? 0;
      if (c <= 0) return;
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 14));
      chips.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.secondaryTextColor),
          const SizedBox(width: 4),
          CustomText(
            _formatCount(c),
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ));
    }

    add(Icons.visibility_outlined, m.viewCount);
    add(Icons.favorite_border_rounded, m.likeCount);
    add(Icons.mode_comment_outlined, m.commentCount);

    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: chips),
    );
  }

  /// Compact count formatting: 1394 → "1.4K", 88303 → "88.3K", 2_000_000 → "2M".
  String _formatCount(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return '$n';
  }

  /// Fallback card for an Instagram post the backend couldn't resolve
  /// (login wall → no thumbnail/title/caption). Communicates *why* the
  /// preview is missing and *what the user can do* (open it in
  /// Instagram), instead of showing a near-empty rich card.
  Widget _buildUnresolvedInstagramCard() {
    const igBrand = Color(0xFFE1306C);
    return CustomFormCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero — branded placeholder, no network image to load.
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0x22833AB4),
                          Color(0x22E1306C),
                          Color(0x22FCAF45),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              color: igBrand, size: 24),
                        ),
                        const SizedBox(height: 8),
                        CustomText(
                          'Preview not available',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                      ],
                    ),
                  ),
                  // Instagram provider chip, top-left — consistent with
                  // the rich card so the source still reads at a glance.
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: igBrand.withValues(alpha: 0.55)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 12, color: igBrand),
                          SizedBox(width: 4),
                          Text(
                            'INSTAGRAM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: igBrand,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Instagram link',
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 6),
                // Why it happened — plain, non-alarming explanation.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.secondaryTextColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomText(
                        'Instagram limits link previews, so the thumbnail '
                        'and caption couldn’t be loaded. Your link is saved '
                        'and opens in the Instagram app.',
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                if (widget.post.externalLink.isNotEmpty) ...[
                  SizedBox(height: SizeConfig.paddingXSL),
                  // What to do — open the reel in Instagram.
                  InkWell(
                    onTap: _openLink,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: igBrand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: igBrand.withValues(alpha: 0.45)),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              size: 16, color: igBrand),
                          SizedBox(width: 8),
                          Text(
                            'Open in Instagram',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: igBrand,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hero zone — swipeable PageView of [video?, ...images]. When the
  /// post has neither, falls back to a gradient placeholder. Page dots
  /// + page count badge appear when there's more than one page.
  Widget _buildHero() {
    return VisibilityDetector(
      key: ValueKey('admin_post_hero_${widget.post.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 0.4 &&
            (_videoCtrl?.value.isPlaying ?? false)) {
          _videoCtrl!.pause();
          if (_AdminPostPlaybackBus.activeId.value == widget.post.id) {
            _AdminPostPlaybackBus.activeId.value = null;
          }
          if (mounted) setState(() {});
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _pages.isEmpty
              ? _gradientPlaceholder()
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (_, i) => _buildPageMedia(_pages[i]),
                    ),
                    // Native video page → tap toggles in-app playback.
                    // External (Instagram / YouTube / Twitter) page →
                    // tap opens the platform via launchUrl, since those
                    // services don't expose direct streams we can play.
                    if (_pages[_currentPage].isVideo)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _togglePlayback,
                          child: _buildPlayBadge(),
                        ),
                      )
                    else if (_pages[_currentPage].isExternal)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openExternal,
                          child: _buildExternalBadge(),
                        ),
                      ),
                    if (_pages[_currentPage].isExternal)
                      _buildExternalProviderChip(),
                    if (_pages.length > 1) _buildPageCountBadge(),
                    if (_pages.length > 1) _buildPageDots(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPageMedia(_HeroPage page) {
    if (page.isVideo) return _buildVideoMedia();
    if (page.isExternal) return _buildExternalMedia(page.imageUrl);
    return _buildImageMedia(page.imageUrl!);
  }

  Widget _buildExternalMedia(String? thumb) {
    if (thumb != null && thumb.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumb,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.whiteE5),
        errorWidget: (_, __, ___) => _gradientPlaceholder(),
      );
    }
    return _gradientPlaceholder();
  }

  Widget _buildVideoMedia() {
    final ctrl = _videoCtrl;
    if (ctrl != null && ctrl.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: ctrl.value.size.width,
          height: ctrl.value.size.height,
          child: VideoPlayer(ctrl),
        ),
      );
    }
    if (_generatedThumb != null) {
      return Image.file(
        _generatedThumb!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientPlaceholder(),
      );
    }
    return _gradientPlaceholder();
  }

  Widget _buildImageMedia(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.whiteE5),
      errorWidget: (_, __, ___) => _gradientPlaceholder(),
    );
  }

  Widget _gradientPlaceholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.10),
            AppColors.primaryColor.withValues(alpha: 0.04),
          ],
        ),
      ),
    );
  }

  /// "1 / N" badge in the top-right showing the user where they are
  /// in the carousel. Hidden when there's only a single page.
  Widget _buildPageCountBadge() {
    return Positioned(
      top: 10,
      right: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _pages[_currentPage].isVideo
                      ? Icons.play_circle_outline_rounded
                      : Icons.image_outlined,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                CustomText(
                  '${_currentPage + 1} / ${_pages.length}',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tiny dot indicators at the bottom centre.
  Widget _buildPageDots() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pages.length, (i) {
          final active = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  /// Frosted-glass play badge for external posts. Same silhouette as
  /// the in-app one so the card stays consistent, but the icon is the
  /// outward-arrow `open_in_new` glyph so the user understands tapping
  /// will leave the app.
  Widget _buildExternalBadge() {
    return Center(
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  /// Top-left chip naming the source platform (Instagram / YouTube /
  /// Twitter). Adopts the platform's brand color so the user spots
  /// where the content originated at a glance.
  Widget _buildExternalProviderChip() {
    // Always show the standard platform name (Instagram / YouTube / Twitter /
    // Facebook) — never the raw scraper extractor (microlink / fb-og / …).
    final platform = widget.post.platformKey;
    final label = widget.post.platformLabel;
    if (label.isEmpty) return const SizedBox.shrink();
    final brand = _brandColorFor(platform);
    final icon = _brandIconFor(platform);
    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brand.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: brand),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: brand,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _brandColorFor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'twitter':
      case 'x':
        return const Color(0xFF1DA1F2);
      case 'facebook':
        return const Color(0xFF1877F2);
      default:
        return AppColors.primaryColor;
    }
  }

  IconData _brandIconFor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'youtube':
        return Icons.play_circle_fill;
      case 'twitter':
      case 'x':
        return Icons.alternate_email;
      case 'facebook':
        return Icons.facebook;
      default:
        return Icons.link_rounded;
    }
  }

  /// Frosted-glass play / pause disc — only shown on the video page.
  Widget _buildPlayBadge() {
    final isPlaying = _videoCtrl?.value.isPlaying ?? false;
    final icon =
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded;
    return Center(
      child: AnimatedOpacity(
        opacity: isPlaying ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}

/// One slide in the hero PageView. Either:
///   • a native S3 video (`_HeroPage.video()`),
///   • an external preview (Instagram / YouTube / Twitter) where
///     [imageUrl] is the metadata thumbnail and the tap opens the
///     post in the platform's app (`_HeroPage.external(thumb)`), or
///   • one of the post's own image URLs (`_HeroPage.image(url)`).
class _HeroPage {
  final bool isVideo;
  final bool isExternal;
  final String? imageUrl;
  const _HeroPage.video()
      : isVideo = true,
        isExternal = false,
        imageUrl = null;
  const _HeroPage.external(this.imageUrl)
      : isVideo = false,
        isExternal = true;
  const _HeroPage.image(this.imageUrl)
      : isVideo = false,
        isExternal = false;
}
