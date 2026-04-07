import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/widget/book_via_blueera_partner_banner.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─── AllSelfProfessionScreen ───
class AllSelfProfessionScreen extends StatefulWidget {
  final List<ProfessionTypeData> selfEmployedCategories;
  final ProfessionTypeData? selectedSelfProfessionData;

  const AllSelfProfessionScreen({
    super.key,
    required this.selfEmployedCategories,
    this.selectedSelfProfessionData,
  });

  @override
  State<AllSelfProfessionScreen> createState() =>
      _AllSelfProfessionScreenState();
}

class _AllSelfProfessionScreenState extends State<AllSelfProfessionScreen> {
  final controller = getOrPut(() => DiscoverController());
  late List<ProfessionTypeData> _selfEmployedCategories;
  final ScrollController scrollController = ScrollController();
  final String serviceSubType = EarnServiceTypes.selfWork.label;
  final String earnServiceType = AppConstants.service;

  @override
  void initState() {
    super.initState();
    _selfEmployedCategories = widget.selfEmployedCategories;
    final selected = widget.selectedSelfProfessionData;
    controller.selectedEarnServiceData.value = selected != null
        ? OnboardingCategoryModel(
            name: selected.name ?? '',
            slugId: selected.tagId ?? '',
            accountType: AppConstants.individual,
          )
        : null;
    controller.fetchEarnServices(
        earnServiceType: earnServiceType, subType: serviceSubType);
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller.fetchEarnServices(
            earnServiceType: earnServiceType,
            subType: serviceSubType,
            isLoadMore: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Book via BlueEra Partner Banner ───
            BookViaBlueEraPartnerBanner(
              onTap: () {
                // your navigation here
              },
            ),

            // ─── Main Content ───
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftCategoryList(),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(child: rightContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget leftCategoryList() {
    final allItem = ProfessionTypeData(
      name: 'All',
      tagId: 'ALL_OPTION',
      imageUrl: AppImageAssets.all,
    );
    final fullList = [allItem, ..._selfEmployedCategories];

    return CommonGenericLeftSideCategoryList<ProfessionTypeData>(
      items: fullList,
      getLabel: (item) => item.name ?? '',
      getIcon: (item) => getIndividualProfessionIcon(item.tagId).isNotEmpty
          ? getIndividualProfessionIcon(item.tagId)
          : item.imageUrl ?? '',
      isSelected: (item) {
        if (item.tagId == 'ALL_OPTION')
          return controller.selectedEarnServiceData.value == null;
        return controller.selectedEarnServiceData.value?.slugId == item.tagId;
      },
      onTap: (item, index) {
        controller.selectedTabIndex.value = index;
        controller.selectedEarnServiceData.value =
            item.tagId == 'ALL_OPTION' ? null : OnboardingCategoryModel(
              name: item.name ?? '',
              slugId: item.tagId ?? '',
              accountType: AppConstants.individual,
            );
        controller.fetchEarnServices(
            earnServiceType: earnServiceType, subType: serviceSubType);
      },
    );
  }

  Widget rightContent() {
    return Obx(() => Padding(
          padding: EdgeInsets.only(right: SizeConfig.size8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HorizontalTabSelector<CategoryFilter>(
                tabs: controller.filters,
                selectedIndex:
                    controller.filters.indexOf(controller.selectedFilter.value),
                horizontalMargin: 0.0,
                onTabSelected: (index, _) {
                  final selectedEnum = controller.filters[index];
                  if (controller.selectedFilter.value == selectedEnum) return;
                  controller.selectedFilter.value = selectedEnum;
                },
                labelBuilder: (r) => r.localizedLabel,
                unSelectedBackgroundColor: AppColors.white,
              ),
              SizedBox(height: SizeConfig.size8),
              Expanded(
                child: Obx(() {
                  if (controller.isEarnServiceLoading.value &&
                      controller.earnServiceList.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.earnServiceList.isEmpty) {
                    return Center(
                        child: EmptyStateWidget(message: AppStrings.noServicesFound.tr));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: controller.earnServiceList.length +
                        (controller.isEarnServiceLoadingMore.value ? 1 : 0),
                    padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                    itemBuilder: (context, index) {
                      if (index == controller.earnServiceList.length) {
                        return const Center(
                            child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)));
                      }
                      return selfProfessionCard(
                          controller.earnServiceList[index]);
                    },
                  );
                }),
              ),
            ],
          ),
        ));
  }

