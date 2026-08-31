import 'dart:math' as math;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/glass_surface.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:BlueEra/features/common/home/view/widget/symbol_fullscreen_viewer.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SymbolStoryRow extends StatelessWidget {
  const SymbolStoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SymbolFeedController>();

    return Obx(() {
      // Build an ordered list with self always first.
      final List<SymbolUserGroup> raw = controller.userGroups.toList();
      final int selfIdx =
          userId.isEmpty ? -1 : raw.indexWhere((g) => g.user?.id == userId);
      SymbolUserGroup? selfGroup;
      if (selfIdx != -1) {
        selfGroup = raw.removeAt(selfIdx);
      }

      // Hide row entirely while initial load is in progress and we have no
      // data to show. Once we know the user is logged in, the self card
      // (with Add option) is always visible.
      if (controller.isLoading.value && raw.isEmpty && selfGroup == null) {
        return const SizedBox.shrink();
      }
      if (userId.isEmpty && raw.isEmpty) {
        return const SizedBox.shrink();
      }

      // Total = self card (always) + others
      final int othersCount = raw.length;
      final int totalCount = (userId.isNotEmpty ? 1 : 0) + othersCount;

      // Trailing slot: while a page is loading show shimmer placeholder cards
      // for the upcoming data; otherwise show a single arrow the user taps to
      // page in the next batch of user groups.
      final bool isLoadingMore = controller.isLoadingMore.value;
      final bool showLoadMore = controller.hasMore.value;
      const int shimmerCount = 3;
      final int trailingCount =
          isLoadingMore ? shimmerCount : (showLoadMore ? 1 : 0);

      Future<void> openAddSymbol() async {
        await Get.to(() => AddChatSymbolScreen());
        controller.fetchSymbolFeed();
      }

      // Panel-weight glass under a [GlassScope] (the Connect screen): the rail
      // is chrome behind the story cards, not a surface carrying text, so it
      // takes the lighter wash and lets the banner read through between cards.
      // Outside the scope it stays the solid white band the other feed hosts
      // are built around.
      final bool glass = GlassScope.isActive(context);
      return Container(
        // Full-bleed band, so it takes the wash on its own rather than through
        // glassDecoration() — a rounded rim and a lift shadow are for panels
        // that have edges to define, and this one runs to both screen edges.
        decoration: glass
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: kGlassPanelGradient,
                ),
              )
            : const BoxDecoration(color: Colors.white),
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        height: 168,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: totalCount + trailingCount,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            // Trailing slot sits after all the user cards: shimmer placeholders
            // while paging, otherwise the tappable "load more" arrow.
            if (index >= totalCount) {
              if (isLoadingMore) {
                return const _SymbolShimmerCard();
              }
              return _LoadMoreCard(onTap: controller.loadMoreSymbols);
            }

            final bool isSelfSlot = userId.isNotEmpty && index == 0;
            if (isSelfSlot) {
              if (selfGroup != null && selfGroup.symbols.isNotEmpty) {
                // Self has symbols → show the card with "+" badge.
                return _StatusCard(
                  group: selfGroup,
                  isSelf: true,
                  onTap: () {
                    // Place self at index 0 of the list passed to the viewer.
                    final ordered = <SymbolUserGroup>[selfGroup!, ...raw];
                    _openFullscreen(context, ordered, 0);
                  },
                  onAddTap: openAddSymbol,
                );
              }
              // No self symbols → show empty add placeholder.
              return _AddSymbolCard(onTap: openAddSymbol);
            }

            final int rowOffset = userId.isNotEmpty ? 1 : 0;
            final int rawIdx = index - rowOffset;
            final group = raw[rawIdx];
            return _StatusCard(
              group: group,
              isSelf: false,
              onTap: () {
                final ordered = <SymbolUserGroup>[
                  if (selfGroup != null) selfGroup,
                  ...raw,
                ];
                // `ordered` prepends self only when selfGroup != null. Row
                // offset (the add-card placeholder slot) is independent of
                // that, so derive the viewer index from rawIdx instead of
                // the row index — otherwise tapping otherN opens otherN+1
                // when the placeholder occupies row 0.
                final int viewerIndex = (selfGroup != null ? 1 : 0) + rawIdx;
                _openFullscreen(context, ordered, viewerIndex);
              },
            );
          },
        ),
      );
    });
  }

  void _openFullscreen(BuildContext context, List<SymbolUserGroup> groups,
      int initialGroupIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => SymbolFullscreenViewer(
          groups: groups,
          initialGroupIndex: initialGroupIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SymbolUserGroup group;
  final VoidCallback onTap;
  final bool isSelf;
  final VoidCallback? onAddTap;

  static const double _cardWidth = 88;
  static const double _cardHeight = 146;
  static const double _radius = 12;
  static const double _avatarSize = 36;
  static const double _avatarRingStroke = 2.2;
  static const double _addBadgeSize = 18;

  const _StatusCard({
    required this.group,
    required this.onTap,
    this.isSelf = false,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final String? profileImage = group.user?.profileImage;
    final String name = group.user?.name ?? AppStrings.userFallback.tr;
    final SymbolFeedItem? preview = _previewSymbol;
    final List<bool> seenFlags =
        group.symbols.map((s) => s.hasSeen == true).toList(growable: false);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _cardWidth,
        height: _cardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(preview),
              // Bottom gradient for legibility of the name.
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: SizedBox(
                  width: _avatarSize,
                  height: _avatarSize,
                  child: CustomPaint(
                    painter: _StatusRingPainter(
                      seenFlags: seenFlags,
                      strokeWidth: _avatarRingStroke,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: ClipOval(
                          child:
                              (profileImage != null && profileImage.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: profileImage,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          const _AvatarFallback(),
                                      errorWidget: (_, __, ___) =>
                                          const _AvatarFallback(),
                                    )
                                  : const _AvatarFallback(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isSelf && onAddTap != null)
                Positioned(
                  top: 8 + _avatarSize - _addBadgeSize + 2,
                  left: 8 + _avatarSize - _addBadgeSize + 2,
                  child: GestureDetector(
                    onTap: onAddTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: _addBadgeSize,
                      height: _addBadgeSize,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// First unseen symbol if available, otherwise the latest one.
  SymbolFeedItem? get _previewSymbol {
    if (group.symbols.isEmpty) return null;
    return group.symbols.firstWhere(
      (s) => s.hasSeen != true,
      orElse: () => group.symbols.first,
    );
  }

  Widget _buildBackground(SymbolFeedItem? symbol) {
    if (symbol == null) {
      return Container(color: Colors.grey.shade300);
    }

    final String type = symbol.type ?? '';
    final String? content = symbol.content;
    final bool hasContent = content != null && content.isNotEmpty;

    // 1. Video → play glyph and the clip length. Checked before the image
    // branch so an mp4 mislabelled `image` doesn't fail to decode.
    if (hasContent && (type == 'video' || _isVideoUrl(content))) {
      return _buildVideoPreview(symbol);
    }

    // 2. Explicit image type, OR a URL whose path looks like an image file.
    if (hasContent && (type == 'image' || _isImageUrl(content))) {
      return CachedNetworkImage(
        imageUrl: content,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey.shade300),
        errorWidget: (_, __, ___) =>
            _buildTextPreview(symbol, fallback: Colors.grey.shade400),
      );
    }

    // 3. Any other URL (embeddedUrl or plain link in content) → link preview.
    if (hasContent && _isHttpUrl(content)) {
      return _buildLinkPreview(symbol, content);
    }

    return _buildTextPreview(symbol);
  }

  /// Video tile for the story row. Deliberately doesn't buffer the clip just to
  /// paint a card — the length comes from `media_duration`, so the badge is
  /// correct on the first frame.
  Widget _buildVideoPreview(SymbolFeedItem symbol) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Center(
            child: Icon(Icons.play_circle_fill_rounded,
                color: Colors.white70, size: 26),
          ),
          if (symbol.hasKnownDuration)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomText(
                  formatMediaDuration(symbol.mediaDuration),
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
    'avif',
    'svg',
  };

  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'm4v',
    'webm',
    'mkv',
    '3gp',
    'avi',
  };

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// Lower-cased file extension of a URL, or null when there isn't one to read.
  /// Decodes percent-encoded paths (e.g. "uploads%2F...jpg") first.
  String? _urlExtension(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return null;
    String path;
    try {
      path = Uri.decodeFull(uri.path);
    } catch (_) {
      path = uri.path;
    }
    final dot = path.lastIndexOf('.');
    if (dot == -1) return null;
    return path.substring(dot + 1).toLowerCase();
  }

  bool _isImageUrl(String value) =>
      _imageExtensions.contains(_urlExtension(value));

  bool _isVideoUrl(String value) =>
      _videoExtensions.contains(_urlExtension(value));

  Widget _buildLinkPreview(SymbolFeedItem symbol, String url) {
    final Color bg = _parseColor(symbol.backgroundColor) ?? Colors.white;
    // Wrap in IgnorePointer so AnyLinkPreview's default tap-to-open-browser
    // doesn't swallow the card's tap. We always want the card to open the
    // fullscreen viewer.
    return IgnorePointer(
      child: AnyLinkPreview(
        link: url,
        cache: const Duration(days: 7),
        backgroundColor: bg,
        bodyMaxLines: 2,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        bodyStyle: const TextStyle(color: Colors.white70, fontSize: 10),
        placeholderWidget: _linkFallback(url, bg),
        errorWidget: _linkFallback(url, bg),
        borderRadius: 0,
        removeElevation: true,
      ),
    );
  }

  Widget _linkFallback(String url, Color bg) {
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(8, 56, 8, 36),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(
            url,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPreview(SymbolFeedItem symbol, {Color? fallback}) {
    final Color bg = _parseColor(symbol.backgroundColor) ??
        fallback ??
        AppColors.primaryColor;
    final String? body =
        (symbol.caption?.isNotEmpty ?? false) ? symbol.caption : symbol.content;

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(8, 56, 8, 36),
      alignment: Alignment.center,
      child: body == null || body.isEmpty
          ? const SizedBox.shrink()
          : Text(
              body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var clean = hex.replaceFirst('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    final parsed = int.tryParse('0x$clean');
    return parsed == null ? null : Color(parsed);
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.person, color: Colors.grey[400], size: 20),
    );
  }
}

/// Empty self placeholder shown when the current user has no symbols yet.
/// Mirrors WhatsApp's "Add status" card: light grey card, centered profile
/// avatar with a black "+" badge, and a two-line "Add status" label below.
class _AddSymbolCard extends StatelessWidget {
  final VoidCallback onTap;

  static const double _cardWidth = 88;
  static const double _cardHeight = 146;
  static const double _radius = 12;
  static const double _avatarSize = 52;
  static const double _addBadgeSize = 20;

  const _AddSymbolCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String? profileImage =
        userProfileGlobal.isNotEmpty ? userProfileGlobal : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _cardWidth,
        height: _cardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(_radius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: _avatarSize + 6,
                  height: _avatarSize + 6,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Container(
                          width: _avatarSize,
                          height: _avatarSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: (profileImage != null &&
                                    profileImage.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: profileImage,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        const _AvatarFallback(),
                                    errorWidget: (_, __, ___) =>
                                        const _AvatarFallback(),
                                  )
                                : const _AvatarFallback(),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: _addBadgeSize,
                          height: _addBadgeSize,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1F22),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    AppStrings.addSymbolMenu.tr,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1E1F22),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trailing card in the story row that pages in the next batch of user
/// groups when tapped. While the page is loading, the row swaps this arrow for
/// [_SymbolShimmerCard] placeholders instead.
class _LoadMoreCard extends StatelessWidget {
  final VoidCallback onTap;

  static const double _cardHeight = 146;
  static const double _cardWidth = 56;
  static const double _buttonSize = 44;

  const _LoadMoreCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _cardWidth,
        height: _cardHeight,
        child: Center(
          child: Container(
            width: _buttonSize,
            height: _buttonSize,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder shown in place of a not-yet-loaded story card while the
/// next page of symbols is being fetched. Matches the story card footprint.
class _SymbolShimmerCard extends StatelessWidget {
  const _SymbolShimmerCard();

  static const double _cardWidth = 88;
  static const double _cardHeight = 146;

  @override
  Widget build(BuildContext context) {
    return buildLoadingShimmer(
      child: shimmerContainer(
        width: _cardWidth,
        height: _cardHeight,
        radius: 12,
      ),
    );
  }
}

/// Paints a WhatsApp-style segmented status ring around the small avatar.
/// Green for unseen segments, light grey for seen.
class _StatusRingPainter extends CustomPainter {
  final List<bool> seenFlags;
  final double strokeWidth;

  static const Color _unseenColor = AppColors.symbolBorderGreen;
  static final Color _seenColor = Colors.grey.shade400;

  const _StatusRingPainter({
    required this.seenFlags,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int count = seenFlags.length;
    if (count == 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (count == 1) {
      paint.color = seenFlags.first ? _seenColor : _unseenColor;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final double gapDeg = count > 12 ? 2.0 : (count > 6 ? 3.0 : 4.0);
    final double gapRad = gapDeg * math.pi / 180.0;
    final double totalGap = gapRad * count;
    final double segmentSweep = (2 * math.pi - totalGap) / count;

    double startAngle = -math.pi / 2 + gapRad / 2;

    for (int i = 0; i < count; i++) {
      paint.color = seenFlags[i] ? _seenColor : _unseenColor;
      canvas.drawArc(rect, startAngle, segmentSweep, false, paint);
      startAngle += segmentSweep + gapRad;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusRingPainter old) {
    if (old.strokeWidth != strokeWidth) return true;
    if (old.seenFlags.length != seenFlags.length) return true;
    for (int i = 0; i < seenFlags.length; i++) {
      if (old.seenFlags[i] != seenFlags[i]) return true;
    }
    return false;
  }
}
