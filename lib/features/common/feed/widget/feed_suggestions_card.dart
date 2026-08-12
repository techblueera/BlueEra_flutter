import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/glass_surface.dart';
import 'package:flutter/material.dart';

/// The "who to follow" block of the merged home feed — a horizontally
/// scrolling row of profile cards, rendered for `type: "user_suggestions"`
/// items. See docs/HOME_FEED_INTEGRATION_GUIDE.md §4.5.
///
/// It is deliberately NOT a post: no view tracking, no engagement row, no
/// author header. Everything it needs arrives inside the feed item itself, so
/// it costs no extra request.
class FeedSuggestionsCard extends StatefulWidget {
  const FeedSuggestionsCard({super.key, required this.block});

  final FeedSuggestions block;

  @override
  State<FeedSuggestionsCard> createState() => _FeedSuggestionsCardState();
}

class _FeedSuggestionsCardState extends State<FeedSuggestionsCard> {
  /// Ids with a follow request in flight — keeps a double-tap from firing the
  /// call twice while the first is still going.
  final Set<String> _inFlight = {};

  Future<void> _onFollowTap(SuggestedUser user) async {
    if (user.id.isEmpty || _inFlight.contains(user.id)) return;

    final bool previous = user.isFollowing;
    setState(() {
      _inFlight.add(user.id);
      // Optimistic: the button flips immediately, then reverts if the call
      // fails (guide §5).
      user.isFollowing = true;
    });

    try {
      final response = await UserRepo().followUser(followUserId: user.id);
      if (!mounted) return;
      if (!response.isSuccess) {
        setState(() => user.isFollowing = previous);
        commonSnackBar(message: 'Could not follow. Please try again.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => user.isFollowing = previous);
      commonSnackBar(message: 'Could not follow. Please try again.');
    } finally {
      if (mounted) setState(() => _inFlight.remove(user.id));
    }
  }

  /// Opens the tapped profile through the app-wide visit resolver, the same
  /// one the feed's author header uses — so a suggested lab / restaurant lands
  /// on its own screen rather than the generic business profile.
  void _openProfile(SuggestedUser user) {
    if (user.id.isEmpty) return;
    final bool isBusiness = (user.accountType ?? '').toUpperCase() ==
        AppConstants.business.toUpperCase();
    openVisitProfile(
      accountType: user.accountType,
      // Individuals: `designation` is the profession's display name, which the
      // resolver maps to a profile type.
      profession: isBusiness ? null : user.designation,
      // Businesses: the sub-category decides the destination screen;
      // `designation` repeats it on most payloads and stands in when absent.
      categoryOfBusiness:
          isBusiness ? (user.businessCategory ?? user.designation) : null,
      // The suggestion payload carries one id. `openVisitProfile` falls back
      // between the two, so handing it over as the business id for a business
      // account and the user id otherwise is enough to route correctly.
      businessId: isBusiness ? user.id : null,
      userId: isBusiness ? null : user.id,
      screenFrom: AppConstants.feedScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.block.users;
    // Never render an empty box — a suggestion block with no profiles is just
    // a gap in the feed (guide §4.5).
    if (users.isEmpty) return const SizedBox.shrink();

    final bool glass = GlassScope.isActive(context);
    final radius = BorderRadius.circular(20);

    return Container(
      margin: EdgeInsets.only(
        bottom: SizeConfig.paddingXSL,
        left: SizeConfig.paddingXS,
        right: SizeConfig.paddingXS,
      ),
      clipBehavior: Clip.antiAlias,
      // Matches FeedCardWidget so the block sits in the same visual family as
      // the post cards around it — translucent under a [GlassScope] (Connect /
      // Social), solid white everywhere else.
      decoration: glass
          ? glassDecoration(borderRadius: radius)
          : BoxDecoration(
              color: AppColors.white,
              borderRadius: radius,
              border: Border.all(color: AppColors.greyE5, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: CustomText(
              widget.block.title,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(
            height: 208,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final user = users[index];
                return _SuggestionTile(
                  key: ValueKey(user.id.isNotEmpty ? user.id : 'sug_$index'),
                  user: user,
                  isBusy: _inFlight.contains(user.id),
                  onFollow: () => _onFollowTap(user),
                  onOpen: () => _openProfile(user),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// One profile card inside the row.
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    super.key,
    required this.user,
    required this.isBusy,
    required this.onFollow,
    required this.onOpen,
  });

  final SuggestedUser user;
  final bool isBusy;
  final VoidCallback onFollow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final bool following = user.isFollowing;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 136,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.greyE5, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedAvatarWidget(
              // `profile_image` is already CDN-rewritten and may be empty —
              // the avatar widget renders its own grey placeholder for null.
              imageUrl: user.profileImage,
              size: 62,
              borderRadius: 31,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: CustomText(
                    user.name,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (user.verified) ...[
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.verified,
                    size: 13,
                    color: AppColors.primaryColor,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            // Two lines max: some subtitles ("Followed by 12 others you
            // follow") never fit on one at this width.
            SizedBox(
              height: 30,
              child: CustomText(
                user.subtitle,
                fontSize: 10.5,
                color: AppColors.secondaryTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            // Follow flips in place and the card STAYS in the row — removing
            // it mid-scroll makes the row jump under the user's finger
            // (guide §4.5).
            InkWell(
              onTap: (following || isBusy) ? null : onFollow,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: following ? AppColors.white : AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryColor, width: 1.2),
                ),
                child: isBusy
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                        ),
                      )
                    : CustomText(
                        following ? 'Following' : 'Follow',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: following
                            ? AppColors.primaryColor
                            : AppColors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
