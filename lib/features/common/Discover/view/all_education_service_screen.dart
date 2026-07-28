import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/api/model/school_quick_info_field.dart';
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
import 'package:BlueEra/features/common/Discover/widget/discover_profile_navigation.dart';
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
      {super.key,
      required this.professionalConsultantCategories,
      this.selectedProfessionConsultantData});

  @override
  State<AllEducationServiceScreen> createState() =>
      _AllEducationServiceScreenState();
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
    controller_.selectedEducationServiceData.value =
        widget.selectedProfessionConsultantData;
    controller_.fetchEducationServiceServices();

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller_.fetchEducationServiceServices(isLoadMore: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = [
      StickyCategory(
          id: 'ALL_OPTION',
          name: AppStrings.all.tr,
          imageUrl: AppImageAssets.all),
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
                    selectedId: controller_
                            .selectedEducationServiceData.value?.slugId ??
                        'ALL_OPTION',
                    onCategoryTap: (item) {
                      final index =
                          stickyCategories.indexWhere((c) => c.id == item.id);
                      controller_.selectedTabIndex.value = index;
                      controller_.selectedEducationServiceData.value =
                          item.id == 'ALL_OPTION'
                              ? null
                              : _professionalConsultantCategories
                                  .firstWhere((c) => c.slugId == item.id);
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
      if (controller_.isEducationServiceLoading.value &&
          controller_.schoolDetailsDataDataList.isEmpty) {
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

    // Hero shows the cover banner, never the logo. Falls back to gallery
    // photos only when the school hasn't uploaded a banner yet.
    final List<String> coverImages = <String>[];
    if ((service.bannerUrl ?? '').isNotEmpty) {
      coverImages.add(service.bannerUrl!);
    }
    if (coverImages.isEmpty) {
      coverImages.addAll(
        service.galleryPhotos?.where((u) => u.trim().isNotEmpty) ??
            const <String>[],
      );
    }

    final String name =
        (service.name?.isNotEmpty ?? false) ? service.name! : na;
    final String address = (service.location?.name?.isNotEmpty ?? false)
        ? service.location!.name!
        : na;
    final String distance = _distanceFromUser(service);
    final String numberOfStudents =
        (service.numberOfStudents != null && service.numberOfStudents! > 0)
            ? '${service.numberOfStudents}'
            : na;
    final double? ratingValue = service.avgRating;
    final String rating = (ratingValue != null && ratingValue > 0)
        ? ratingValue.toStringAsFixed(1)
        : na;

    // Three category-appropriate highlight cells for the stats row. For
    // a School listing this yields Class Range / Board / Medium; for a
    // Sports listing → Sports Offered / Facilities / Achievements; etc.
    final highlights = _buildHighlightCells(service);

    return InkWell(
      onTap: () {
        // Seed the lighter list item so the header renders instantly; the
        // school home screen then loads the full record from
        // `education-service/schools/{id}` itself (in its initState).
        final schoolAboutUsController =
            getOrPut(() => SchoolAboutUsController());
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
                    service: service,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  if (highlights.isNotEmpty)
                    Row(
                      children: [
                        for (int i = 0; i < highlights.length; i++) ...[
                          Expanded(
                            child: _statCell(
                                highlights[i].icon, highlights[i].label),
                          ),
                          if (i != highlights.length - 1)
                            SizedBox(width: SizeConfig.size8),
                        ],
                      ],
                    ),
                  SizedBox(height: SizeConfig.size12),
                  _buildFeeRow(
                    label: 'No Of Student',
                    value: numberOfStudents,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card-only field override — the full `kQuickInfoFieldsByCategory`
  /// schema is what the About-Us controller consumes, but the listing
  /// card only has room for three highlight cells and sometimes wants
  /// a different subset. Categories that appear here bypass the schema
  /// for cell selection; everything else falls through to the schema.
  static const Map<String, List<String>> _cardFieldsByCategory = {
    'College/University': [
      'coursesOffered',
      'affiliatedUniversity',
      'streams',
    ],
  };

  /// Pick up to 3 highlight cells for the stats row based on the
  /// listing's category. Draws keys from [_cardFieldsByCategory] when a
  /// card-specific list is defined, otherwise from
  /// [kQuickInfoFieldsByCategory] (skipping `numberOfStudents`, which
  /// gets its own dedicated row) and reads each value from
  /// `service.quickInfoRaw`. Falls back to school-flavoured defaults
  /// when the category isn't resolvable — that's what the old card
  /// showed, so this keeps behaviour identical for the historical
  /// case.
  List<_HighlightCell> _buildHighlightCells(SchoolDetailsData service) {
    const na = 'N/A';
    final resolvedKey =
        resolveQuickInfoCategoryKey(service.quickInfoCategory ?? service.type);
    final schema = resolvedKey != null
        ? (_cardFieldsByCategory[resolvedKey] ??
            kQuickInfoFieldsByCategory[resolvedKey]!)
        : const <String>['classRange', 'board', 'mediumOfInstruction'];

    final raw = service.quickInfoRaw ?? const <String, dynamic>{};
    final cells = <_HighlightCell>[];
    for (final key in schema) {
      if (key == 'numberOfStudents') continue; // rendered in the fee row
      if (cells.length >= 3) break;
      final value = raw[key] ?? _typedFallback(service, key);
      cells.add(_HighlightCell(
        icon: _iconForKey(key),
        label: _formatCellLabel(key, value, na),
      ));
    }
    return cells;
  }

  /// Fall back to the typed mirror on [SchoolDetailsData] when
  /// `quickInfoRaw` doesn't have the key — e.g. records that came in
  /// via the school-home flow before we started preserving the raw
  /// map.
  dynamic _typedFallback(SchoolDetailsData s, String key) {
    switch (key) {
      case 'classRange':
        return s.classRange;
      case 'studentTeacherRatio':
        return s.studentTeacherRatio;
      case 'board':
        return s.boards;
      case 'mediumOfInstruction':
        return s.mediumOfInstruction;
      default:
        return null;
    }
  }

  /// Compact suffix rendering per field, matching the previous card's
  /// "CBSE Board" / "English Medium" style but generalised to any
  /// list/string/number value.
  String _formatCellLabel(String key, dynamic value, String na) {
    final suffix = _suffixForKey(key);
    if (value is List) {
      if (value.isEmpty) return _labelForKey(key, na);
      final head = value.first.toString();
      if (value.length == 1) return suffix.isEmpty ? head : '$head $suffix';
      return suffix.isEmpty
          ? '${value.length} ${_labelForKey(key, '').trim()}'
          : '${value.length} ${suffix}s';
    }
    if (value is num) return '$value ${_labelForKey(key, '').trim()}'.trim();
    final str = value?.toString().trim() ?? '';
    if (str.isEmpty) return _labelForKey(key, na);
    return suffix.isEmpty ? str : '$str $suffix';
  }

  /// Human suffix appended to a value, e.g. "Board" → "CBSE Board".
  /// Empty when the value is self-describing (course names, sports).
  String _suffixForKey(String key) {
    switch (key) {
      case 'board':
        return 'Board';
      case 'mediumOfInstruction':
        return 'Medium';
      case 'studentTeacherRatio':
        return 'Ratio';
      default:
        return '';
    }
  }

  /// Placeholder label when a field is empty ("N/A Board", "N/A Medium").
  String _labelForKey(String key, String na) {
    final suffix = _suffixForKey(key);
    return suffix.isEmpty ? na : '$na $suffix';
  }

  String _iconForKey(String key) {
    switch (key) {
      // School Education / Coaching — unchanged per request.
      case 'classRange':
        return AppIconAssets.classIcon;
      case 'board':
        return AppIconAssets.personProfileIcon;
      case 'mediumOfInstruction':
        return AppIconAssets.mediumIcon;
      case 'studentTeacherRatio':
        return AppIconAssets.personProfileIcon;
      // College/University-specific fields (per kQuickInfoFieldsByCategory).
      case 'coursesOffered':
        return AppIconAssets.standardIcon;
      case 'affiliatedUniversity':
        return AppIconAssets.affiliatedUniversityIcon;
      case 'streams':
        return AppIconAssets.streamsIcon;
      // Sports & Hobby fields.
      case 'sportsOffered':
        return AppIconAssets.sportsOfferedIcon;
      case 'sportsFacilities':
        return AppIconAssets.sportsFacilitiesIcon;
      case 'achievements':
        return AppIconAssets.achievementsIcon;
      // Skill Training / Professional Learn fields.
      case 'skillPrograms':
        return AppIconAssets.skillsIcon;
      case 'industryPartnerships':
        return AppIconAssets.industryPartnershipsIcon;
      case 'certifications':
        return AppIconAssets.certificationsIcon;
      default:
        // Any key we haven't mapped yet (e.g. coursesOffered) still falls
        // back to the generic classes icon.
        return AppIconAssets.classIcon;
    }
  }

  Future<void> _shareSchool(SchoolDetailsData service) async {
    final name = (service.name?.trim().isNotEmpty ?? false)
        ? service.name!.trim()
        : 'this school';
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
      if (slot.isOpen == true &&
          (slot.openTime ?? '').isNotEmpty &&
          (slot.closeTime ?? '').isNotEmpty) {
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
    final allSame = openSlots.every((e) =>
        e.value.openTime == firstOpen && e.value.closeTime == firstClose);

    if (allSame) return '$dayRange | $firstOpen - $firstClose';
    return '$dayRange | varies';
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
                  color: AppColors.black25,
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
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _shareSchool(service),
                    child: _circleIcon(AppIconAssets.share_bold),
                  ),
                  const SizedBox(height: 8),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xffF2FFF2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greenShade, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: AppColors.greenShade),
                        const SizedBox(width: 4),
                        Flexible(
                          child: CustomText(
                            window,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greenShade,
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
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.black25,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: LocalAssets(
          imagePath: icon,
          imgColor: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildHeaderRow({
    required String logoUrl,
    required String name,
    required String distance,
    required String address,
    required SchoolDetailsData service,
  }) {
    final String location = [
      if (distance.isNotEmpty) distance,
      if (address.isNotEmpty) address,
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo / name open the school's business profile; the rest of
        // the card still opens the school detail page.
        DiscoverProfileTap(
          accountType: AppConstants.business,
          businessId: service.id,
          userId: service.ownerId,
          child: _schoolLogo(logoUrl),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiscoverProfileTap(
                accountType: AppConstants.business,
                businessId: service.id,
                userId: service.ownerId,
                child: CustomText(
                  name,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: SizeConfig.size2),
              Row(
                children: [
                  LocalAssets(
                      imagePath: AppIconAssets.location_outline,
                      imgColor: AppColors.primaryColor,
                      height: 14,
                      width: 14),
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

  Widget _statCell(String icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size6,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: AppColors.geryFC,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed box so mixed-source assets (small SVGs like standard.svg
          // vs. large rasters like stream.png) all read at the same visual
          // weight across cells.
          SizedBox(
            height: 20,
            width: 20,
            child: LocalAssets(
              imagePath: icon,
              height: 20,
              width: 20,
              imgColor: AppColors.primaryColor,
              boxFix: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 6),
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
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
          border: Border.all(color: Color(0xffDDE2EE), width: 0.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  label,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
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
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  "Inquiry Now",
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward,
                    size: 16, color: AppColors.white),
              ],
            ),
          )
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
                const Icon(Icons.arrow_forward,
                    size: 16, color: AppColors.white),
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

/// Value class for one stat cell rendered in the education card's
/// stats row. Just a bundle of icon + preformatted label — kept
/// private since only [selfProfessionCard] emits these.
class _HighlightCell {
  final String icon;
  final String label;
  const _HighlightCell({required this.icon, required this.label});
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
                  Icon(Icons.refresh,
                      color: AppColors.white, size: SizeConfig.size18),
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
