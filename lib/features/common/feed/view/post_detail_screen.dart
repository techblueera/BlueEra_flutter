import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/post_detail_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

class PostDeatilPage extends StatelessWidget {
  const PostDeatilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostDetailController>(
        init: PostDetailController(),
        builder: (controller) {
          return Scaffold(
            appBar: CommonBackAppBar(
              onBackTap: () {
                Get.offAllNamed(
                  RouteHelper.getBottomNavigationBarScreenRoute(),
                  arguments: {ApiKeys.initialIndex: 0},
                );
                // Navigator.of(context).pushNamedAndRemoveUntil(
                //   RouteHelper.getBottomNavigationBarScreenRoute(),
                //   arguments: {ApiKeys.initialIndex: 0},
                //   (Route<dynamic> route) => false,
                // );
              },
              // title: controller.isupdate.value?Text("Update Bank Account"):Text("Update Bank Account")
              title: "Post",
              isLeading: true,
            ),
            body: Column(
              children: [
                controller.post != null
                    ? FeedCard(
                        index: 0,
                        post: controller.post,
                        postFilteredType: PostType
                            .otherPosts, //controller.postByIdResponseModalClass.data.type,
                      )
                    : Center(
                        child: CircularProgressIndicator(),
                      ),
                // Container(
                //   // child: Image.network(controller.postId ?? ""),
                // )
              ],
            ),
          );
        });
  }
}
