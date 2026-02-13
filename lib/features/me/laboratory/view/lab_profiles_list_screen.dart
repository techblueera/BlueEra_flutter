import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_profiles_list_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabProfilesListScreen extends StatefulWidget {
  const LabProfilesListScreen({super.key});

  @override
  State<LabProfilesListScreen> createState() => _LabProfilesListScreenState();
}

class _LabProfilesListScreenState extends State<LabProfilesListScreen> {
  late final LabProfilesListController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => LabProfilesListController());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      controller.fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: const CommonBackAppBar(title: "Laboratory Profiles"),
      backgroundColor: AppColors.appBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.profiles.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (controller.error.value.isNotEmpty && controller.profiles.isEmpty) {
          return Center(
            child: CustomText(
              "Failed to load data",
              fontSize: SizeConfig.medium,
              color: AppColors.red,
            ),
          );
        }
        if (controller.profiles.isEmpty) {
          return Center(
            child: CustomText(
              "No laboratories found",
              fontSize: SizeConfig.medium,
              color: AppColors.grey9B,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: controller.fetchInitial,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(SizeConfig.paddingM),
            itemCount: controller.profiles.length +
                (controller.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.profiles.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor)),
                );
              }
              final item = controller.profiles[index];
              return _LabCard(item: item);
            },
          ),
        );
      }),
    );
  }
}

class _LabCard extends StatelessWidget {
  final LabProfileListItem item;
  const _LabCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SizeConfig.size12),
            child: Container(
              width: SizeConfig.size60,
              height: SizeConfig.size60,
              color: AppColors.liteWhite,
              child: item.logoUrl.isNotEmpty
                  ? Image.network(
                      item.logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Icon(Icons.image,
                          color: AppColors.placeHolder,
                          size: SizeConfig.size32),
                    )
                  : Icon(Icons.image,
                      color: AppColors.placeHolder, size: SizeConfig.size32),
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        item.name.isNotEmpty ? item.name : "Unknown",
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.more_vert, color: AppColors.grey9B, size: 20),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  item.description.isNotEmpty
                      ? item.description
                      : "No description available",
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  "Open: 9:00 AM", // placeholder since API does not provide timing
                  fontSize: SizeConfig.small,
                  color: AppColors.green00,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
