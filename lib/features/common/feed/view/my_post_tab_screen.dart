import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart'
    show getVideoData;
import 'package:BlueEra/features/common/feed/view/twitter_post_detail_screen.dart';
import 'package:BlueEra/features/common/reel/view/shorts/shorts_player_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/me/social/controller/social_home_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Which slice of the viewer's own posts the grid is showing.
///
/// Only [all] maps to something the backend understands. The rest are applied
/// **client-side** over the already-fetched `post/my-posts` page, because that
/// endpoint has no type filter — see SOCIAL_SECTION_INTEGRATION_GUIDE.md §1,
/// which describes My Post as "a pure UI move: same request, same response".
///
/// The practical consequence is that a filtered chip only ever sees the pages
/// pulled so far, so it fills in as the user scrolls rather than being a
/// complete server-side result set. Swap to real query params the moment the
/// endpoint grows them.
enum MyPostFilter { all, shorts, videos, reposts }

extension _MyPostFilterLabel on MyPostFilter {
  String get label => switch (this) {
        MyPostFilter.all => AppStrings.all.tr,
        MyPostFilter.shorts => AppStrings.shorts.tr,
        MyPostFilter.videos => AppStrings.videos.tr,
        MyPostFilter.reposts => AppStrings.reposts.tr,
      };
}

/// "My Post" tab of the Social section — the viewer's own profile summary above
/// a 3-column grid of everything they have posted.
///
/// Data comes from `post-service/post/my-posts` via
/// [FeedController.getPostsByType] with [PostType.myPosts] — the same call the
/// profile screens already make, so nothing new is fetched and the two stay in
/// sync through the shared [FeedController.myPosts] list.
class MyPostTabScreen extends StatefulWidget {
  const MyPostTabScreen({super.key});

  @override
  State<MyPostTabScreen> createState() => _MyPostTabScreenState();
}

