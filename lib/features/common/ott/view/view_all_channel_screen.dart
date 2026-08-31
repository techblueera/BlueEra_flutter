import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/ott/binding/search_channel_binding.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/ott/view/search_channel_screen.dart';
import 'package:BlueEra/features/common/ott/widget/logo_name_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ViewAllChannelScreen extends StatefulWidget {
  const ViewAllChannelScreen({super.key});

  @override
  State<ViewAllChannelScreen> createState() => _ViewAllChannelScreenState();
}

class _ViewAllChannelScreenState extends State<ViewAllChannelScreen> {
  final channelFeedController = Get.find<ChannelFeedController>();

  final ScrollController _scrollController = ScrollController();

  apiCalling({required bool isLoadMore}) {
    channelFeedController.getAllChannelData(loadMore: isLoadMore);
  }

  @override
  void initState() {
    super.initState();
    // Listener for Pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        apiCalling(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in RefreshIndicator for Pull-to-Refresh
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        title: AppStrings.allChannels,
      ),
      body: Obx(() {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
              child: CommonSearchBar(
                  controller: TextEditingController(),
                  isShowCursor: false,
                  onSearchTap: () {
                    Get.to(() => SearchChannelScreen(),
                        binding: SearchChannelBinding());
                  },
                  onClearCallback: null,
                  hintText: AppStrings.searchByChannelName),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  apiCalling(isLoadMore: false);
                },
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  // Ensure grid is scrollable even if items are few (so refresh works)
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    // Display 3 items per row (Standard for Mobile)
                    crossAxisSpacing: 15,
                    // Horizontal space between items
                    mainAxisSpacing: 10,
                    // Vertical space between items
                    childAspectRatio:
                        0.9, // Adjust this ratio to fit your Text height (Width / Height)
                  ),
                  // If loading more, add +1 to count for the spinner
                  itemCount: channelFeedController.allChannelDataList.length +
                      (channelFeedController.isAllChannelLoading.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    // CASE 1: Render Loading Spinner at the bottom
                    if (index ==
                        channelFeedController.allChannelDataList.length) {
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                        ),
                      );
                    }

                    // CASE 2: Render Channel Item
                    final item =
                        channelFeedController.allChannelDataList[index];
                    return LogoNameWidget(
                      logoUrl: item.logoUrl ?? "",
                      channelName: item.name ?? "",
                      channelID: item.id ?? "",
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
