import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/personal_overview_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/testimonials_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/widget/new_profile_header_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/portfolio_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../controller/profile_controller.dart';

class NewVisitProfileScreen extends StatefulWidget {
  final String authorId;
  final String screenFromName;
  final String channelId;

  const NewVisitProfileScreen(
      {super.key,
      required this.authorId,
      required this.screenFromName,
      required this.channelId});

  @override
  State<NewVisitProfileScreen> createState() => _NewVisitProfileScreenState();
}

class _NewVisitProfileScreenState extends State<NewVisitProfileScreen>
    with SingleTickerProviderStateMixin {
  List<String> postTab = [];
  int selectedIndex = 0;
  late VisitProfileController controller;
  List<SortBy>? filters;
  SortBy selectedFilter = SortBy.Latest;

  @override
  void initState() {
    controller = Get.put(VisitProfileController());
    setFilters();
    controller.fetchUserById(userId: widget.authorId);
    controller.getUserChannelDetailsController(userId: widget.authorId);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  setFilters() {
    SortBy.values.where((e) => e != SortBy.UnderProgress).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: Obx(() {
        final user = controller.userData.value?.user;
        if (controller.isProfileLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        postTab = [
          "Overview",
          if (user?.profession == SELF_EMPLOYED) 'Portfolio',
          'Posts',
          'Testimonials',
          'Shorts',
          'Videos'
        ];
        final validIndexes =
            user?.profession == SELF_EMPLOYED ? {3, 4} : {2, 3};

        return SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NewProfileHeaderWidget(
                    user: user,
                    screenFromName: widget.screenFromName,

                  ),
                  SizedBox(
                    height: SizeConfig.size16,
                  ),
                  Padding(
                    padding:  EdgeInsets.symmetric( horizontal: SizeConfig.size16),
                    child: HorizontalTabSelector(
                      horizontalMargin: 0,
                      tabs: postTab,
                      selectedIndex: selectedIndex,
                      onTabSelected: (index, value) {
                        setState(() => selectedIndex = index);
                      },
                      labelBuilder: (label) => label,
                    ),
                  ),
                  if (validIndexes.contains(selectedIndex)) ...[
                    _filterButtons(),
                  ],
                  SizedBox(height: SizeConfig.size16),
                  _buildTabContent(selectedIndex)
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _filterButtons() {
    return SingleChildScrollView(
        padding:
            EdgeInsets.only(top: SizeConfig.size20, bottom: SizeConfig.size10),
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.channelFilterIcon),
            SizedBox(width: SizeConfig.size10),
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Row(
                children: filters?.map((filter) {
                      final isSelected = selectedFilter == filter;
                      return Padding(
                        padding: EdgeInsets.only(right: SizeConfig.size14),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
                          child: CustomText(
                            filter.label,
                            decoration: TextDecoration.underline,
                            color: isSelected ? Colors.blue : Colors.black54,
                            decorationColor:
                                isSelected ? Colors.blue : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList() ??
                    [],
              ),
            )
          ],
        ));
  }

  Widget _buildTabContent(int index) {
    switch (postTab[index]) {
      case 'Overview':
        return PersonalOverviewScreen(
          userId: widget.authorId,
          channelId: widget.channelId,
          videoType: VideoType.latest.name, screenFromName: widget.screenFromName,

        );
      case 'Portfolio':
        return PortfolioWidget(
          isSelfPortfolio: false,
        );

      case 'Posts':
        return FeedScreen(
            key: ValueKey('feedScreen_user_posts_${widget.authorId}'),
            postFilterType: PostType.otherPosts,
            isInParentScroll: true,
            // or whatever enum value you have for user posts
            id: widget.authorId);
      // case 'Achievements':
      // return AchievementsWidget();
      case 'Testimonials':
        return TestimonialsScreen(
          userName: controller.userData.value?.user?.name ?? 'N/A',
          visitUserID: widget.authorId,
          isSelfTestimonial: false,
          screenFromName: widget.screenFromName,
        );
      case 'Shorts':
        return ShortsChannelSection(
          isOwnShorts: true,
          channelId: '',
          authorId: widget.authorId,
          showShortsInGrid: true,
          sortBy: selectedFilter,
          postVia: PostVia.profile,
        );
      case 'Videos':
        return VideoChannelSection(
          isOwnVideos: false,
          channelId: '',
          authorId: widget.authorId,
          sortBy: selectedFilter,
          padding: 0.0,
          postVia: PostVia.profile,
        );
      default:
        return const Center(child: CustomText('Coming soon'));
    }
  }
}

class StatBlock extends StatelessWidget {
  final String count;
  final String label;

  const StatBlock({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          count,
          fontWeight: FontWeight.w600,
        ),
        CustomText(
          label,
          fontSize: SizeConfig.small,
          color: Color.fromRGBO(107, 124, 147, 1),
        ),
      ],
    );
  }
}

class _SocialLink extends StatelessWidget {
  final String text;

  const _SocialLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomText(
      text,
      fontSize: SizeConfig.small,
      color: AppColors.primaryColor,
      fontWeight: FontWeight.w900,
    );
  }
}