  Widget selfProfessionCard(ServiceData service) {
    final timingMap = getMinMaxTimings(service.service?.timings);
    final priceData = service.priceData;
    final isRange = priceData?.priceType == 'range';
    final priceDisplay = isRange
        ? "₹${formatIndianNumber(priceData?.priceRange?.min ?? 0)}-${formatIndianNumber(priceData?.priceRange?.max ?? 0)}"
        : "₹${formatIndianNumber(priceData?.singlePrice ?? 0)}";
    final badgeColor = isRange ? AppColors.green1A : AppColors.primaryColor;
    final badgeText = priceData?.priceType.toString().capitalizeFirst ?? '';

    return InkWell(
      onTap: () => Get.to(() => SelfProfessionScreenPreview(
            service: service,
            timingMap: timingMap,
            priceDisplay: priceDisplay,
            priceBadgeText: badgeText,
            priceBadgeColor: badgeColor,
          )),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5, width: 0.8),
          boxShadow: [AppShadows.textFieldShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Padding(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with online indicator
                  Stack(
                    children: [
                      CachedAvatarWidget(
                        imageUrl: service.profileImage ?? '',
                        size: SizeConfig.size44,
                        borderColor: Colors.white,
                        borderRadius: SizeConfig.size22,
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(width: SizeConfig.size8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          service.name ?? AppStrings.unknownUser.tr,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                        SizedBox(height: SizeConfig.size2),
                        CommonRatingRow(
                          rating:
                              double.tryParse(service.rating.toString()) ?? 0.0,
                          reviews: service.reviewCount ?? 0,
                          distance: '${service.distance ?? 0} KM',
                        ),
                      ],
                    ),
                  ),

                  // Price badge
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size8,
                        vertical: SizeConfig.size4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomText(priceDisplay,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w700,
                            color: badgeColor),
                        CustomText(badgeText,
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                            color: badgeColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Expertise bullets ───
            if (service.service?.expertise?.isNotEmpty == true)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    service.service!.expertise!.take(2).length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 6.0, right: 6.0),
                            child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle)),
                          ),
                          Expanded(
                            child: CustomText(
                              service.service!.expertise![index],
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ─── Footer — timing + action ───
            Container(
              margin: EdgeInsets.only(top: SizeConfig.size8),
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size10, vertical: SizeConfig.size8),
              decoration: BoxDecoration(
                color: AppColors.whiteF3,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  // Timing
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.secondaryTextColor),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          '${timingMap["start"]} - ${timingMap["end"]}',
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ),
                  // Book now chip
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size10,
                        vertical: SizeConfig.size4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      AppStrings.viewProfile,
                      fontSize: SizeConfig.small,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Timing helpers ───
  DateTime _parse12HourTime(String timeStr) {
    final format = RegExp(r'(\d+):(\d+)\s*(AM|PM)');
    final match = format.firstMatch(timeStr.trim());
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3);
      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;
      return DateTime(0, 1, 1, hour, minute);
    }
    return DateTime(0);
  }

  Map<String, String> getMinMaxTimings(List<Timings>? timingsList) {
    if (timingsList == null || timingsList.isEmpty)
      return {"start": "--", "end": "--"};
    Timings? earliest = timingsList.first;
    Timings? latest = timingsList.first;
    for (final t in timingsList) {
      if (_parse12HourTime(t.start ?? "00:00 AM")
          .isBefore(_parse12HourTime(earliest?.start ?? "00:00 AM")))
        earliest = t;
      if (_parse12HourTime(t.end ?? "00:00 AM")
          .isAfter(_parse12HourTime(latest?.end ?? "00:00 AM"))) latest = t;
    }
    return {"start": earliest?.start ?? "--", "end": latest?.end ?? "--"};
  }
}

// ─── SelfProfessionScreenPreview ───
class SelfProfessionScreenPreview extends StatelessWidget {
  final ServiceData service;
  final Map<String, String> timingMap;
  final String priceDisplay;
  final String priceBadgeText;
  final Color priceBadgeColor;

