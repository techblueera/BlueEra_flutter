import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/widgets/business_profile_widget.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';

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
    'Profile','My Posts',
    'Shorts',
    'My Products',
    'Subscription',
    
    'Channels'
  ];

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
          id: businessId
        );
         case 'Shorts':
           return ShortsChannelSection(
          isOwnChannel: true,
          channelId: channelId,
          authorId: userId,
          showShortsInGrid: true,
           extraParams: { ApiKeys.postVia: 'user'},
        );

      default:
        return const Center(child: CustomText('Coming soon'));
    }
  }
}
