import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/discover_school_home_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/auth/service/chat_click_tracker.dart';

class AllEducationServiceScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> professionalConsultantCategories;
  final OnboardingCategoryModel? selectedProfessionConsultantData;

  const AllEducationServiceScreen(
      {super.key, required this.professionalConsultantCategories, this.selectedProfessionConsultantData});

  @override
  State<AllEducationServiceScreen> createState() => _AllEducationServiceScreenState();
}

class _AllEducationServiceScreenState extends State<AllEducationServiceScreen> {
  final controller_ = getOrPut(() => DiscoverController());
  late List<OnboardingCategoryModel> _professionalConsultantCategories;
  ScrollController scrollController = ScrollController();

  final List<String> _bannerImages = const [
    "https://img.magnific.com/free-vector/education-horizontal-typography-banner-set-with-learning-knowledge-symbols-flat-illustration_1284-29493.jpg",
    "https://img.magnific.com/premium-psd/school-education-admission-youtube-thumbnail-web-banner-template_475351-415.jpg?semt=ais_hybrid&w=740&q=80",
    "https://c8.alamy.com/comp/P70PTA/school-banner-with-education-items-P70PTA.jpg"
  ];
  // final List<String> _bannerImages = const [
  //   "https://img.freepik.com/free-photo/happy-students-classroom_23-2149207191.jpg?w=1380",
  //   "https://img.freepik.com/free-photo/group-college-students-studying-library_329181-15025.jpg?w=1380",
  //   "https://img.freepik.com/free-photo/group-young-students-with-books-chalkboard_1303-20932.jpg?w=1380",
  // ];

