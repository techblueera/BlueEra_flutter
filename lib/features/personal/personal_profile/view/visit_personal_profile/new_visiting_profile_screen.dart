import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/tab_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/controller/overview_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/testimonials_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/widget/new_profile_header_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/size_config.dart';
import '../../controller/profile_controller.dart';

class NewVisitProfileScreen extends StatefulWidget {
  final String authorId;
  final String screenFromName;
  final String? isScreenName;

  // final String channelId;

  const NewVisitProfileScreen({
    super.key,
    required this.authorId,
    required this.screenFromName,
    this.isScreenName,
    // required this.channelId
  });

  @override
  State<NewVisitProfileScreen> createState() => _NewVisitProfileScreenState();
}

class _NewVisitProfileScreenState extends State<NewVisitProfileScreen>
    with SingleTickerProviderStateMixin {
  List<TabItem> postTab = [];
  int selectedIndex = 0;

  List<SortBy>? filters;

  // SortBy selectedFilter = SortBy.Latest;
  final ScrollController _scrollController = ScrollController();
  final OverviewController overViewController = Get.put(OverviewController());
  final FeedController feedController = Get.put(FeedController());
  VisitProfileController visitController =
      Get.isRegistered<VisitProfileController>()
          ? Get.find<VisitProfileController>()
          : Get.put(VisitProfileController());

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overViewController.loadOverviewData(
        widget.authorId,
        VideoType.latest.name,
      );
      feedController.getPostsByType(PostType.otherPosts,
          isInitialLoad: true,
          refresh: true,
          id: widget.authorId,
          query: "",
          screenName: '');

      visitController.fetchUserById(userId: widget.authorId);
      visitController.getUserChannelDetailsController(userId: widget.authorId);

      apiCalling();

      _setupScrollListener();
    });

    super.initState();
  }

  void setFilters() {
    filters = SortBy.values.toList();
  }

  apiCalling() async {
    await visitController.getTestimonialController(userID: widget.authorId);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      // Handle pagination for child sections
      _handleChildSectionPagination();
    });
  }

  void _handleChildSectionPagination() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom =
        position.pixels >= position.maxScrollExtent - 100; // 100px threshold

    if (isAtBottom) {
      final feedController = Get.find<FeedController>();
      if (feedController.isTargetHasMoreData.isTrue &&
          feedController.isLoading.isFalse) {
        feedController.getPostsByType(
          PostType.otherPosts,
          isInitialLoad: false,
          id: widget.authorId,
          screenName: '',
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  onBackClick() {
    if (widget.isScreenName == AppConstants.deepLinkScreen) {
      Get.offAllNamed(
        RouteHelper.getBottomNavigationBarScreenRoute(),
        arguments: {ApiKeys.initialIndex: 0},
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onBackClick();
        return false;
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          onBackTap: () async {
            onBackClick();
          },
        ),
        body: Obx(() {
          final user = visitController.userData.value?.user;
          if (visitController.isProfileLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          postTab = [
            TabItem(id: 'Posts', title: AppStrings.posts.tr),
            TabItem(id: 'Testimonials', title: AppStrings.testimonials.tr),
            TabItem(id: 'Channel', title: AppStrings.channel.tr),
          ];

          return SingleChildScrollView(
            controller: _scrollController,
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
                      height: SizeConfig.size10,
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                      child: HorizontalTabSelector(
                        horizontalMargin: 0,
                        tabs: postTab,
                        selectedIndex: selectedIndex,
                        onTabSelected: (index, value) {
                          setState(() => selectedIndex = index);
                        },
                        labelBuilder: (label) => label.title,
                      ),
                    ),
                    SizedBox(height: SizeConfig.size16),
                    _buildTabContent(selectedIndex)
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (postTab[index].id) {
      case 'Posts':
        return FeedScreen(
            key: ValueKey('feedScreen_user_posts_${widget.authorId}'),
            postFilterType: PostType.otherPosts,
            isInParentScroll: true,
            id: widget.authorId);
      case 'Testimonials':
        return TestimonialsScreen(
          userName: visitController.userData.value?.user?.name ?? 'N/A',
          visitUserID: widget.authorId,
          isSelfTestimonial: false,
          screenFromName: widget.screenFromName,
        );
      case 'Channel':
        return const Center(child: CustomText('Coming soon'));

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
