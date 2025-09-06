import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/widgets/business_profile_widget.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api/apiService/api_response.dart';
import '../../../widgets/horizontal_tab_selector.dart';
import '../auth/controller/view_business_details_controller.dart';

class BusinessProfileScreen extends StatefulWidget {
  BusinessProfileScreen({
    super.key,
  });

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  List<String> postTab = [
    'Profile',
    'My Posts',
    'Shorts',
    'Videos',
    'My Products',
    'Subscription',
    'Channels'
  ];
  List<SortBy>? filters;
  SortBy selectedFilter = SortBy.Latest;

  @override
  void initState() {
    setFilters();
    super.initState();
  }

  void setFilters(){
    filters = SortBy.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ViewBusinessDetailsController>(builder: (controller) {
      if (controller.viewBusinessResponse.status == Status.COMPLETE) {
        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.large, vertical: SizeConfig.size10),
          child: Column(
            children: [
              HorizontalTabSelector(
                tabs: postTab,
                selectedIndex:
                    viewBusinessDetailsController.selectedIndex.value,
                onTabSelected: (index, value) {
                  setState(() => viewBusinessDetailsController
                      .selectedIndex.value = index);
                },
                labelBuilder: (label) => label,
              ),


              if(viewBusinessDetailsController.selectedIndex.value == 2 ||
                  viewBusinessDetailsController.selectedIndex.value == 3 )...[
                _filterButtons(),
              ],

              SizedBox(
                height: SizeConfig.size20,
              ),
              _buildTabContent(
                  controller, viewBusinessDetailsController.selectedIndex.value)
            ],
          ),
        );
      } else {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(left: 40, top: 20),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }
    });
  }

  Widget _buildTabContent(ViewBusinessDetailsController controller, int index) {
    switch (postTab[index]) {
      case 'Profile':
        return BusinessProfileWidget();
      case 'My Posts':
         return FeedScreen(
          key: ValueKey('feedScreen_my_posts'),
          postFilterType: PostType.myPosts,
          id: businessId,
          isInParentScroll: true
        );
      case 'Shorts':
         return ShortsChannelSection(
          isOwnShorts: true,
          channelId: '',
          authorId: businessUserId,
          showShortsInGrid: true,
          sortBy: selectedFilter,
          postVia: PostVia.profile,
        );
      case "Videos":
      return VideoChannelSection(
            isOwnVideos: true,
            channelId: '',
            authorId: businessUserId,
            isScroll: false,
            postVia: PostVia.profile,
            sortBy: selectedFilter,
        );
      default:
        return const Center(child: CustomText('Coming soon'));
    }
  }

  Widget _filterButtons() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: SizeConfig.large, right: SizeConfig.large, top: SizeConfig.size20),
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.channelFilterIcon),
            SizedBox(width: SizeConfig.size10),
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Row(
                children: filters!.map((filter) {
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
                        filter.label, // use .label for display text
                        decoration: TextDecoration.underline,
                        color: isSelected ? Colors.blue : Colors.black54,
                        decorationColor: isSelected ? Colors.blue : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        )
    );
  }
}