  @override
  initState() {
    super.initState();
    _professionalConsultantCategories = widget.professionalConsultantCategories;
    controller_.selectedEducationServiceData.value = widget.selectedProfessionConsultantData;
    controller_.fetchEducationServiceServices();

    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        controller_.fetchEducationServiceServices(isLoadMore: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = [
      StickyCategory(id: 'ALL_OPTION', name: AppStrings.all.tr, imageUrl: AppImageAssets.all),
      ..._professionalConsultantCategories.map((c) => StickyCategory(
            id: c.slugId,
            name: c.name,
            imageUrl: c.icon,
          )),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: BannerCarousel(
                    images: _bannerImages,
                    onBack: () => Navigator.pop(context),
                    statusBarHeight: statusBarHeight,
                    backgroundColor: AppColors.blue5CAF.withValues(alpha: 0.1),
                    bottomBorderSide: const BorderSide(
                      color: AppColors.white,
                      width: 2,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    categories: stickyCategories,
                    selectedId: controller_.selectedEducationServiceData.value?.slugId ?? 'ALL_OPTION',
                    onCategoryTap: (item) {
                      final index = stickyCategories.indexWhere((c) => c.id == item.id);
                      controller_.selectedTabIndex.value = index;
                      controller_.selectedEducationServiceData.value = item.id == 'ALL_OPTION'
                          ? null
                          : _professionalConsultantCategories.firstWhere((c) => c.slugId == item.id);
                      controller_.fetchEducationServiceServices();
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
                _buildListSliver(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(SchoolDetailsData service) {
    final userId = service.ownerId ?? '';
    if (userId.trim().isEmpty) return;
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final bId = service.id?.trim();
    if (bId != null && bId.isNotEmpty) {
      ChatClickTracker.track(
        userId: bId,
        source: ChatClickSource.searchResult,
      );
    }
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.checkChatConnectionAndOpenChat(
      userId: userId,
      name: service.name,
      profile: service.logo,
      route: AppConstants.route_discover,
    );
  }

  Widget _buildListSliver() {
    return Obx(() {
      if (controller_.isEducationServiceLoading.value && controller_.schoolDetailsDataDataList.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller_.schoolDetailsDataDataList.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size24,
              vertical: SizeConfig.size40,
            ),
            child: _NoSchoolsFound(
              title: AppStrings.noSchoolsFound.tr,
              subtitle: AppStrings.noSchoolsFoundSubtitle.tr,
              onRetry: () => controller_.fetchEducationServiceServices(),
            ),
          ),
        );
      }

      final list = controller_.schoolDetailsDataDataList;
      final showMoreLoader = controller_.isEducationServiceLoadingMore.value;
      final rows = buildNativeAdRows(list.length);

      return SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size10,
        ),
        sliver: SliverList.builder(
          itemCount: rows.length + (showMoreLoader ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == rows.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final row = rows[index];
            if (row.isAd) {
              return NativeAdSlot(
                adOrdinal: row.adOrdinal,
                keyPrefix: 'education_service_native_ad',
              );
            }
            return selfProfessionCard(list[row.contentIndex]);
          },
        ),
      );
    });
  }

  Widget selfProfessionCard(SchoolDetailsData service) {
    const String na = 'N/A';

    final List<String> coverImages = <String>[
      ...?service.galleryPhotos?.where((u) => u.trim().isNotEmpty),
    ];
    if (coverImages.isEmpty && (service.bannerUrl ?? '').isNotEmpty) {
      coverImages.add(service.bannerUrl!);
    }
    if (coverImages.isEmpty && (service.logo ?? '').isNotEmpty) {
      coverImages.add(service.logo!);
    }

    final String name = (service.name?.isNotEmpty ?? false) ? service.name! : na;
    final String address = (service.location?.name?.isNotEmpty ?? false) ? service.location!.name! : na;
    final String distance = _distanceFromUser(service);
    final String classRange = (service.classRange?.isNotEmpty ?? false) ? service.classRange! : na;
    final String ratio =
        (service.studentTeacherRatio?.isNotEmpty ?? false) ? service.studentTeacherRatio! : na;
    final String medium =
        (service.mediumOfInstruction?.isNotEmpty ?? false) ? service.mediumOfInstruction!.join(', ') : na;
    final String feeLabel = _buildFeeLabel(service);
    final String feeRange = _buildFeeRange(service);
    final double? ratingValue = service.avgRating;
    final String rating = (ratingValue != null && ratingValue > 0) ? ratingValue.toStringAsFixed(1) : na;

    return InkWell(
      onTap: () {
        // Seed the lighter list item so the header renders instantly; the
        // school home screen then loads the full record from
        // `education-service/schools/{id}` itself (in its initState).
        final schoolAboutUsController = getOrPut(() => SchoolAboutUsController());
        schoolAboutUsController.schoolDetailsData?.value = service;
        Get.to(DiscoverSchoolHomeScreen());
      },
      child: CustomFormCard(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverSection(
              images: coverImages,
              rating: rating,
              service: service,
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(
                    logoUrl: service.logo ?? '',
                    name: name,
                    distance: distance,
                    address: address,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _buildStatsRow(
                    classRange: classRange,
                    ratio: ratio,
                    medium: medium,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _buildFeeRow(label: feeLabel, value: feeRange),
                  SizedBox(height: SizeConfig.size12),
                  _buildActionsRow(service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareSchool(SchoolDetailsData service) async {
    final name = (service.name?.trim().isNotEmpty ?? false) ? service.name!.trim() : 'this school';
    // final address = service.location?.name?.trim() ?? '';
    // final classRange = service.classRange?.trim() ?? '';
    // final mediums = service.mediumOfInstruction?.where((s) => s.trim().isNotEmpty).toList() ?? const [];
    // final fees = service.fees;

    final shareLink = educationProfileDeepLink(userId: service.ownerId);

    final lines = <String>['Check out $name on BlueEra'];
    // if (address.isNotEmpty) lines.add(address);
    // if (classRange.isNotEmpty) lines.add('Classes: $classRange');
    // if (mediums.isNotEmpty) lines.add('Medium: ${mediums.join(', ')}');
    // if (fees != null) lines.add('Annual fee: ${_formatFee(fees)}');
    lines.add(shareLink);

    await ShareService.instance.openShareSheet(
      text: lines.join('\n'),
      subject: name,
    );
  }

  String _distanceFromUser(SchoolDetailsData service) {
    final coords = service.location?.coordinates;
    if (coords == null || coords.length < 2) return 'N/A';
    // GeoJSON convention used by the API + adapter: [lng, lat].
    final lng = coords[0].toDouble();
    final lat = coords[1].toDouble();
    if (lat == 0.0 || lng == 0.0) return 'N/A';
    final km = calculateDistance(lat, lng);
    if (km == null) return 'N/A';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m Away';
    if (km < 10) return '${km.toStringAsFixed(1)}KM Away';
    return '${km.toStringAsFixed(0)}KM Away';
  }

  String _buildFeeLabel(SchoolDetailsData service) {
    if (service.fees != null) return 'Annual fee';
    final courses = service.courses;
    if (courses == null || courses.isEmpty) return 'Annual fee';
    return 'Annual fee · varies by class';
  }

  String _buildFeeRange(SchoolDetailsData service) {
    if (service.fees != null) return '${_formatFee(service.fees!)}/Year';
    final courses = service.courses;
    if (courses == null || courses.isEmpty) return 'N/A';
    final yearly = courses.map((c) => c.courseFees?.yearly).whereType<int>().toList()..sort();
    if (yearly.isEmpty) return 'N/A';
    final min = yearly.first;
    final max = yearly.last;
    if (min == max) return '${_formatFee(min)}/Year';
    return '${_formatFee(min)} - ${_formatFee(max)}/Year';
  }

  String? _operatingWindow(SchoolDetailsData service) {
    final availability = service.availability;
    if (availability == null || availability.isEmpty) return null;
    const order = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const shortNames = {
      'Monday': 'Mon',
      'Tuesday': 'Tue',
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
      'Saturday': 'Sat',
      'Sunday': 'Sun',
    };

    final openSlots = <MapEntry<int, Availability>>[];
    for (var i = 0; i < order.length; i++) {
      final slot = availability.firstWhere(
        (a) => (a.day ?? '').toLowerCase() == order[i].toLowerCase(),
        orElse: () => Availability(),
      );
      if (slot.isOpen == true && (slot.openTime ?? '').isNotEmpty && (slot.closeTime ?? '').isNotEmpty) {
        openSlots.add(MapEntry(i, slot));
      }
    }
    if (openSlots.isEmpty) return null;

    // Group consecutive open-day indexes into contiguous runs.
    final groups = <List<MapEntry<int, Availability>>>[];
    for (final entry in openSlots) {
      if (groups.isEmpty || entry.key != groups.last.last.key + 1) {
        groups.add([entry]);
      } else {
        groups.last.add(entry);
      }
    }

    final dayRange = groups.map((g) {
      final first = shortNames[g.first.value.day] ?? g.first.value.day ?? '';
      final last = shortNames[g.last.value.day] ?? g.last.value.day ?? '';
      return first == last ? first : '$first–$last';
    }).join(', ');

    final firstOpen = openSlots.first.value.openTime!;
    final firstClose = openSlots.first.value.closeTime!;
    final allSame = openSlots.every((e) => e.value.openTime == firstOpen && e.value.closeTime == firstClose);

    if (allSame) return '$dayRange | $firstOpen - $firstClose';
    return '$dayRange | varies';
  }

  String _formatFee(int value) {
    if (value >= 100000) {
      final lakhs = value / 100000;
      final txt = lakhs % 1 == 0 ? lakhs.toStringAsFixed(0) : lakhs.toStringAsFixed(1);
      return '₹${txt}L';
    }
    if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(0)},000';
    }
    return '₹$value';
  }

  Widget _buildCoverSection({
    required List<String> images,
    required String rating,
    required SchoolDetailsData service,
  }) {
    final window = _operatingWindow(service);
    final Widget imageWidget = images.isNotEmpty
        ? GestureDetector(
            onTap: () => navigatePushTo(
              context,
              ImageViewScreen(
                subTitle: service.type ?? AppStrings.education.tr,
                appBarTitle: AppStrings.imageViewer.tr,
                imageUrls: images,
                initialIndex: 0,
              ),
            ),
            child: CachedNetworkImage(
              imageUrl: images.first,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder: (_, __) => LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                boxFix: BoxFit.cover,
              ),
              errorWidget: (_, __, ___) => LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                boxFix: BoxFit.cover,
              ),
            ),
          )
        : Container(
            height: 170,
            width: double.infinity,
            color: AppColors.greyE5,
            child: LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.cover,
            ),
          );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: SizedBox(
        height: 170,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.yellow),
                    const SizedBox(width: 4),
                    CustomText(
                      rating,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _shareSchool(service),
                    child: _circleIcon(AppIconAssets.share_bold),
                  ),
                  const SizedBox(width: 8),
                  _circleIcon(AppIconAssets.star),
                ],
              ),
            ),
            if (window != null)
              Positioned(
                bottom: 10,
                right: 10,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greenShade, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12, color: AppColors.greenShade),
                        const SizedBox(width: 4),
                        Flexible(
                          child: CustomText(
                            window,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _circleIcon(String icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: LocalAssets(
          imagePath: icon,
          imgColor: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildHeaderRow({
    required String logoUrl,
    required String name,
    required String distance,
    required String address,
  }) {
    final String location = [
      if (distance.isNotEmpty) distance,
      if (address.isNotEmpty) address,
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _schoolLogo(logoUrl),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                name,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: CustomText(
                      location,
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow({
    required String classRange,
    required String ratio,
    required String medium,
  }) {
    return Row(
      children: [
        Expanded(child: _statCell(AppIconAssets.classIcon, classRange)),
        SizedBox(width: SizeConfig.size8),
        Expanded(child: _statCell(AppIconAssets.personProfileIcon, ratio)),
        SizedBox(width: SizeConfig.size8),
        Expanded(child: _statCell(AppIconAssets.mediumIcon, medium)),
      ],
    );
  }

  Widget _statCell(String icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        color: AppColors.geryFC,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: icon, imgColor: AppColors.primaryColor),
          const SizedBox(height: 6),
          CustomText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow({required String label, required String value}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5, width: 1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  label,
                  fontSize: 11,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  value,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.skyBlueFF,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomText(
              'View In Details',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(SchoolDetailsData service) {
    return Row(
      children: [
        // Expanded(
        //   flex: 2,
        //   child: InkWell(
        //     onTap: () => _openChat(service),
        //     child: Container(
        //       height: 44,
        //       decoration: BoxDecoration(
        //         color: AppColors.skyBlueFF,
        //         borderRadius: BorderRadius.circular(10),
        //       ),
        //       child: Row(
        //         mainAxisAlignment: MainAxisAlignment.center,
        //         children: [
        //           LocalAssets(imagePath: AppIconAssets.chat, imgColor: AppColors.primaryColor),
        //           const SizedBox(width: 6),
        //           CustomText(
        //             'Chat',
        //             fontSize: 13,
        //             fontWeight: FontWeight.w600,
        //             color: AppColors.primaryColor,
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
        // const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  AppStrings.inquiry.tr,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 16, color: AppColors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _schoolLogo(String url) {
    if (url.isEmpty) return _brokenSchoolLogo();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: SizeConfig.size40,
        height: SizeConfig.size40,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: SizeConfig.size40,
          height: SizeConfig.size40,
          color: AppColors.greyE5,
        ),
        errorWidget: (_, __, ___) => _brokenSchoolLogo(),
      ),
    );
  }

  Widget _brokenSchoolLogo() => Container(
        width: SizeConfig.size40,
        height: SizeConfig.size40,
        decoration: BoxDecoration(
          color: AppColors.greyE5,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.school_outlined,
          size: SizeConfig.size22,
          color: AppColors.secondaryTextColor,
        ),
      );
}

class _NoSchoolsFound extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _NoSchoolsFound({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final illustrationSize = SizeConfig.size80;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: illustrationSize,
          height: illustrationSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.12),
                AppColors.primaryColor.withValues(alpha: 0.04),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.school_outlined,
            size: illustrationSize * 0.5,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        CustomText(
          title,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size8),
        CustomText(
          subtitle,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (onRetry != null) ...[
          SizedBox(height: SizeConfig.size16),
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size20,
                vertical: SizeConfig.size10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: AppColors.white, size: SizeConfig.size18),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    AppStrings.retry.tr,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
