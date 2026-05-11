import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_blog/other_blogs_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_downloads/other_downloads_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_news/other_news_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: "Blog",
      icon: AppIconAssets.other_blog,
      // Replace with your actual icon asset
      page: () => OtherBlogsScreen(),
    ),
    ServiceMenuItem(
      title: "News",
      icon: AppIconAssets.other_news,
      page: () => OtherNewsScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Downloads",
      icon: AppIconAssets.other_download,
      page: () => OtherDownloadsScreen(),
    ),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.otherAnnouncements.tr,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...serviceMenus.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              // Spacing between cards
              child: InkWell(
                onTap: () => Get.to(item.page),
                child: MeMenuCardDesign(
                  title: item.title,
                  icon: item.icon,
                ),
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
        ],
      ),
    );
  }
}
