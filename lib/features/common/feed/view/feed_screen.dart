import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/view/feed_shimmer_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_reel_card.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/shared/widgets/animated/fade_in_up.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FeedScreen extends StatefulWidget {
  final PostType postFilterType;
  final String? id;
  final String? query;
  final Function(bool)? onHeaderVisibilityChanged;
  final double? headerHeight;
  final double? bottomPaddingChannel;
  final double? horizontalPaddingChannel;
  final bool isInParentScroll;

  /// Channel name from the channel screen, shown on posts created via
  /// channel in the channel feed. Null for the global feed.
  final String? channelName;

  const FeedScreen({
    super.key,
    required this.postFilterType,
    this.id,
    this.query,
    this.onHeaderVisibilityChanged,
    this.headerHeight,
    this.bottomPaddingChannel,
    this.horizontalPaddingChannel,
    this.isInParentScroll = false,
    this.channelName,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final feedController =
      Get.isRegistered<FeedController>() ? Get.find<FeedController>() : Get.put(FeedController());
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  // 🔹 State to track if "Scroll to Top" button should be visible
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);

      if (!widget.isInParentScroll) {
        _scrollController.addListener(_scrollListener);
      }

      ever(Get.find<NavigationHelperController>().shouldRefreshBottomBar, (shouldRefresh) {
        if (shouldRefresh == true) {
          fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
          Get.find<NavigationHelperController>().shouldRefreshBottomBar.value = false;
        }
      });
    });
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    // 🔹 1. Handle "Back to Top" button visibility
    // Show button after scrolling down 600 pixels
    bool show = position.pixels > 600;
    if (show != _showBackToTop) {
      setState(() {
        _showBackToTop = show;
      });
    }

    // 🔹 2. Handle Pagination (Existing logic)
    final isAtBottom = position.pixels >= position.maxScrollExtent - 200;
    if (isAtBottom) {
      feedController.handleScrollToBottom(widget.postFilterType);
    }
  }

  // 🔹 Method to animate back to the top
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postFilterType != widget.postFilterType) {
      fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
    }
    if (oldWidget.query != widget.query) {
      _onQueryChanged(widget.query);
    }
  }

  void _onQueryChanged(String? newQuery) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 100), () {
      fetchPostData(isInitialLoad: true, id: widget.id, query: newQuery);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    if (!widget.isInParentScroll) {
      _scrollController.removeListener(_scrollListener);
      _scrollController.dispose();
    }
    super.dispose();
  }

  void fetchPostData({bool isInitialLoad = false, bool refresh = false, String? id, String? query}) {
    feedController.getPostsByType(widget.postFilterType,
        isInitialLoad: isInitialLoad, refresh: refresh, id: id, query: query, screenName: '');
  }

  int _calculateItemCount(int rowsLength) {
    int totalItems = rowsLength;
    if (widget.postFilterType != PostType.saved && feedController.isTargetHasMoreData.isTrue) {
      totalItems += 1;
    }
    return totalItems;
  }

  Widget _buildListItem(int index, List<Post> posts, List<NativeAdRow> rows) {
    // Trailing load-more loader sits after all interleaved rows.
    if (index >= rows.length) {
      return Obx(() => feedController.isTargetMoreDataLoading.value
          ? staggeredDotsWaveLoading()
          : const SizedBox.shrink());
    }

    final row = rows[index];
    if (row.isAd) {
      return NativeAdSlot(
        adOrdinal: row.adOrdinal,
        keyPrefix: 'feed_native_ad',
      );
    }

    final int postIndex = row.contentIndex;
    final post = posts[postIndex];

    // Mixed post/reel feed: a reel item renders as a reel card instead of a
    // post card, and is not view-tracked as a post. See
    // docs/backend/REELS_IN_FEED_FRONTEND_GUIDE.md.
    if (post.isReel && post.reel != null) {
      return FeedReelCard(
        reel: post.reel!,
        horizontalPadding: widget.horizontalPaddingChannel,
        bottomPadding: widget.bottomPaddingChannel,
      );
    }

    return VisibilityDetector(
      key: Key('post_$postIndex'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5) {
          trackPostView(post.id);
        }
      },
      child: FeedCard(
        post: post,
        index: postIndex,
        postFilteredType: widget.postFilterType,
        bottomPadding: widget.bottomPaddingChannel,
        horizontalPadding: widget.horizontalPaddingChannel,
        channelName: widget.channelName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          if (feedController.isLoading.isFalse) {
            if (feedController.postsResponse.value.status == Status.COMPLETE ||
                widget.postFilterType == PostType.saved) {
              List<Post> posts = feedController.getListByType(widget.postFilterType);
              final rows = buildNativeAdRows(posts.length);

              if (posts.isEmpty) {
                // Polished "draft on a stack" empty state when the user
                // is looking at their own posts list. Three skeleton
                // post cards drift behind a primary-edged draft card,
                // with a single confident CTA. We gate on myPosts so
                // we never show "Write a post" on someone else's
                // profile or in the global feed.
                if (widget.postFilterType == PostType.myPosts) {
                  return const _CreatePostEmptyState();
                }
                return Center(
                  child: EmptyStateWidget(
                    message: widget.postFilterType == PostType.saved
                        ? AppStrings.noPostIsInSaved.tr
                        : AppStrings.noPostAvailable.tr,
                  ),
                );
              }

              final content = RefreshIndicator(
                notificationPredicate: (notification) {
                  return HomeScreenController.to.headerOffset.value == 0.0 &&
                      notification.metrics.pixels <= notification.metrics.minScrollExtent;
                },
                onRefresh: () async {
                  if (HomeScreenController.to.headerOffset.value != 0.0) return;
                  fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
                  return Future.value();
                },
                child: ListView.builder(
                  controller: widget.isInParentScroll ? null : _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(top: SizeConfig.size2, bottom: SizeConfig.size80),
                  shrinkWrap: widget.isInParentScroll,
                  physics: widget.isInParentScroll
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  itemCount: _calculateItemCount(rows.length),
                  itemBuilder: (context, index) => _buildListItem(index, posts, rows),
                ),
              );

              if (widget.postFilterType == PostType.all || widget.postFilterType == PostType.saved) {
                return setupScrollVisibilityNotification(
                  controller: widget.isInParentScroll ? null : _scrollController,
                  headerHeight: (widget.headerHeight ?? SizeConfig.size100),
                  onVisibilityChanged: (visible, offset) {
                    final controller = HomeScreenController.to;
                    const step = 0.25;
                    double newOffset = visible
                        ? (controller.headerOffset.value - step).clamp(0.0, 1.0)
                        : (controller.headerOffset.value + step).clamp(0.0, 1.0);

                    controller.headerOffset.value = newOffset;
                    controller.isVisible.value = visible;
                    widget.onHeaderVisibilityChanged?.call(visible);
                  },
                  child: content,
                );
              }
              return content;
            }
            else if (feedController.postsResponse.value.status == Status.ERROR) {
              return LoadErrorWidget(
                errorMessage: AppStrings.failedToLoadPosts.tr,
                onRetry: () {
                  feedController.isLoading.value = true;
                  fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
                },
              );
            } else {
              return const SizedBox();
            }
          } else {
            return FeedShimmerCard();
          }
        }),

        // 🔹 Floating Action Button Implementation
        if (_showBackToTop && !widget.isInParentScroll)
          Positioned(
            bottom: SizeConfig.size80,
            // Adjust height to avoid overlapping bottom bar
            right: SizeConfig.size10,
            child: FadeInUp(
              // Assuming you use animate_do or similar, otherwise use AnimatedOpacity
              duration: const Duration(milliseconds: 300),
              child: FloatingActionButton(
                backgroundColor: AppColors.primaryColor,
                mini: true,
                onPressed: _scrollToTop,
                child: const Icon(Icons.arrow_circle_up, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// "Draft on a stack" empty state — shown when the current user's
// post list is empty. The metaphor: three skeleton post cards
// drift behind a primary-edged draft card, with a soft primary
// halo radiating from beneath the stack. A single confident CTA
// sits below, opening the lekha (text) post composer via the
// shared [postVia] dialog. The composition fades in over ~900 ms
// in five staggered windows so the surface feels alive on land.
// ────────────────────────────────────────────────────────────────
class _CreatePostEmptyState extends StatelessWidget {
  const _CreatePostEmptyState();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, t, _) {
        // Stagger helper: returns a 0..1 fade-in for a sub-window
        // [start..end] of the overall animation timeline. Lets each
        // element appear in its own slot without a separate
        // controller per piece.
        double slot(double start, double end) => ((t - start) / (end - start)).clamp(0.0, 1.0);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Stack(slot: slot),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: slot(0.40, 0.65),
                    child: Transform.translate(
                      offset: Offset(0, (1 - slot(0.40, 0.65)) * 8),
                      child: const _Copy(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: slot(0.55, 0.80),
                    child: Transform.translate(
                      offset: Offset(0, (1 - slot(0.55, 0.80)) * 8),
                      child: const _PrimaryCta(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── STACK — three skeleton cards behind a primary-edged draft.
class _Stack extends StatelessWidget {
  final double Function(double, double) slot;
  const _Stack({required this.slot});

  @override
  Widget build(BuildContext context) {
    // Heights tuned to the actual artwork: tallest card bottoms out
    // around y=110, and the box leaves ~25 px of room beneath for
    // the soft drop shadows to bleed.
    return SizedBox(
      width: 300,
      height: 135,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft primary halo sits behind the cards. Radial gradient
          // with no hard edge so it reads as warmth, not a shape.
          // Allowed to bleed past the SizedBox via Clip.none.
          Positioned(
            left: 0,
            right: 0,
            top: -50,
            child: Center(
              child: Opacity(
                opacity: slot(0.0, 0.45) * 0.85,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.22),
                        AppColors.primaryColor.withValues(alpha: 0.06),
                        AppColors.primaryColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Furthest skeleton card — tilted left, faintest.
          Positioned(
            left: 18,
            top: 18,
            child: Opacity(
              opacity: slot(0.05, 0.30),
              child: Transform.rotate(
                angle: -0.06,
                child: const _SkeletonCard(width: 220, alphaScale: 0.55),
              ),
            ),
          ),
          // Middle skeleton card — tilted right, brighter.
          Positioned(
            right: 14,
            top: 8,
            child: Opacity(
              opacity: slot(0.15, 0.40),
              child: Transform.rotate(
                angle: 0.05,
                child: const _SkeletonCard(width: 240, alphaScale: 0.85),
              ),
            ),
          ),
          // Active "draft" card — primary-edged, sits on top, slides
          // up slightly during reveal so the eye lands on it.
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: slot(0.25, 0.55),
                child: Transform.translate(
                  offset: Offset(0, (1 - slot(0.25, 0.55)) * 14),
                  child: const _DraftCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── A faint skeleton placeholder card (avatar dot + content
// bars). The [alphaScale] dials the entire card's opacity so the
// further-back cards read as a softer ghost.
class _SkeletonCard extends StatelessWidget {
  final double width;
  final double alphaScale;
  const _SkeletonCard({required this.width, required this.alphaScale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alphaScale),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE6E8EE).withValues(alpha: alphaScale),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14001120).withValues(alpha: alphaScale * 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE6E8EE).withValues(alpha: alphaScale),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 70,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E8EE).withValues(alpha: alphaScale),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 7,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1F5).withValues(alpha: alphaScale),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 7,
            width: width * 0.7,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1F5).withValues(alpha: alphaScale),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 7,
            width: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1F5).withValues(alpha: alphaScale),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── The active "draft" card on top of the stack: a primary-tinted
// edit tile + a small headline + two primary-tinted bars suggesting
// in-progress writing. Reads instantly as "your unfinished post".
class _DraftCard extends StatelessWidget {
  const _DraftCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0x1A001120),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  Color.lerp(AppColors.primaryColor, Colors.black, 0.22) ?? AppColors.primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.draftSomething.tr,
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 6,
                  width: 78,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── COPY block: tracked primary eyebrow → display heading →
// supportive body line. Centered. Heading uses a hard newline so
// the two-line rhythm reads editorial rather than headline-y.
class _Copy extends StatelessWidget {
  const _Copy();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary-color eyebrow with two short hairlines flanking
        // the label. The hairlines anchor the eyebrow visually
        // without a heavy divider.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 1.4,
              color: AppColors.primaryColor.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.yourFirstPost.tr,
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 18,
              height: 1.4,
              color: AppColors.primaryColor.withValues(alpha: 0.55),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          AppStrings.shareWhatsOnYourMind.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            height: 1.12,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.yourFollowersAreListening.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── PRIMARY CTA — filled gradient pill with a soft primary glow
// underneath. Tap routes through the shared [postVia] dialog with
// the lekha (message) entry, matching how the global app bar
// kicks off a text post.
//
// The shadow lives on an *outer* Container, NOT on the Ink's
// decoration. Putting a shadow on Ink paints it onto the parent
// Material's rectangular canvas — which renders as a square blue
// halo regardless of the borderRadius we set. The canonical fix is
// shadow → outer container, gradient → Ink, splash → InkWell, all
// clipped to the same pill shape.
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                Color.lerp(AppColors.primaryColor, Colors.black, 0.18) ?? AppColors.primaryColor,
              ],
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: () => postVia(context, PostCreationMenu.message),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 17),
                  const SizedBox(width: 9),
                  Text(
                    AppStrings.writeAPost.tr,
                    style: TextStyle(
                      fontFamily: AppConstants.OpenSans,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*class FeedScreen extends StatefulWidget {
  final PostType postFilterType;
  final String? id;
  final String? query;
  final Function(bool)? onHeaderVisibilityChanged;
  final double? headerHeight;
  final double? bottomPaddingChannel;
  final double? horizontalPaddingChannel;
  final bool isInParentScroll; // Flag to indicate if used in parent scroll view

  const FeedScreen({
    super.key,
    required this.postFilterType,
    this.id,
    this.query,
    this.onHeaderVisibilityChanged,
    this.headerHeight,
    this.bottomPaddingChannel,
    this.horizontalPaddingChannel,
    this.isInParentScroll = false, // Default to false for individual page
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final feedController = Get.isRegistered<FeedController>()
      ? Get.find<FeedController>()
      : Get.put(FeedController());
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);

      // Only add scroll listener if this is an individual page (not in parent scroll)
      if (!widget.isInParentScroll) {
        _scrollController.addListener(_scrollListener);
      }

      /// forcefully we are calling api due to page is already loaded but we want to call api due to some new post is added by us
      ever(Get
          .find<NavigationHelperController>()
          .shouldRefreshBottomBar,
              (shouldRefresh) {
            if (shouldRefresh == true) {
              fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
              Get
                  .find<NavigationHelperController>()
                  .shouldRefreshBottomBar
                  .value =
              false;
            }
          });
    });
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom =
        position.pixels >= position.maxScrollExtent - 200; // 100px threshold

    if (isAtBottom) {
      feedController.handleScrollToBottom(widget.postFilterType);
    }
  }

  // this will if changes in sort by cause page is already loaded
  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// this is the case when post api is calling when sort by changed
    if (oldWidget.postFilterType != widget.postFilterType) {
      fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
    }

    /// this is the case when search query changes
    if (oldWidget.query != widget.query) {
      _onQueryChanged(widget.query);
    }
  }

  void _onQueryChanged(String? newQuery) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 100), () {
      // call the same method you already use
      fetchPostData(
        isInitialLoad: true,
        id: widget.id,
        query: newQuery,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _searchDebounce?.cancel();
    if (!widget.isInParentScroll) {
      _scrollController.removeListener(_scrollListener);
      _scrollController.dispose();
    }
  }

  void fetchPostData({bool isInitialLoad = false,
    bool refresh = false,
    String? id,
    String? query}) {
    feedController.getPostsByType(widget.postFilterType,
        isInitialLoad: isInitialLoad,
        refresh: refresh,
        id: id,
        query: query,
        screenName: '');
  }

  // Method to be called from parent for pagination
  void loadMore() {
    if (feedController.isTargetHasMoreData.isTrue &&
        feedController.isLoading.isFalse &&
        widget.postFilterType != PostType.saved) {
      fetchPostData(id: widget.id, query: widget.query);
    }
  }

  int _calculateItemCount(int postsLength) {
    int totalItems = postsLength;

    // Add loading indicator if there's more data
    if (widget.postFilterType != PostType.saved &&
        feedController.isTargetHasMoreData.isTrue) {
      totalItems += 1;
    }

    return totalItems;
  }

  Widget _buildListItem(int index, List<Post> posts) {
    int postIndex = index;
    // Loader at the end
    if (postIndex >= posts.length) {
      // Only show loader if pagination is in progress
      return Obx(() =>
      feedController.isTargetMoreDataLoading.value
          ? staggeredDotsWaveLoading()
          : const SizedBox.shrink());
    }

    return VisibilityDetector(
      key: Key('post_$index'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5) {
          trackPostView(posts[postIndex].id);
        }
      },
      child: FeedCard(
        post: posts[postIndex],
        index: postIndex,
        postFilteredType: widget.postFilterType,
        bottomPadding: widget.bottomPaddingChannel,
        horizontalPadding: widget.horizontalPaddingChannel,
        channelName: widget.channelName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Obx(() {
      if (feedController.isLoading.isFalse) {
        if (feedController.postsResponse.value.status == Status.COMPLETE ||
            widget.postFilterType == PostType.saved) {
          List<Post> posts =
          feedController.getListByType(widget.postFilterType);

          if (posts.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                message: widget.postFilterType == PostType.saved
                    ? 'No post is in saved.'
                    : 'No post available.',
              ),
            );
          }

          // 🔹 Only wrap with RefreshIndicator if headerOffset == 0
          final content = RefreshIndicator(
            notificationPredicate: (notification) {
              return Get
                  .find<HomeScreenController>()
                  .headerOffset
                  .value ==
                  0.0 &&
                  notification.metrics.pixels <=
                      notification.metrics.minScrollExtent;
            },
            onRefresh: () async {
              if (Get
                  .find<HomeScreenController>()
                  .headerOffset
                  .value != 0.0) {
                return;
              }

              // just call your function, then return a completed Future
              fetchPostData(
                isInitialLoad: true,
                refresh: true,
                id: widget.id,
              );

              return Future.value();
            },
            child: ListView.builder(
              controller: widget.isInParentScroll ? null : _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                  top: SizeConfig.size2, bottom: SizeConfig.size80),
              shrinkWrap: widget.isInParentScroll,
              physics: widget.isInParentScroll
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              itemCount: _calculateItemCount(posts.length),
              itemBuilder: (context, index) {
                return _buildListItem(index, posts);
              },
            ),
          );

          if (widget.postFilterType == PostType.all ||
              widget.postFilterType == PostType.saved) {
            return setupScrollVisibilityNotification(
              controller: widget.isInParentScroll ? null : _scrollController,
              headerHeight: (widget.headerHeight ?? SizeConfig.size100),
              onVisibilityChanged: (visible, offset) {
                final controller = Get.find<HomeScreenController>();
                final currentOffset = controller.headerOffset.value;

                // Linear animation step (same speed up/down)
                const step = 0.25;

                double newOffset = currentOffset;
                if (visible) {
                  // show header
                  newOffset = (currentOffset - step).clamp(0.0, 1.0);
                } else {
                  // hide header
                  newOffset = (currentOffset + step).clamp(0.0, 1.0);
                }

                controller.headerOffset.value = newOffset;
                controller.isVisible.value = visible;
                widget.onHeaderVisibilityChanged?.call(visible);
              },
              child: content,
            );
          }

          return content;
        } else if (feedController.postsResponse.value.status == Status.ERROR) {
          return LoadErrorWidget(
            errorMessage: 'Failed to load posts',
            onRetry: () {
              feedController.isLoading.value = true;
              fetchPostData(
                isInitialLoad: true,
                refresh: true,
                id: widget.id,
              );
            },
          );
        } else {
          return const SizedBox();
        }
      } else {
        return FeedShimmerCard();
      }
    });
  }

}*/