  const SelfProfessionScreenPreview({
    super.key,
    required this.service,
    required this.timingMap,
    required this.priceDisplay,
    required this.priceBadgeText,
    required this.priceBadgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: 80 + MediaQuery.of(context).padding.bottom),
            child: Column(
              children: [
                // ─── Profile Info Card ───
                CustomFormCard(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primaryColor, width: 2),
                            ),
                            child: CachedAvatarWidget(
                              imageUrl: service.profileImage ?? '',
                              size: 64,
                              borderColor: Colors.white,
                              borderRadius: 32,
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
                                        service.name ?? AppStrings.unknown.tr,
                                        fontSize: SizeConfig.large,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.mainTextColor,
                                      ),
                                    ),
                                    // Profession chip
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: SizeConfig.size8,
                                          vertical: SizeConfig.size3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppColors.primaryColor
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: CustomText(
                                        service.profession ?? '',
                                        fontSize: SizeConfig.small,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size6),
                                CommonRatingRow(
                                  rating: double.tryParse(
                                          service.rating.toString()) ??
                                      0.0,
                                  reviews: service.reviewCount ?? 0,
                                  distance: '${service.distance ?? 0} KM',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Bio
                      if (service.bio?.isNotEmpty == true) ...[
                        SizedBox(height: SizeConfig.size12),
                        Divider(color: AppColors.greyE5, height: 1),
                        SizedBox(height: SizeConfig.size12),
                        ExpandableText(
                          text: service.bio ?? '',
                          trimLines: 3,
                          expandMode: ExpandMode.dialog,
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontFamily: AppConstants.OpenSans,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeConfig.medium,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size8),

                // ─── Quick Stats Row ───
                CustomFormCard(
                  padding: EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      _buildStatItem(
                        icon: Icons.currency_rupee_rounded,
                        label: AppStrings.priceLabel.tr,
                        value: priceDisplay,
                        color: priceBadgeColor,
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        icon: Icons.access_time_rounded,
                        label: AppStrings.opens.tr,
                        value: timingMap["start"] ?? '--',
                        color: Colors.green,
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        icon: Icons.access_time_filled_rounded,
                        label: AppStrings.closes.tr,
                        value: timingMap["end"] ?? '--',
                        color: AppColors.redB4,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size8),

                // ─── Service Description ───
                if (service.service?.facilities?.isNotEmpty == true)
                  _buildInfoCard(
                    icon: Icons.description_outlined,
                    title: AppStrings.serviceDescription.tr,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        service.service!.facilities!.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(
                                    top: 7.0, right: 8.0),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle),
                              ),
                              Expanded(
                                child: CustomText(
                                  service.service!.facilities![index],
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: SizeConfig.size8),

                // ─── Work Experience ───
                _buildInfoCard(
                  icon: Icons.work_outline_rounded,
                  title: AppStrings.workExperience.tr,
                  child: service.experiences?.isNotEmpty == true
                      ? CustomText(
                          service.experiences![0],
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                        )
                      : _buildEmptyState(AppStrings.noExperienceAddedYet.tr),
                ),

                SizedBox(height: SizeConfig.size8),

                // ─── Expertise ───
                if (service.skills?.isNotEmpty == true)
                  _buildInfoCard(
                    icon: Icons.star_outline_rounded,
                    title: AppStrings.expertiseLabel.tr,
                    child: Wrap(
                      spacing: SizeConfig.size8,
                      runSpacing: SizeConfig.size8,
                      children: service.skills!
                          .map((skill) => Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: SizeConfig.size10,
                                    vertical: SizeConfig.size6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.primaryColor
                                          .withValues(alpha: 0.2)),
                                ),
                                child: CustomText(skill,
                                    fontSize: SizeConfig.small,
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w500),
                              ))
                          .toList(),
                    ),
                  ),

                SizedBox(height: SizeConfig.size8),

                // ─── Gallery ───
                if (service.serviceMedia?.photos?.isNotEmpty == true)
                  _buildInfoCard(
                    icon: Icons.photo_library_outlined,
                    title: AppStrings.gallery.tr,
                    child: SocialGalleryGrid(
                      imageUrls: service.serviceMedia!.photos!,
                    ),
                  ),
              ],
            ),
          ),

          // ─── Fixed Bottom Button ───
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size16,
                SizeConfig.size12,
                SizeConfig.size16,
                SizeConfig.size16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: CustomBtn(
                onTap: () {},
                isValidate: true,
                radius: SizeConfig.size12,
                title: AppStrings.requestBooking.tr,
                bgColor: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stat Item ───
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(value,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor),
          CustomText(label,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: AppColors.greyE5);
  }

  // ─── Info Card ───
  Widget _buildInfoCard(
      {required IconData icon, required String title, required Widget child}) {
    return CustomFormCard(
      padding: EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primaryColor),
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(title,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor),
            ],
          ),
          Divider(color: AppColors.greyE5, height: SizeConfig.size20),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return CustomText(msg,
        fontSize: SizeConfig.medium,
        color: AppColors.secondaryTextColor,
        fontWeight: FontWeight.w400);
  }

}
