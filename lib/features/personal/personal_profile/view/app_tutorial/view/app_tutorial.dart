import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/api/apiService/api_keys.dart';
import '../../../../../../core/constants/app_enum.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/size_config.dart';
import '../../../../../../core/routes/route_helper.dart';
import '../../../../../../widgets/custom_text_cm.dart';

import 'package:get/get.dart';

import '../../../../../common/auth/model/adminvideo_model.dart';
import '../../../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../../../../../common/feed/models/video_feed_model.dart';
import 'list_of_apptotorial_video_view.dart';

class AppTutorialScreen extends StatefulWidget {
  const AppTutorialScreen({super.key});

  @override
  State<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends State<AppTutorialScreen> {
  final bottomBarController = Get.find<BottomBarController>();

  @override
  void initState() {
    super.initState();
    bottomBarController.fetchAllAdminVideoApiMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: CommonBackAppBar(
      title: "App Tutorial",
    ),
      body: Obx(() {
        if (bottomBarController.adminVideoLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bottomBarController.adminVideos.isEmpty) {
          return Center(
            child: CustomText(
              AppStrings.noDataFound.tr,
              fontSize: SizeConfig.medium,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bottomBarController.adminVideos.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TutorialVideoCard(
                videoItem: bottomBarController.adminVideos[index],
                videoType: VideoType.latest,
              ),
            );
          },
        );
      }),
    );
  }
}

class TutorialVideoCard extends StatelessWidget {
  final AdminVideo videoItem;
  final VideoType videoType;
  final VoidCallback? onTap;

  const TutorialVideoCard({
    super.key,
    required this.videoItem,
    required this.videoType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap:
              () {

        Get.to(ListOfAppTutorialVideoView(tittle:videoItem.title??'',videosUrl:videoItem.videoUrls));
          },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  videoItem.thumbnailUrl ?? '', // ✅ correct key
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey.shade300,
                  ),
                ),
                const Icon(
                  Icons.play_circle_fill,
                  size: 48,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CustomText(
            videoItem.title ?? '',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 4),
          CustomText(
            videoItem.description ?? '',
            fontSize: SizeConfig.small,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }
}