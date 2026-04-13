import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/post_detail_controller.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostDeatilPage extends StatelessWidget {
  const PostDeatilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async {

        Get.offAllNamed(
          RouteHelper.getBottomNavigationBarScreenRoute(),
          arguments: {ApiKeys.initialIndex: 0},
        );

        return false;
      },
      child: GetBuilder<PostDetailController>(
          init: PostDetailController(),
          builder: (controller) {
            return Scaffold(
              appBar: CommonBackAppBar(
                onBackTap: () {
                  Get.offAllNamed(
                    RouteHelper.getBottomNavigationBarScreenRoute(),
                    arguments: {ApiKeys.initialIndex: 0},
                  );
                },
                title: AppStrings.post,
                isLeading: true,
              ),
              body: controller.post != null
                  ? SingleChildScrollView(
                      child: FeedCard(
                        index: 0,
                        post: controller.post,
                        postFilteredType: PostType.otherPosts,
                        likeFeed: controller.onLikeDislikePressed,
                      ),
                    )
                  : Center(
                      child: CircularProgressIndicator(),
                    ),
            );
          }),
    );
  }
}
