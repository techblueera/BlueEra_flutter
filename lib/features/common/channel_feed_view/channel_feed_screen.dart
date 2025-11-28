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
import 'package:BlueEra/features/common/channel_feed_view/unjoin_channel_card_widget.dart';
import 'package:BlueEra/features/common/channel_feed_view/view_all_joined_channel_list_screen.dart';
import 'package:BlueEra/features/common/channel_feed_view/whats_new_channel_list_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChannelFeedScreen extends StatefulWidget {
  ChannelFeedScreen({super.key});

  @override
  State<ChannelFeedScreen> createState() => _ChannelFeedScreenState();
}

class _ChannelFeedScreenState extends State<ChannelFeedScreen> {
  final channelFeedController = Get.put(ChannelFeedController());
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    /// Initial data load
    channelFeedController.fetchChannelData(loadMore: false);
    channelFeedController.fetchUnJoinChannelData(loadMore: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
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
                                        _buildTitleWidget(AppStrings.myChannel),
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
                                        AppStrings.view,
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryColor,
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: SizeConfig.size16,
                                ),
                                _buildContainerOverlay(
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
                                  _buildTitleWidget(AppStrings.myChannel),
                                  Spacer(),
                                  CustomText(
                                    AppStrings.create,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() {
                        return CustomText(
                          "${AppStrings.joined.tr} ${formatNumberLikePost(channelFeedController.channelFeedModel.value.pagination?.total ?? 0)} ${AppStrings.channels.tr}",
                          fontWeight: FontWeight.w500,
                          fontSize: SizeConfig.size16,
                          color: AppColors.mainTextColor,
                        );
                      }),
                      InkWell(
                        onTap: () => Get.to(ViewAllJoinedChannelListScreen()),
                        child: CustomText(
                          AppStrings.viewAll,
                          fontWeight: FontWeight.w500,
                          fontSize: SizeConfig.size16,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Joined Channels
              Obx(() => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final channel =
                            channelFeedController.channelDataList[index];
                        return InkWell(
                          onTap: () => Get.to(
                            () => ChannelFeedPostListingScreen(
                                channelData: channel),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: ChannelCardWidget(channelModel: channel),
                          ),
                        );
                      },
                      childCount: channelFeedController.channelDataList.length,
                    ),
                  )),

              // Suggested Header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        AppStrings.suggested,
                        fontWeight: FontWeight.w500,
                        fontSize: SizeConfig.size16,
                        color: AppColors.mainTextColor,
                      ),
                      InkWell(
                        onTap: () => Get.to(WhatsNewChannelListScreen()),
                        child: CustomText(
                          AppStrings.viewAll,
                          fontWeight: FontWeight.w500,
                          fontSize: SizeConfig.size16,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Suggested Channels
              Obx(() => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final newChannel =
                            channelFeedController.unJoinChannelDataList[index];
                        return InkWell(
                          onTap: () async {
                            await Get.to(() => ChannelFeedPostListingScreen(
                                channelData: newChannel));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: UnjoinChannelCardWidget(
                              channelModel: newChannel,
                              index: index,
                            ),
                          ),
                        );
                      },
                      childCount:
                          channelFeedController.unJoinChannelDataList.length,
                    ),
                  )),

              // Bottom Spacer
              const SliverToBoxAdapter(
                child: SizedBox(height: kBottomNavigationBarHeight + 20),
              ),
            ],
          )),
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

  Widget _buildContainerOverlay({required Widget child}) {
    return Container(
      width: SizeConfig.screenWidth,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.greyE5, width: 1),
          boxShadow: [AppShadows.textFieldShadow]),
      child: child,
    );
  }
}
