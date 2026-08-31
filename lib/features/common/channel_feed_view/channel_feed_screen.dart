import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_card_widget.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_post_listing_screen.dart';
import 'package:BlueEra/features/common/channel_feed_view/suggested_channels_screen.dart';

import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/glass_surface.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

DateTime? _lastChannelFetchTime;
bool _isChannelFetching = false;

class ChannelFeedScreen extends StatefulWidget {
  final Function(bool)? onHeaderVisibilityChanged;
  final double headerHeight;

  ChannelFeedScreen({
    super.key,
    this.onHeaderVisibilityChanged,
    required this.headerHeight,
  });

  @override
  State<ChannelFeedScreen> createState() => _ChannelFeedScreenState();
}

class _ChannelFeedScreenState extends State<ChannelFeedScreen> {
  final channelFeedController = Get.find<ChannelFeedController>();
  final scrollController = ScrollController();

  Future<void> _guardedChannelFetch() async {
    final currentTime = DateTime.now();

    // Check if we are already in the middle of a request OR if we fetched recently
    if (_isChannelFetching) return;
    if (_lastChannelFetchTime != null &&
        currentTime.difference(_lastChannelFetchTime!) < fetchThreshold) {
      debugPrint("Channel API call skipped: Too frequent.");
      return;
    }

    _isChannelFetching = true;
    _lastChannelFetchTime = currentTime;

    try {
      // Run both calls in parallel for better performance
      await Future.wait([
        channelFeedController.fetchChannelData(loadMore: false),
        channelFeedController.fetchUnJoinChannelData(loadMore: false),
      ]);
    } catch (e) {
      debugPrint("Error fetching channel data: $e");
    } finally {
      _isChannelFetching = false;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _guardedChannelFetch();
  }

  @override
  Widget build(BuildContext context) {
    // Under a [GlassScope] (the Connect screen) the page drops its opaque white
    // fill, which covered the app-wide banner edge to edge, for a frosted
    // sheet.
    //
    // A sheet and not full transparency: the rows on this page
    // ([ChannelCardWidget]) are already transparent and draw their channel name
    // and description in near-black, having leaned on the white fill behind
    // them for contrast. Over a bare banner that text lands on whatever image
    // the user picked. The wash keeps the banner visible while still giving
    // those rows a surface to be legible against.
    final bool glass = GlassScope.isActive(context);
    final myWidget = Material(
      color: glass ? Colors.white.withValues(alpha: 0.62) : AppColors.white,
      child: RefreshIndicator(
          onRefresh: () async {
            channelFeedController.clearList();
            await Future.delayed(Duration(microseconds: 200));

            await channelFeedController.fetchChannelData(loadMore: false);

            await channelFeedController.fetchUnJoinChannelData(loadMore: false);
          },
          child: CustomScrollView(
            controller: scrollController, // 👈 attach this!
            slivers: [
              // Header
              if (isIndividualUser() && channelId.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: CustomFormCard(
                      // Sits on the frosted sheet above, so it takes a lighter
                      // wash than a standalone glass card would — two full
                      // translucencies stacked would add back up to opaque
                      // white.
                      color:
                          glass ? Colors.white.withValues(alpha: 0.55) : null,
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size16,
                        vertical: SizeConfig.size10,
                      ),
                      child: channelId.isNotEmpty
                          ? Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        _buildCircleIcon(
                                            AppIconAssets.channelNew),
                                        SizedBox(width: SizeConfig.size6),
                                        _buildTitleWidget(
                                            AppStrings.myChannel.tr),
                                      ],
                                    ),
                                    SizedBox(width: SizeConfig.size6),
                                    InkWell(
                                      onTap: () {
                                        Get.toNamed(
                                          RouteHelper.getChannelScreenRoute(),
                                          arguments: {
                                            ApiKeys.argAccountType:
                                                accountTypeGlobal,
                                            ApiKeys.channelId: channelId,
                                            ApiKeys.authorId:
                                                (accountTypeGlobal ==
                                                        AppConstants.individual)
                                                    ? userId
                                                    : businessId
                                          },
                                        );
                                      },
                                      child: CustomText(
                                        AppStrings.view.tr,
                                        fontWeight: FontWeight.w500,
                                        fontSize: SizeConfig.size16,
                                        color: AppColors.primaryColor,
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: SizeConfig.size16,
                                ),
                                _buildContainerOverlay(
                                  glass: glass,
                                  child: Row(
                                    children: [
                                      CustomText(
                                        channelName,
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.primaryColor,
                                      ),
                                      SizedBox(width: SizeConfig.size6),
                                      CustomText(
                                        '@$channelOwner',
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            )
                          : InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteHelper.getManageChannelScreenRoute(),
                                );
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildCircleIcon(AppIconAssets.channelNew),
                                  SizedBox(width: SizeConfig.size6),
                                  _buildTitleWidget(AppStrings.myChannel.tr),
                                  Spacer(),
                                  CustomText(
                                    AppStrings.create.tr,
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  )
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              // Joined channels (only). Empty state nudges the user to
              // browse suggestions on a separate screen.
              Obx(() {
                final joined = channelFeedController.channelDataList;
                if (joined.isEmpty) {
                  return SliverToBoxAdapter(child: _buildJoinedEmptyState());
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final channel = joined[index];
                      return InkWell(
                        onTap: () => Get.to(
                          () => ChannelFeedPostListingScreen(
                              channelData: channel),
                        ),
                        child: ChannelCardWidget(channelModel: channel),
                      );
                    },
                    childCount: joined.length,
                  ),
                );
              }),

              // "See more suggestions" CTA at the end of the joined list —
              // hidden when the list is empty (empty state already has its
              // own CTA).
              Obx(() {
                if (channelFeedController.channelDataList.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _buildSeeMoreSuggestionsButton(),
                );
              }),

              // Bottom Spacer
              const SliverToBoxAdapter(
                child: SizedBox(height: kBottomNavigationBarHeight + 20),
              ),
            ],
          )),
    );
    return setupScrollVisibilityNotification(
      controller: scrollController,
      headerHeight: (widget.headerHeight),
      onVisibilityChanged: (visible, offset) {
        final controller = HomeScreenController.to;
        controller.headerOffset.value = offset;
        controller.isVisible.value = visible;
        widget.onHeaderVisibilityChanged?.call(visible);
      },
      child: myWidget,
    );
  }

  Widget _buildCircleIcon(String iconImage) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.primaryColor, width: 0.5),
      ),
      child: LocalAssets(
        width: SizeConfig.size22,
        height: SizeConfig.size22,
        imagePath: iconImage,
        imgColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildTitleWidget(String text) {
    return CustomText(
      text,
      fontSize: SizeConfig.medium,
      fontWeight: FontWeight.w600,
      color: AppColors.secondaryTextColor,
    );
  }

  Widget _buildJoinedEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.groups_rounded,
                size: 36, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 16),
          CustomText(
            AppStrings.noChannelsJoinedYet.tr,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 6),
          CustomText(
            AppStrings.discoverCommunitiesHint.tr,
            fontSize: 13,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => Get.to(() => const SuggestedChannelsScreen()),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_outlined,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  CustomText(
                    AppStrings.browseSuggestedChannels.tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeeMoreSuggestionsButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        onTap: () => Get.to(() => const SuggestedChannelsScreen()),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline,
                  size: 20, color: AppColors.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: CustomText(
                  AppStrings.seeMoreSuggestions.tr,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContainerOverlay({required Widget child, bool glass = false}) {
    return Container(
      width: SizeConfig.screenWidth,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size10,
      ),
      // Innermost of three stacked surfaces (sheet → card → this), so it takes
      // the inset wash — see [kGlassInsetGradient].
      decoration: glass
          ? glassDecoration(
              colors: kGlassInsetGradient,
              borderRadius: BorderRadius.circular(8),
              shadow: const [],
            )
          : BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.greyE5, width: 1),
              boxShadow: [AppShadows.textFieldShadow]),
      child: child,
    );
  }
}
