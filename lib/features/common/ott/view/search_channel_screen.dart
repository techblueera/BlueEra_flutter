import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/ott/controller/search_channel_controller.dart';
import 'package:BlueEra/features/common/ott/view/all_channel_video_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchChannelScreen extends StatefulWidget {
  SearchChannelScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<SearchChannelScreen> createState() => _SearchChannelScreenState();
}

class _SearchChannelScreenState extends State<SearchChannelScreen> {
  final controller = Get.find<SearchChannelController>();

  @override
  void dispose() {
    // TODO: implement dispose
    deleteIfRegistered<SearchChannelController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: AppStrings.searchChannels,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: AppStrings.searchByChannelName.tr,
                  hintStyle: TextStyle(
                      fontSize: SizeConfig.medium,
                      color: AppColors.secondaryTextColor),
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size8,
                        vertical: SizeConfig.size5),
                    child: LocalAssets(
                        imagePath: AppIconAssets.chat_search,
                        imgColor: AppColors.mainTextColor),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.greyD3,
                ),
              ),
            ),
            // --- Results List ---
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.searchList.isEmpty &&
                    controller.searchController.text.isNotEmpty) {
                  return const Center(
                      child: CustomText(AppStrings.noChannelsFound));
                }

                if (controller.searchList.isEmpty) {
                  return const Center(
                      child: CustomText(AppStrings.noChannelsFound));
                }

                return ListView.separated(
                  itemCount: controller.searchList.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final channel = controller.searchList[index];

                    return ListTile(
                      onTap: () {
                        Get.to(() => VideoListScreen(
                              channelID: channel.sId ?? "",
                              channelName: channel.name ?? "",
                            ));
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        // Check if URL exists before trying to load
                        child: ((channel.logoUrl?.isNotEmpty ?? false))
                            ? CachedNetworkImage(
                                imageUrl: channel.logoUrl ?? "",
                                // 1. If image loads successfully, show it in a CircleAvatar
                                imageBuilder: (context, imageProvider) =>
                                    CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage: imageProvider,
                                ),
                                // 2. While loading, show a spinner (or you can use a Shimmer widget)
                                placeholder: (context, url) => CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey.shade100,
                                  child: const SizedBox(
                                    height: 20,
                                    width: 20,
                                  ),
                                ),
                                // 3. If image fails to load, show the fallback icon
                                errorWidget: (context, url, error) =>
                                    CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey.shade100,
                                  child:
                                      const Icon(Icons.tv, color: Colors.grey),
                                ),
                              )
                            // 4. If URL is null/empty originally, show the fallback immediately
                            : CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.grey.shade100,
                                child: const Icon(Icons.tv, color: Colors.grey),
                              ),
                      ),
                      title: CustomText(
                        channel.name ?? "",
                        fontWeight: FontWeight.bold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: CustomText(
                        "@${channel.username ?? ""}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                );
              }),
            ),
            SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
