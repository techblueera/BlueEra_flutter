import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/api/model/school_quick_info_field.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../../business/widgets/rating_widget.dart';

/// Card surface for one school tile. The listing is a two-up grid now,
/// so the card is a plain white surface with a hairline border — the
/// tinted wash rotation the single-column card used would fight with
/// the cover images sitting side by side.
const Color _kCardBorder = Color(0xFFE9EBF0);

/// Hairline rule between the highlight cells and the students footer.
const Color _kCardDivider = Color(0xFFEDEFF3);

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
                    // The header paints a search bar; this is what it opens —
                    // the shared store search, scoped to this vertical by its
                    // StoreSearchConfig. Tapping a result opens that profile.
                    onSearchTap: () => Get.to(() => StoreSearchScreen(
                        config: StoreSearchConfig.education())),
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

      // Column count scales with the viewport so the tile keeps a
      // readable width from a small phone up to a tablet in landscape.
      final crossAxisCount = _gridCrossAxisCount();

      // Masonry (not a fixed-ratio grid) because tiles differ in height:
      // a listing with no highlight cells or no students count is
      // shorter than a full one, and masonry packs those without
      // stretching or clipping. Ads stay full-width between chunks.
      return SliverMainAxisGroup(
        slivers: [
          ...buildNativeAdGridSlivers(
            itemCount: list.length,
            keyPrefix: 'education_service_native_ad',
            adPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            gridSliverBuilder: (start, end) => SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size10,
                vertical: SizeConfig.size6,
              ),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: SizeConfig.size10,
                crossAxisSpacing: SizeConfig.size10,
                childCount: end - start,
                itemBuilder: (context, i) =>
                    selfProfessionCard(list[start + i]),
              ),
            ),
          ),
          if (showMoreLoader)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size10)),
        ],
      );
    });
  }

  /// Two tiles on a phone, three on a tablet, four on a wide tablet /
  /// landscape — keeps each tile between roughly 160dp and 220dp wide.
  int _gridCrossAxisCount() {
    final width = SizeConfig.screenWidth;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  Widget selfProfessionCard(SchoolDetailsData service) {
    // Hero shows the cover banner, never the logo. Priority:
    //   1. `coverPicture` — the field the backend now sets for schools
    //      (see the education-service payload sample).
    //   2. `bannerUrl` — legacy field kept for records that haven't been
    //      migrated to `coverPicture` yet.
    //   3. `galleryPhotos` — last resort so a school with no explicit
    //      cover still shows something.
    final List<String> coverImages = <String>[];
    if ((service.coverPicture ?? '').trim().isNotEmpty) {
      coverImages.add(service.coverPicture!.trim());
    }
    if (coverImages.isEmpty && (service.bannerUrl ?? '').trim().isNotEmpty) {
      coverImages.add(service.bannerUrl!.trim());
    }
    if (coverImages.isEmpty) {
      coverImages.addAll(
        service.galleryPhotos?.where((u) => u.trim().isNotEmpty) ??
            const <String>[],
      );
    }

    final String name =
        (service.name?.isNotEmpty ?? false) ? service.name! : '';
    final String numberOfStudents =
        (service.numberOfStudents != null && service.numberOfStudents! > 0)
            ? _formatStudentCount(service.numberOfStudents!)
            : '';
    final double? ratingValue = service.avgRating;
    final String rating = (ratingValue != null && ratingValue > 0)
        ? ratingValue.toStringAsFixed(1)
        : '';

    // Distance + address feed the location line under the meta row —
    // the tile is half a screen wide, so distance wins the space and
    // the address only fills whatever is left over.
    final String distance = _distanceFromUser(service);
    final String address = (service.location?.name?.isNotEmpty ?? false)
        ? service.location!.name!
        : '';

    // Highlight cells show two items. The category's headline field
    // (board / streams / …) is rendered in the meta row above, so it
    // is filtered out of this row via [_buildHighlightCells].
    final highlights = _buildHighlightCells(service);
    final List<String> metaItems = _pillItems(service);
    final String? pillField = _pillFieldFor(service);
    final String metaSuffix = pillField == null ? '' : _suffixForKey(pillField);

    final bool showLocation = distance.isNotEmpty || address.isNotEmpty;
    final bool showMeta = rating.isNotEmpty || metaItems.isNotEmpty;

    return InkWell(
      onTap: () {
        // Routed through openVisitProfile so the type→screen mapping stays in
        // one place. The lighter list item goes with it, so the header renders
        // instantly; the school home screen then loads the full record from
        // `education-service/schools/{id}` itself (in its initState).
        openVisitProfile(
          accountType: AppConstants.business,
          typeOfBusiness: BusinessType.Siksha.name,
          businessId: service.id,
          userId: service.ownerId,
          schoolData: service,
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCardBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F001120),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCoverSection(
              images: coverImages,
              service: service,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size10,
                SizeConfig.size10,
                SizeConfig.size10,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name.isNotEmpty)
                    CustomText(
                      name,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black22,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (showMeta) ...[
                    SizedBox(height: SizeConfig.size4),
                    _buildMetaRow(rating, metaItems, metaSuffix),
                  ],
                  if (showLocation) ...[
                    SizedBox(height: SizeConfig.size4),
                    _buildLocationRow(distance, address),
                  ],
                  if (highlights.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size8),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < highlights.length; i++) ...[
                            if (i > 0) SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child: _statCell(
                                  highlights[i].icon, highlights[i].label),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: SizeConfig.size10),
                ],
              ),
            ),
            if (numberOfStudents.isNotEmpty) ...[
              Container(height: 1, color: _kCardDivider),
              Padding(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: _buildStudentsRow(numberOfStudents),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Which quick-info field is rendered in the header pill row (next
  /// to the rating) per category. Everything else stays in the
  /// two-cell highlights strip below.
  ///
  /// - School / Coaching → boards
  /// - College/University → streams (a.k.a. streams / departments)
  /// - Sports & Hobby → sportsFacilities
  /// - Skill Training / Professional Learn → certifications
  static const Map<String, String> _pillFieldByCategory = {
    'School Education': 'board',
    'Coaching/Institute': 'board',
    'College/University': 'streams',
    'Sports & Hobby': 'sportsFacilities',
    'Professional Learn': 'certifications',
    'Skill Training': 'certifications',
  };

  /// Resolves the pill-row field for a listing. Falls back to `board`
  /// when the category is unknown so legacy school records with
  /// `category: null` still surface their boards.
  String? _pillFieldFor(SchoolDetailsData service) {
    final key =
        resolveQuickInfoCategoryKey(service.quickInfoCategory ?? service.type);
    if (key == null) return 'board';
    return _pillFieldByCategory[key];
  }

  /// Reads the pill field's value from `quickInfoRaw` (preferred) with
  /// the typed-model fallback via [_typedFallback], normalised to a
  /// list of trimmed strings. Empty entries are filtered out — the
  /// caller checks `isEmpty` to hide the pill row entirely.
  List<String> _pillItems(SchoolDetailsData service) {
    final field = _pillFieldFor(service);
    if (field == null) return const <String>[];
    final raw = service.quickInfoRaw ?? const <String, dynamic>{};
    final value = raw[field] ?? _typedFallback(service, field);
    final items = <String>[];
    if (value is List) {
      items.addAll(value
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty));
    } else if (value is String && value.trim().isNotEmpty) {
      items.add(value.trim());
    }
    return items;
  }

  /// Card-only field override — the full `kQuickInfoFieldsByCategory`
  /// schema is what the About-Us controller consumes, but the listing
  /// card only has room for two highlight cells and sometimes wants a
  /// different subset. Categories that appear here bypass the schema
  /// for cell selection; everything else falls through to the schema.
  ///
  /// Each category's pill field ([_pillFieldByCategory]) is filtered
  /// out at iteration time in [_buildHighlightCells] — the lists here
  /// already exclude it too so the intent is explicit.
  ///
  /// School / Coaching also drop `studentTeacherRatio` so the two
  /// visible cells become `classRange` + `mediumOfInstruction`. The
  /// About-Us page still shows the full field list including ratio.
  static const Map<String, List<String>> _cardFieldsByCategory = {
    'School Education': [
      'classRange',
      'mediumOfInstruction',
    ],
    'Coaching/Institute': [
      'classRange',
      'mediumOfInstruction',
    ],
    // Streams moved to the pill row → highlights show courses +
    // affiliated university.
    'College/University': [
      'coursesOffered',
      'affiliatedUniversity',
    ],
    // Facilities moved to the pill row → highlights show sports
    // offered + championships/achievements.
    'Sports & Hobby': [
      'sportsOffered',
      'achievements',
    ],
    // Certifications moved to the pill row → highlights show skill
    // programs + industry partnerships.
    'Professional Learn': [
      'skillPrograms',
      'industryPartnerships',
    ],
    'Skill Training': [
      'skillPrograms',
      'industryPartnerships',
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
  /// case. Empty fields are skipped entirely (no "N/A Board" filler).
  List<_HighlightCell> _buildHighlightCells(SchoolDetailsData service) {
    final resolvedKey =
        resolveQuickInfoCategoryKey(service.quickInfoCategory ?? service.type);
    final schema = resolvedKey != null
        ? (_cardFieldsByCategory[resolvedKey] ??
            kQuickInfoFieldsByCategory[resolvedKey]!)
        : const <String>['classRange', 'mediumOfInstruction'];

    // Whichever field is in the header pill for this category should
    // not also appear as a highlight cell.
    final pillField = _pillFieldFor(service);

    final raw = service.quickInfoRaw ?? const <String, dynamic>{};
    final cells = <_HighlightCell>[];
    for (final key in schema) {
      if (key == 'numberOfStudents') continue; // rendered in the fee row
      if (key == pillField) continue; // rendered in the header pill row
      if (cells.length >= 2) break;
      final value = raw[key] ?? _typedFallback(service, key);
      final label = _formatCellLabel(key, value);
      if (label.isEmpty) continue;
      cells.add(_HighlightCell(
        icon: _iconForKey(key),
        label: label,
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

  /// Compact rendering per field. Single-value fields keep the
  /// "CBSE Board" / "English Medium" style; list-valued fields render
  /// as either one "value Suffix" chip (single item) or up to two
  /// names comma-separated with " …+N" appended for the rest
  /// (2+ items). Returns empty when the source has nothing — the
  /// caller then skips the cell instead of rendering an "N/A" placeholder.
  String _formatCellLabel(String key, dynamic value) {
    final suffix = _suffixForKey(key);
    if (value is List) {
      final items = value
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (items.isEmpty) return '';
      // Single entry keeps the "value Suffix" formatting so a card
      // like Streams=[Science] reads as "Science" (no suffix) or
      // Medium=[English] reads as "English Medium".
      if (items.length == 1) {
        return suffix.isEmpty ? items.first : '${items.first} $suffix';
      }
      // 2+ entries: comma-separate up to two names and append "…+N"
      // for the rest. Suffix dropped — repeating "CBSE Board, State
      // Board" would blow past the cell width.
      const int maxVisible = 2;
      final visible =
          items.length > maxVisible ? items.sublist(0, maxVisible) : items;
      final extra = items.length - visible.length;
      return extra > 0 ? '${visible.join(', ')} …+$extra' : visible.join(', ');
    }
    if (value is num) return '$value $suffix'.trim();
    final str = value?.toString().trim() ?? '';
    if (str.isEmpty) return '';
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

  /// Opens the rating submit dialog for a school listing. The POST target
  /// is the be_user_service `businesses._id` (see
  /// lib/docs/rating-ui-integration.md §1) — the caller must hide the
  /// entry point when it is empty, otherwise the request 404s.
  Future<void> _openRateDialog(SchoolDetailsData service) async {
    final businessId = (service.id ?? '').trim();
    if (businessId.isEmpty) return;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => RatingFeedbackDialog(
        businessId: businessId,
        reviewFor: AppConstants.business,
      ),
    );
    if (submitted == true) {
      controller_.fetchEducationServiceServices();
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

  /// Thousands-separated head count — "25000" reads as "25,000" in the
  /// tile footer.
  String _formatStudentCount(num count) {
    final digits = count.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _distanceFromUser(SchoolDetailsData service) {
    final coords = service.location?.coordinates;
    if (coords == null || coords.length < 2) return '';
    // GeoJSON convention used by the API + adapter: [lng, lat].
    final lng = coords[0].toDouble();
    final lat = coords[1].toDouble();
    if (lat == 0.0 || lng == 0.0) return '';
    final km = calculateDistance(lat, lng);
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m Away';
    if (km < 10) return '${km.toStringAsFixed(1)}KM Away';
    return '${km.toStringAsFixed(0)}KM Away';
  }

  /// Whether the listing is open on the current weekday. The tile has
  /// room for a badge, not a full "Mon–Sat | 9:00 - 17:00" window, so
  /// the cover shows a plain "Open" chip and the full schedule stays on
  /// the school's profile page.
  bool _isOpenToday(SchoolDetailsData service) {
    final availability = service.availability;
    if (availability == null || availability.isEmpty) return false;
    const order = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    // DateTime.weekday is 1 (Monday) … 7 (Sunday) — same order as above.
    final today = order[DateTime.now().weekday - 1].toLowerCase();
    final slot = availability.firstWhere(
      (a) => (a.day ?? '').toLowerCase() == today,
      orElse: () => Availability(),
    );
    return slot.isOpen == true;
  }

  /// Cover uses an [AspectRatio] rather than a fixed height so the
  /// image scales with the tile width — the same card has to work at
  /// two, three or four columns.
  Widget _buildCoverSection({
    required List<String> images,
    required SchoolDetailsData service,
  }) {
    final bool isOpen = _isOpenToday(service);
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
              width: double.infinity,
              fit: BoxFit.cover,
              memCacheWidth: 600,
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
            width: double.infinity,
            color: AppColors.greyE5,
            child: LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.cover,
            ),
          );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            Positioned(
              top: SizeConfig.size6,
              right: SizeConfig.size6,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _shareSchool(service),
                    child: _circleIcon(AppIconAssets.share_bold),
                  ),
                  // Rate CTA is only shown when the listing carries the
                  // be_user_service `businesses._id` (see
                  // lib/docs/rating-ui-integration.md §1) — without it the
                  // POST to /business/{businessId}/ratings would 404.
                  if ((service.id ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size6),
                    GestureDetector(
                      onTap: () => _openRateDialog(service),
                      child: _circleIcon(AppIconAssets.star),
                    ),
                  ],
                ],
              ),
            ),
            if (isOpen)
              Positioned(
                bottom: SizeConfig.size6,
                right: SizeConfig.size6,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size6,
                    vertical: SizeConfig.size3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF2FFF2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.greenShade, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time,
                          size: SizeConfig.size12, color: AppColors.greenShade),
                      SizedBox(width: SizeConfig.size3),
                      CustomText(
                        AppStrings.open.tr,
                        fontSize: SizeConfig.extraSmall,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenShade,
                        maxLines: 1,
                      ),
                    ],
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
      width: SizeConfig.size26,
      height: SizeConfig.size26,
      decoration: const BoxDecoration(
        color: AppColors.black25,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size6),
        child: LocalAssets(
          imagePath: icon,
          imgColor: AppColors.white,
        ),
      ),
    );
  }

  /// Meta line under the school name: `★ 4.8 | CBSE Board | State Board`.
  /// A half-width tile has no room for individual chips, so the rating
  /// and the category's headline values ([_pillItems]) are rendered as
  /// one pipe-separated line that ellipsizes as a whole. Shows up to
  /// two values and appends "+N" for the rest.
  Widget _buildMetaRow(String rating, List<String> items, String suffix) {
    const int maxVisible = 2;
    final visible =
        items.length > maxVisible ? items.sublist(0, maxVisible) : items;
    final extra = items.length - visible.length;

    final labels = <String>[
      for (final item in visible) suffix.isEmpty ? item : '$item $suffix',
      if (extra > 0) '+$extra',
    ];

    final separator = TextSpan(
      text: '  |  ',
      style: TextStyle(
        color: AppColors.greyE5,
        fontSize: SizeConfig.extraSmall,
      ),
    );

    return Row(
      children: [
        if (rating.isNotEmpty) ...[
          LocalAssets(
            imagePath: AppIconAssets.fill_star,
            width: SizeConfig.size12,
            height: SizeConfig.size12,
            imgColor: AppColors.yellow,
          ),
          SizedBox(width: SizeConfig.size3),
          CustomText(
            rating,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.black22,
          ),
        ],
        if (labels.isNotEmpty)
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  for (int i = 0; i < labels.length; i++) ...[
                    if (i > 0 || rating.isNotEmpty) separator,
                    TextSpan(
                      text: labels[i],
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.extraSmall,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Inline distance + " | " + address row — matches
  /// `service_business_card.dart._buildLocationRow` so both discover
  /// cards share the same location styling (pin + primary-coloured
  /// distance + secondary-coloured address).
  Widget _buildLocationRow(String distanceText, String address) {
    return Row(
      children: [
        LocalAssets(
          imagePath: AppIconAssets.location_outline,
          imgColor: AppColors.primaryColor,
          height: SizeConfig.size10,
          width: SizeConfig.size10,
        ),
        SizedBox(width: SizeConfig.size4),
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                if (distanceText.isNotEmpty)
                  TextSpan(
                    text: distanceText,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (distanceText.isNotEmpty && address.isNotEmpty)
                  TextSpan(
                    text: '  |  ',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.extraSmall,
                    ),
                  ),
                if (address.isNotEmpty)
                  TextSpan(
                    text: address,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// One highlight cell — icon stacked above the label so a two-up
  /// tile can still show a full value like "Class 1-12" without
  /// truncating it against a side-by-side icon.
  Widget _statCell(String icon, String label) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed box so mixed-source assets (small SVGs like standard.svg
          // vs. large rasters like stream.png) all read at the same visual
          // weight across cells.
          SizedBox(
            height: SizeConfig.size18,
            width: SizeConfig.size18,
            child: LocalAssets(
              imagePath: icon,
              imgColor: AppColors.grey7E,
              boxFix: BoxFit.contain,
            ),
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: AppColors.black22,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Footer line — "25,000 Students" with the head-count icon in the
  /// brand colour, sitting below the hairline rule.
  Widget _buildStudentsRow(String value) {
    return Row(
      children: [
        SizedBox(
          height: SizeConfig.size18,
          width: SizeConfig.size18,
          child: LocalAssets(
            imagePath: AppIconAssets.multiPersonsIcon,
            imgColor: AppColors.primaryColor,
            boxFix: BoxFit.contain,
          ),
        ),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            // Literal label, same as the "No. Of Students" copy this row
            // replaces — there is no `students` translation key yet.
            '$value Students',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.black22,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
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
