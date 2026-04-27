import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_chat_icon.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_map_widgets.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_profession_screen_preview.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _SelfProfessionPalette {
  final Color cardBg;
  final Color cardBorder;
  final Color tileBorder;
  final Color dividerLine;

  const _SelfProfessionPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.tileBorder,
    required this.dividerLine,
  });
}

const _selfProfessionPalettes = <_SelfProfessionPalette>[
  _SelfProfessionPalette(
    cardBg: Color(0xFFEDFDFF),
    cardBorder: Color(0xFFC0DDE1),
    tileBorder: Color(0xFFD0EEF2),
    dividerLine: Color(0xFFBBE3E8),
  ),
  _SelfProfessionPalette(
    cardBg: Color(0xFFFCF5FF),
    cardBorder: Color(0xFFECD3F6),
    tileBorder: Color(0xFFF7E3FF),
    dividerLine: Color(0xFFE3D4E9),
  ),
];

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
  final String serviceSubType = 'selfWork';
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
  }

  Widget _buildServicesMap(double statusBarHeight) {
    return DiscoverMapPreview(
      statusBarHeight: statusBarHeight,
      onTap: _openFullMap,
    );
  }

  void _openFullMap() {
    Get.to(() => _SelfProfessionMapScreen(
          earnServiceType: earnServiceType,
          subType: serviceSubType,
          onMarkerTap: _showServiceMapSheet,
        ));
  }

  /// Bottom sheet shown when a map marker is tapped — compact provider
  /// summary (avatar, name, rating, distance, price) with a "View Profile"
  /// CTA into [SelfProfessionScreenPreview]. Takes the host [BuildContext]
  /// so the sheet can render over either this screen or the dedicated
  /// [_SelfProfessionMapScreen] depending on where the marker was tapped.
  void _showServiceMapSheet(BuildContext hostContext, ServiceData service) {
    final priceData = service.priceData;
    final isRange = priceData?.priceType == 'range';
    final priceDisplay = isRange
        ? "₹${formatIndianNumber(priceData?.priceRange?.min ?? 0)}-${formatIndianNumber(priceData?.priceRange?.max ?? 0)}"
        : "₹${formatIndianNumber(priceData?.singlePrice ?? 0)}";
    final priceUnit =
        (priceData?.perUnit?.trim().isNotEmpty ?? false)
            ? priceData!.perUnit!
            : 'Hour';
    final ratingValue = service.rating != null && service.rating != 0
        ? service.rating.toString()
        : '0';
    final distance = '${service.distance ?? 0} km';

    showModalBottomSheet<void>(
      context: hostContext,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size12,
              SizeConfig.size16, SizeConfig.size16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CachedAvatarWidget(
                          imageUrl: service.profileImage ?? '',
                          size: SizeConfig.size60,
                          borderColor: Colors.white,
                          borderRadius: SizeConfig.size30,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            service.name ?? AppStrings.unknownUser.tr,
                            fontSize: SizeConfig.large18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mainTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((service.profession ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            CustomText(
                              service.profession!,
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                          SizedBox(height: SizeConfig.size6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildRatingBadge(ratingValue),
                              _buildDistanceBadge(distance),
                              _buildOnlineBadge(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size16),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w800,
                          ),
                          children: [
                            TextSpan(text: priceDisplay),
                            TextSpan(
                              text: ' / $priceUnit',
                              style: TextStyle(
                                fontSize: SizeConfig.small,
                                color: AppColors.secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        Get.to(() => SelfProfessionScreenPreview(
                              service: service,
                              timingMap:
                                  getMinMaxTimings(service.service?.timings),
                              priceDisplay: priceDisplay,
                              priceBadgeText: priceData?.priceType
                                      .toString()
                                      .capitalizeFirst ??
                                  '',
                              priceBadgeColor: isRange
                                  ? AppColors.green1A
                                  : AppColors.primaryColor,
                            ));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size16,
                            vertical: SizeConfig.size8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CustomText(
                          AppStrings.viewProfile,
                          color: Colors.white,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.fetchEarnServices(
          earnServiceType: earnServiceType,
          subType: serviceSubType,
          isLoadMore: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = [
      StickyCategory(id: 'ALL_OPTION', name: 'All', imageUrl: AppImageAssets.all),
      ..._selfEmployedCategories.map((c) => StickyCategory(
        id: c.tagId ?? '',
        name: c.name ?? '',
        imageUrl: getIndividualProfessionIcon(c.tagId).isNotEmpty
            ? getIndividualProfessionIcon(c.tagId)
            : c.imageUrl ?? '',
      )),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.appBackgroundColor,
        body: Stack(
          children: [
            NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _buildServicesMap(statusBarHeight),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    categories: stickyCategories,
                    singleLineLabel: true,
                    selectedId: controller.selectedEarnServiceData.value?.slugId ?? 'ALL_OPTION',
                    onCategoryTap: (item) {
                      controller.selectedEarnServiceData.value =
                          item.id == 'ALL_OPTION' ? null : OnboardingCategoryModel(
                            name: item.name,
                            slugId: item.id,
                            accountType: AppConstants.individual,
                          );
                      controller.fetchEarnServices(
                          earnServiceType: earnServiceType, subType: serviceSubType);
                      setState(() {});
                    },
                    onBack: () => Navigator.pop(context),
                    expandedLabelColor: AppColors.white,
                    backgroundGradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.blue5CAF.withValues(alpha: 0.1),
                        AppColors.blue5CAF.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ],
              body: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() => Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BookViaBlueEraPartnerBanner(onTap: () {}),
              HorizontalTabSelector<CategoryFilter>(
                tabs: controller.filters,
                selectedIndex:
                    controller.filters.indexOf(controller.selectedFilter.value),
                horizontalMargin: 0.0,
                verticalMargin: 8.0,
                onTabSelected: (index, _) {
                  final selectedEnum = controller.filters[index];
                  if (controller.selectedFilter.value == selectedEnum) return;
                  controller.selectedFilter.value = selectedEnum;
                },
                labelBuilder: (r) => r.localizedLabel,
                unSelectedBackgroundColor: AppColors.white,
              ),
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

  _SelfProfessionPalette _paletteFor(ServiceData service) {
    final key = (service.id ?? service.name ?? '').hashCode;
    return _selfProfessionPalettes[
        key.abs() % _selfProfessionPalettes.length];
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
    final priceUnit =
        (priceData?.perUnit?.trim().isNotEmpty ?? false)
            ? priceData!.perUnit!
            : 'Hour';

    final palette = _paletteFor(service);
    final livePhotos = (service.serviceMedia?.photos ?? const <String>[])
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final logo = service.profileImage ?? '';
    final hasLogo = logo.isNotEmpty;
    final heroImage = livePhotos.isNotEmpty
        ? livePhotos.first
        : (hasLogo ? logo : '');
    final extraPhotos = livePhotos.length > 1 ? livePhotos.length - 1 : 0;
    final expertise = (service.service?.expertise ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .toList();

    void openPreview() => Get.to(() => SelfProfessionScreenPreview(
          service: service,
          timingMap: timingMap,
          priceDisplay: priceDisplay,
          priceBadgeText: badgeText,
          priceBadgeColor: badgeColor,
        ));

    return InkWell(
      onTap: openPreview,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(service),
                  SizedBox(height: SizeConfig.size10),
                  _buildDottedLine(palette.dividerLine),
                  SizedBox(height: SizeConfig.size10),
                  _buildBodyRow(
                    service: service,
                    timingMap: timingMap,
                    expertise: expertise,
                    heroImage: heroImage,
                    livePhotos: livePhotos,
                    extraPhotos: extraPhotos,
                    palette: palette,
                  ),
                ],
              ),
            ),
            _buildFooter(
              priceDisplay: priceDisplay,
              priceUnit: priceUnit,
              palette: palette,
              onTap: openPreview,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header: avatar (online dot) + name + rating/distance/online + chat ─
  Widget _buildHeader(ServiceData service) {
    final ratingValue = service.rating != null && service.rating != 0
        ? service.rating.toString()
        : '0';
    final distance = '${service.distance ?? 0} km';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            CachedAvatarWidget(
              imageUrl: service.profileImage ?? '',
              size: SizeConfig.size50,
              borderColor: Colors.white,
              borderRadius: SizeConfig.size25,
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
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                service.name ?? AppStrings.unknownUser.tr,
                fontSize: SizeConfig.large18,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w800,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildRatingBadge(ratingValue),
                  _buildDistanceBadge(distance),
                  _buildOnlineBadge(),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size6),
        DiscoverChatIcon(
          userId: service.id ?? '',
          name: service.name,
          profile: service.profileImage,
          businessId: service.id,
          trackingSource: ChatClickSource.searchResult,
        ),
      ],
    );
  }

  // ─── Body: timing tile + expertise bullets on left, hero image right ───
  Widget _buildBodyRow({
    required ServiceData service,
    required Map<String, String> timingMap,
    required List<String> expertise,
    required String heroImage,
    required List<String> livePhotos,
    required int extraPhotos,
    required _SelfProfessionPalette palette,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0),
      child: SizedBox(
        height: 110,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimingTile(timingMap, palette),
                  SizedBox(height: SizeConfig.size6),
                  Expanded(child: _buildExpertiseList(expertise)),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              flex: 5,
              child: _buildHeroImage(
                service: service,
                heroImage: heroImage,
                livePhotos: livePhotos,
                extraPhotos: extraPhotos,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingTile(
      Map<String, String> timingMap, _SelfProfessionPalette palette) {
    final start = timingMap['start'] ?? '--';
    final end = timingMap['end'] ?? '--';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size8,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.tileBorder, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded,
              size: 14, color: AppColors.secondaryTextColor),
          SizedBox(width: SizeConfig.size6),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: 'Mon – Fri: '),
                  TextSpan(
                    text: '$start – $end',
                    style: TextStyle(
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.expand_more_rounded,
              size: 16, color: AppColors.secondaryTextColor),
        ],
      ),
    );
  }

  Widget _buildExpertiseList(List<String> expertise) {
    if (expertise.isEmpty) {
      return CustomText(
        '—',
        fontSize: SizeConfig.small,
        color: AppColors.secondaryTextColor,
        fontWeight: FontWeight.w400,
      );
    }
    final visible = expertise.take(3).toList();
    final extra = expertise.length - visible.length;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size8,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < visible.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: (i == visible.length - 1 && extra > 0)
                          ? () => _showExpertiseSheet(expertise)
                          : null,
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(text: visible[i]),
                            if (i == visible.length - 1 && extra > 0)
                              TextSpan(
                                text: '  +$extra More',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Opens a bottom sheet with the full expertise list, used by the
  /// "+N More" tap target inside [_buildExpertiseList].
  void _showExpertiseSheet(List<String> expertise) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
              SizeConfig.size16, SizeConfig.size12, SizeConfig.size16, SizeConfig.size16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        'Expertise',
                        fontSize: SizeConfig.large18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    const CloseButton(),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: expertise.length,
                    separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size6),
                    itemBuilder: (_, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 8),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: CustomText(
                              expertise[index],
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroImage({
    required ServiceData service,
    required String heroImage,
    required List<String> livePhotos,
    required int extraPhotos,
  }) {
    final natureOfBusiness = service.profession ?? 'Service';
    final fullList = livePhotos.isNotEmpty
        ? livePhotos
        : (heroImage.isNotEmpty ? [heroImage] : <String>[]);

    return GestureDetector(
      onTap: fullList.isEmpty
          ? null
          : () => _showPhotoDialog(
                images: fullList,
                initialIndex: 0,
                title: natureOfBusiness,
              ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (heroImage.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: heroImage,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  memCacheHeight: 600,
                  placeholder: (_, __) => LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),
                  errorWidget: (_, __, ___) => LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),
                )
              else
                LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                  boxFix: BoxFit.cover,
                ),
              if (extraPhotos > 0)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: CustomText(
                      '+$extraPhotos',
                      fontSize: SizeConfig.small,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter({
    required String priceDisplay,
    required String priceUnit,
    required _SelfProfessionPalette palette,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size10, horizontal: SizeConfig.size12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: palette.cardBorder, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(text: priceDisplay),
                  TextSpan(
                    text: '/ $priceUnit',
                    style: TextStyle(
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16, vertical: SizeConfig.size6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CustomText(
                AppStrings.viewProfile,
                fontSize: SizeConfig.small,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Badges ─────────────────────────────────────────────────────────────
  Widget _buildRatingBadge(String rating) {
    const goldFg = Color(0xFFB8860B);
    const goldBg = Color(0xFFFFF3D1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, goldBg],
        ),
        border: Border.all(
          color: goldFg.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: goldFg.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: AppIconAssets.star, height: 12, width: 12),
          const SizedBox(width: 4),
          CustomText(
            rating,
            fontSize: 11,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.greyE5.withValues(alpha: 0.4),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined,
              size: 12, color: AppColors.secondaryTextColor),
          const SizedBox(width: 3),
          CustomText(
            text,
            fontSize: 11,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.green.withValues(alpha: 0.10),
        border:
            Border.all(color: Colors.green.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          CustomText(
            'Online',
            fontSize: 11,
            color: Colors.green.shade700,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _buildDottedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }

  void _showPhotoDialog({
    required List<String> images,
    required int initialIndex,
    required String title,
  }) {
    if (images.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _SelfProfessionPhotoDialog(
        images: images,
        initialIndex: initialIndex,
        title: title,
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

/// Full-screen map page reached by tapping the inline preview on
/// [AllSelfProfessionScreen]. Loads every provider (unpaginated) via
/// [DiscoverController.fetchAllEarnServicesForMap] and renders them
/// through `google_maps_flutter`'s built-in clustering so 100+ pins
/// stay smooth — nearby providers collapse into a count badge that
/// splits open as the user zooms in.
///
/// Initial zoom is `12` — that frames roughly a 25–50 km area around
/// the user, matching the "city-radius" feel of mainstream discover apps.
class _SelfProfessionMapScreen extends StatefulWidget {
  final String earnServiceType;
  final String subType;
  final void Function(BuildContext context, ServiceData service) onMarkerTap;

  const _SelfProfessionMapScreen({
    required this.earnServiceType,
    required this.subType,
    required this.onMarkerTap,
  });

  @override
  State<_SelfProfessionMapScreen> createState() =>
      _SelfProfessionMapScreenState();
}

class _SelfProfessionMapScreenState extends State<_SelfProfessionMapScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _serviceIcon;

  final DiscoverController _ctrl = Get.find<DiscoverController>();
  static const ClusterManagerId _clusterManagerId =
      ClusterManagerId('self_profession_services');

  @override
  void initState() {
    super.initState();
    _ctrl.fetchAllEarnServicesForMap(
      earnServiceType: widget.earnServiceType,
      subType: widget.subType,
    );
    // Pre-render the custom marker icon once; cluster taps pop the
    // unclustered marker so this is what the user actually sees.
    DiscoverMarkerIcons.circle(icon: Icons.work_outline_rounded).then((d) {
      if (mounted) setState(() => _serviceIcon = d);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Builds the marker set fed to [GoogleMap.markers]. Each marker is
  /// stamped with [_clusterManagerId] so the platform-side cluster
  /// manager can group nearby ones into a numbered badge automatically.
  Set<Marker> _buildMarkers(List<ServiceData> services) {
    final markers = <Marker>{};
    for (final s in services) {
      final lat = s.userLocation?.lat?.toDouble();
      final lng = s.userLocation?.lon?.toDouble();
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      markers.add(
        Marker(
          markerId: MarkerId(s.id ?? '${s.name}_$lat,$lng'),
          position: LatLng(lat, lng),
          clusterManagerId: _clusterManagerId,
          icon: _serviceIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: s.name ?? AppStrings.unknownUser.tr,
            snippet: s.profession ?? '',
            onTap: () => widget.onMarkerTap(context, s),
          ),
          onTap: () => widget.onMarkerTap(context, s),
        ),
      );
    }
    return markers;
  }

  /// Frames the camera around every position inside the tapped cluster
  /// so the cluster expands cleanly into individual pins.
  Future<void> _zoomToCluster(Cluster cluster) async {
    if (_mapController == null) return;
    final markers = cluster.markerIds;
    if (markers.length <= 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(cluster.position, 15),
      );
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(cluster.bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLat =
        LocationService.lat != 0.0 ? LocationService.lat : 28.6139;
    final initialLng =
        LocationService.lng != 0.0 ? LocationService.lng : 77.2090;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            final markers = _buildMarkers(_ctrl.earnServiceMapList);
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(initialLat, initialLng),
                zoom: 12,
              ),
              markers: markers,
              clusterManagers: {
                ClusterManager(
                  clusterManagerId: _clusterManagerId,
                  onClusterTap: _zoomToCluster,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (c) => _mapController = c,
            );
          }),
          // Loading overlay while the unpaginated fetch is in flight.
          Obx(() {
            final isLoading = _ctrl.earnServiceMapResponse.value.status ==
                Status.INITIAL;
            if (!isLoading) return const SizedBox.shrink();
            return const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          }),
          // Banner-style header.
          Positioned(
            top: statusBarHeight + SizeConfig.size4,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                bannerMapCircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(child: bannerMapLocationPill()),
                SizedBox(width: SizeConfig.size8),
                bannerMapCircleIconButton(
                  icon: Icons.my_location,
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(initialLat, initialLng),
                        13,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Obx(() {
              final count = _ctrl.earnServiceMapList.where((s) {
                final lat = s.userLocation?.lat?.toDouble();
                final lng = s.userLocation?.lon?.toDouble();
                return lat != null && lng != null && !(lat == 0 && lng == 0);
              }).length;
              return Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          '$count service ${count == 1 ? "provider" : "providers"} on the map',
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SelfProfessionPhotoDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const _SelfProfessionPhotoDialog({
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_SelfProfessionPhotoDialog> createState() =>
      _SelfProfessionPhotoDialogState();
}

class _SelfProfessionPhotoDialogState
    extends State<_SelfProfessionPhotoDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.black,
          width: size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        widget.title,
                        fontSize: SizeConfig.medium,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: size.height * 0.5,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: widget.images[i],
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          errorWidget: (_, __, ___) => LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