class _MyPostTabScreenState extends State<MyPostTabScreen>
    with AutomaticKeepAliveClientMixin {
  final _feedController = getOrPut(() => FeedController());
  final _socialController = getOrPut(() => SocialHomeController());
  final _viewController =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  final _scrollController = ScrollController();

  MyPostFilter _filter = MyPostFilter.all;

  // The tab lives inside a TabBarView; without this, swiping away and back
  // would rebuild from scratch and re-trigger the fetch on every visit.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewController.UserFollowersAndPostsCount(userId);
      // Only fetch when the shared list is cold — the profile screens populate
      // the very same list, so a warm one is already correct.
      if (_feedController.myPosts.isEmpty) {
        _fetch(isInitialLoad: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _feedController.handleScrollToBottom(PostType.myPosts);
    }
  }

  Future<void> _fetch({bool isInitialLoad = false, bool refresh = false}) {
    return _feedController.getPostsByType(
      PostType.myPosts,
      isInitialLoad: isInitialLoad,
      refresh: refresh,
      id: userId,
      screenName: 'my_post_tab',
    );
  }

  Future<void> _refresh() async {
    await Future.wait([
      _fetch(isInitialLoad: true, refresh: true),
      _viewController.UserFollowersAndPostsCount(userId, forceRefresh: true),
    ]);
  }

  Future<void> _openFollowList(int tabIndex) async {
    await Get.to(() => FollowersFollowingPage(tabIndex: tabIndex, userID: userId));
    await _viewController.UserFollowersAndPostsCount(userId, forceRefresh: true);
  }

  // ---------------------------------------------------------------- filtering

  /// A reel arrives either as an injected `item_type: "reel"` item (that is how
  /// `my-posts?include_reels=true` ships them) or, on the merged feed, as a
  /// `short_video` typed item. Both are "Shorts" to the user.
  bool _isShort(Post p) => p.isReel || p.feedType == 'short_video';

  /// A long-form video the user posted. `type` is unreliable here — a
  /// `message_post` can carry an mp4 — so decide on the media, exactly as
  /// [Post.hasVideoMedia] does, and exclude anything already counted a short.
  bool _isVideo(Post p) {
    if (_isShort(p)) return false;
    if (p.feedType == 'long_video') return true;
    return p.hasVideoMedia || (p.videoUrl?.isNotEmpty ?? false);
  }

  List<Post> _applyFilter(List<Post> posts) {
    return switch (_filter) {
      MyPostFilter.all => posts,
      MyPostFilter.shorts => posts.where(_isShort).toList(),
      MyPostFilter.videos => posts.where(_isVideo).toList(),
      // `is_reposted` is the only repost signal the post payload carries.
      MyPostFilter.reposts =>
        posts.where((p) => p.is_reposted == true).toList(),
    };
  }

  // ------------------------------------------------------------------ tapping

  void _openItem(List<Post> visible, int index) {
    final post = visible[index];

    if (_isShort(post)) {
      // Hand the player every short in the current filtered view so the user
      // can keep swiping, and land it on the one they tapped.
      final shorts = visible.where(_isShort).toList();
      final startAt = shorts.indexWhere((p) => p.id == post.id);
      Get.to(() => ShortsPlayerScreen(
            shorts: Shorts.trending,
            initialShorts: shorts.map(getVideoData).toList(),
            initialIndex: startAt < 0 ? 0 : startAt,
          ));
      return;
    }

    Get.to(() => TwitterPostDetailScreen(
          post: post,
          postType: PostType.myPosts,
        ));
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Obx(() {
        final all = _feedController.myPosts.toList();
        final visible = _applyFilter(all);
        final isLoading = _feedController.isLoading.value && all.isEmpty;

        return CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildProfileSection()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            if (isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size40),
                  child: Center(
                    child: CustomText(
                      _filter == MyPostFilter.all
                          ? AppStrings.noPostAvailable.tr
                          : AppStrings.noPostAvailable.tr,
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.medium,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    SizeConfig.size8, 0, SizeConfig.size8, SizeConfig.size20),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _MyPostGridTile(
                      post: visible[index],
                      onTap: () => _openItem(visible, index),
                    ),
                    childCount: visible.length,
                  ),
                ),
              ),
            if (_feedController.isTargetMoreDataLoading.value)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size16),
                  child: const Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  // --------------------------------------------------------- profile section

  Widget _buildProfileSection() {
    return Obx(() {
      final user = _viewController.personalProfileDetails.value.user;
      final social = _socialController.profile.value?.data;

      final name = _capitalize(user?.name ?? '');
      final designation = user?.designation ?? '';
      final bio = user?.bio ?? social?.identity?.bio ?? '';
      final websiteUrl = social?.contact?.websiteUrl ?? '';
      final avatar = user?.profileImage ?? '';

      return Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size20,
            SizeConfig.size16, SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CachedAvatarWidget(
                  imageUrl: avatar,
                  size: SizeConfig.size80,
                  borderRadius: SizeConfig.size80 / 2,
                  showProfileOnFullScreen: false,
                ),
                SizedBox(width: SizeConfig.size14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (name.isNotEmpty) ...[
                        CustomText(
                          name,
                          fontSize: SizeConfig.extraLarge,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: SizeConfig.size14),
                      ],
                      _buildStatsRow(),
                    ],
                  ),
                ),
              ],
            ),
            // The chip, bio and link all run the full card width beneath the
            // avatar block rather than continuing the name's column.
            if (designation.trim().isNotEmpty) ...[
              SizedBox(height: SizeConfig.size16),
              _buildDesignationChip(designation),
            ],
            if (bio.trim().isNotEmpty) ...[
              SizedBox(height: SizeConfig.size14),
              ExpandableText(
                text: bio,
                trimLines: 2,
                expandMode: ExpandMode.expandable,
                dialogTitle: AppStrings.bio.tr,
                style: TextStyle(
                  fontSize: SizeConfig.medium15,
                  color: AppColors.mainTextColor,
                  height: 1.5,
                ),
              ),
            ],
            if (websiteUrl.trim().isNotEmpty) ...[
              SizedBox(height: SizeConfig.size12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link,
                      size: SizeConfig.size18, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size6),
                  Flexible(
                    child: CustomText(
                      websiteUrl,
                      fontSize: SizeConfig.medium15,
                      color: AppColors.primaryColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildStatsRow() {
    return Obx(() {
      final posts = _viewController.postsCount.value;
      final followers = _viewController.followersCount.value;
      final following = _viewController.followingCount.value;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statItem(AppStrings.posts.tr, formatNumberLikePost(posts)),
          SizedBox(width: SizeConfig.size24),
          GestureDetector(
            onTap: () => _openFollowList(1),
            child: _statItem(
                AppStrings.followers.tr, formatNumberLikePost(followers)),
          ),
          SizedBox(width: SizeConfig.size24),
          GestureDetector(
            onTap: () => _openFollowList(0),
            child: _statItem(
                AppStrings.following.tr, formatNumberLikePost(following)),
          ),
        ],
      );
    });
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          value,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 4),
        CustomText(
          label,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildDesignationChip(String designation) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14, vertical: SizeConfig.size6),
      decoration: BoxDecoration(
        // Low-alpha black rather than a fixed grey, so the chip reads as the
        // design's light fill on white and stays translucent over the banner.
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: CustomText(
        designation,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  // ----------------------------------------------------------- filter chips

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size12, SizeConfig.size4, SizeConfig.size12, SizeConfig.size12),
      child: Row(
        children: [
          for (final filter in MyPostFilter.values) ...[
            _chip(filter),
            SizedBox(width: SizeConfig.size10),
          ],
        ],
      ),
    );
  }

  Widget _chip(MyPostFilter filter) {
    final selected = _filter == filter;
    return InkWell(
      onTap: () {
        if (selected) return;
        setState(() => _filter = filter);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20, vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.whiteE5,
          ),
        ),
        child: CustomText(
          filter.label,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: selected ? AppColors.white : AppColors.mainTextColor,
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// One thumbnail in the My Post grid: cover image with the view count pinned
/// bottom-left, matching the reel tiles used elsewhere in the app.
class _MyPostGridTile extends StatelessWidget {
  const _MyPostGridTile({required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  /// Reels carry their cover on the nested payload; posts use `thumbnail` and
  /// fall back to their first media entry (an image post has no thumbnail).
  String? get _coverUrl {
    final reel = post.reel;
    if (reel != null) {
      final cover = reel.coverUrl;
      if (cover != null && cover.isNotEmpty) return cover;
      final thumb = reel.thumbnails?.values.firstWhere(
        (v) => v is String && v.isNotEmpty,
        orElse: () => null,
      );
      if (thumb is String && thumb.isNotEmpty) return thumb;
    }
    final thumbnail = post.thumbnail;
    if (thumbnail != null && thumbnail.isNotEmpty) return thumbnail;
    final media = post.media;
    if (media != null && media.isNotEmpty && media.first.isNotEmpty) {
      return media.first;
    }
    return null;
  }

  int get _views => post.reel?.stats.views ?? post.viewsCount ?? 0;

  @override
  Widget build(BuildContext context) {
    final cover = _coverUrl;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover != null)
              CachedNetworkImage(
                imageUrl: cover,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.whiteE5),
                errorWidget: (_, __, ___) => _fallback(),
              )
            else
              _fallback(),
            // Scrim so the white count stays legible over a bright thumbnail.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.viewIcon,
                    height: SizeConfig.size12,
                    width: SizeConfig.size12,
                    imgColor: AppColors.white,
                  ),
                  const SizedBox(width: 4),
                  CustomText(
                    formatNumberLikePost(_views),
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A text/poll post has no media at all — show its message rather than an
  /// empty grey box, so the grid stays readable for text-only authors.
  Widget _fallback() {
    final text = (post.message ?? post.title ?? '').trim();
    return Container(
      color: AppColors.whiteE5,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: CustomText(
        text,
        fontSize: SizeConfig.small,
        color: AppColors.secondaryTextColor,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
