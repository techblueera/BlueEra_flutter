import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_lab_view_screen.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_profiles_list_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabProfilesListScreen extends StatefulWidget {
  const LabProfilesListScreen({super.key});

  @override
  State<LabProfilesListScreen> createState() => _LabProfilesListScreenState();
}

class _LabProfilesListScreenState extends State<LabProfilesListScreen> {
  late final LabProfilesListController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => LabProfilesListController());
  }

  /// Pagination driven by scroll metrics rather than a private controller.
  /// This lets the ListView inherit the NestedScrollView's
  /// PrimaryScrollController so scrolling here also collapses the outer banner
  /// and pins the category header.
  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
      controller.fetchMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Material(
      color: AppColors.appBackgroundColor,
      child: Obx(() {
        if (controller.isLoading.value && controller.profiles.isEmpty) {
          return const _CenteredSpinner();
        }
        if (controller.error.value.isNotEmpty && controller.profiles.isEmpty) {
          return _CenteredMessage(
            message: AppStrings.failedToLoadData.tr,
            color: AppColors.red,
          );
        }
        if (controller.profiles.isEmpty) {
          return _CenteredMessage(
            message: AppStrings.noLaboratoriesFound.tr,
            color: AppColors.grey9B,
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: controller.fetchInitial,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size10,
                horizontal: SizeConfig.size8,
              ),
              itemCount: controller.profiles.length +
                  (controller.isLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.profiles.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                    child: const _CenteredSpinner(),
                  );
                }
                return _LabCard(item: controller.profiles[index]);
              },
            ),
          ),
        );
      }),
    );
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryColor),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final String message;
  final Color color;

  const _CenteredMessage({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomText(
        message,
        fontSize: SizeConfig.medium,
        color: color,
      ),
    );
  }
}

class _LabCard extends StatelessWidget {
  final LabProfileListItem item;

  const _LabCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Get.to(() => DiscoverLabViewScreen(detailsData: item)),
        child: CommonCardWidget(
          cardMargin: 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _logo(),
              SizedBox(width: SizeConfig.size12),
              Expanded(child: _details()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SizeConfig.size12),
      child: Container(
        width: SizeConfig.size60,
        height: SizeConfig.size60,
        color: AppColors.liteWhite,
        child: item.logoUrl.isNotEmpty
            ? Image.network(
                item.logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image,
                  color: AppColors.placeHolder,
                  size: SizeConfig.size32,
                ),
              )
            : Icon(
                Icons.image,
                color: AppColors.placeHolder,
                size: SizeConfig.size32,
              ),
      ),
    );
  }

  Widget _details() {
    final firstCampStart =
        item.fullDetails?.healthCamps?.firstOrNull?.startTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          item.name.isNotEmpty ? item.name : AppStrings.unknown.tr,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size6),
        if (item.description.isNotEmpty)
          ExpandableText(
            text: item.description,
            trimLines: 1,
            isReadMoreNewLine: false,
            expandMode: ExpandMode.dialog,
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              fontFamily: AppConstants.OpenSans,
            ),
          ),
        if (firstCampStart != null) ...[
          SizedBox(height: SizeConfig.size6),
          CustomText(
            "${AppStrings.openTime.tr}: $firstCampStart",
            fontSize: SizeConfig.small,
            color: AppColors.green00,
            fontWeight: FontWeight.w600,
          ),
        ],
      ],
    );
  }
}
