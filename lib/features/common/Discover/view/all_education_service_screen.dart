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
import 'package:BlueEra/features/common/Discover/widget/discover_profile_navigation.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../business/widgets/rating_widget.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/auth/service/chat_click_tracker.dart';

/// Tinted surface set for a school card. Mirrors the palette rotation
/// used by `service_business_card.dart` so both discover directories
/// share the same visual family — the outer wash + border + dashed
/// divider all come from the same palette.
class _CardPalette {
  final Color cardBg;
  final Color cardBorder;
  final Color bodyDashedDivider;

  const _CardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.bodyDashedDivider,
  });
}

/// Two-palette rotation — cards alternate as the user scrolls. Values
/// match the teal / lavender pair in `service_business_card.dart` so
/// the two discover cards read as a set. `bodyDashedDivider` picks a
/// slightly darker shade of the wash so the divider is visible against
/// the card background.
const List<_CardPalette> _schoolCardPalettes = <_CardPalette>[
  _CardPalette(
    cardBg: Color(0xFFEDFCFE),
    cardBorder: Color(0xFFCFEEF2),
    bodyDashedDivider: Color(0xFFBBE3E8),
  ),
  _CardPalette(
    cardBg: Color(0xFFFBF2FF),
    cardBorder: Color(0xFFEDD3F7),
    bodyDashedDivider: Color(0xFFE3D4E9),
  ),
];

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
            return selfProfessionCard(list[row.contentIndex], row.contentIndex);
          },
        ),
      );
    });
  }

  Widget selfProfessionCard(SchoolDetailsData service, int index) {
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
        (service.name?.isNotEmpty ?? false) ? service.name! : '';
    final String numberOfStudents =
        (service.numberOfStudents != null && service.numberOfStudents! > 0)
            ? '${service.numberOfStudents}'
            : '';
    final double? ratingValue = service.avgRating;
    final String rating = (ratingValue != null && ratingValue > 0)
        ? ratingValue.toStringAsFixed(1)
        : '';

    // Distance + address feed the location row under the header pill
    // row — rendered by [_buildLocationRow], matching the exact style
    // used in service_business_card.dart.
    final String distance = _distanceFromUser(service);
    final String address = (service.location?.name?.isNotEmpty ?? false)
        ? service.location!.name!
        : '';

    // Highlight cells now show two items only. The `board` field is
    // rendered above in the header pill row, so it is filtered out of
    // this row via [_buildHighlightCells].
    final highlights = _buildHighlightCells(service);

    // Outer wash rotates per card so adjacent items read as a set,
    // matching the two-palette rotation in service_business_card.dart.
    final palette =
        _schoolCardPalettes[index.abs() % _schoolCardPalettes.length];

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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.cardBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverSection(
              images: coverImages,
              service: service,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  SizeConfig.size12, SizeConfig.size12, SizeConfig.size12, 0),
              child: _buildHeaderRow(
                logoUrl: service.logo ?? '',
                name: name,
                distance: distance,
                address: address,
                rating: rating,
                service: service,
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            _DashedDivider(color: palette.bodyDashedDivider),
            SizedBox(height: SizeConfig.size12),
            if (highlights.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                child: Row(
                  children: [
                    for (int i = 0; i < highlights.length; i++) ...[
                      Expanded(
                        child:
                            _statCell(highlights[i].icon, highlights[i].label),
                      ),
                      if (i != highlights.length - 1)
                        SizedBox(width: SizeConfig.size8),
                    ],
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size10),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(
                  SizeConfig.size12, 0, SizeConfig.size12, SizeConfig.size12),
              child: _buildFeeRow(
                label: 'No. Of Students',
                value: numberOfStudents,
              ),
            ),
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
      final visible = items.length > maxVisible
          ? items.sublist(0, maxVisible)
          : items;
      final extra = items.length - visible.length;
      return extra > 0
          ? '${visible.join(', ')} …+$extra'
          : visible.join(', ');
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
        height: SizeConfig.size200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            Positioned(
              top: 10,
              right: 10,
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
                    SizedBox(height: SizeConfig.size8),
                    GestureDetector(
                      onTap: () => _openRateDialog(service),
                      child: _circleIcon(AppIconAssets.star),
                    ),
                  ],
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
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size10,
                        vertical: SizeConfig.size6),
                    decoration: BoxDecoration(
                      color: Color(0xffF2FFF2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greenShade, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time,
                            size: SizeConfig.size12,
                            color: AppColors.greenShade),
                        SizedBox(width: SizeConfig.size4),
                        Flexible(
                          child: CustomText(
                            window,
                            fontSize: SizeConfig.size12,
                            fontWeight: FontWeight.w500,
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
    required String rating,
    required SchoolDetailsData service,
  }) {
    final bool showLocation = distance.isNotEmpty || address.isNotEmpty;
    final bool showRating = rating.isNotEmpty;
    final List<String> pillItems = _pillItems(service);
    final String? pillField = _pillFieldFor(service);
    final String pillSuffix =
        pillField == null ? '' : _suffixForKey(pillField);
    final bool showPills = pillItems.isNotEmpty;

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
            mainAxisSize: MainAxisSize.min,
            children: [
              if (name.isNotEmpty)
                CustomText(
                  name,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black22,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              //
              Row(
                children: [
                  if (showRating) ...[
                    const SizedBox(height: 6),
                    _buildRatingPill(rating),
                    const SizedBox(width: 6),
                  ],
                  if (showPills)
                    Flexible(child: _buildInfoPillRow(pillItems, pillSuffix)),
                ],
              ),
              if (showLocation) ...[
                const SizedBox(height: 6),
                _buildLocationRow(distance, address),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Rating pill styled to match `service_business_card.dart` so both
  /// discover cards share the same rating badge.
  Widget _buildRatingPill(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffDDE2EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.fill_star,
            width: 10,
            height: 10,
            imgColor: AppColors.yellow,
          ),
          const SizedBox(width: 3),
          CustomText(
            rating,
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  /// Header pill row (sits where `service_business_card.dart` puts
  /// its "Open" pill). Each entry gets its own chip so multi-value
  /// categories (e.g. CBSE + State boards, or Science + Commerce
  /// streams) read as distinct items. Shows up to two chips and
  /// appends a "+N" chip when the listing has more than two.
  /// [suffix] pulls from [_suffixForKey] so schools render "CBSE
  /// Board" while colleges/sports/skills render plain values.
  Widget _buildInfoPillRow(List<String> items, String suffix) {
    const int maxVisible = 2;
    final visible =
        items.length > maxVisible ? items.sublist(0, maxVisible) : items;
    final extra = items.length - visible.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Flexible(
            child: _boardChip(
                suffix.isEmpty ? visible[i] : '${visible[i]} $suffix'),
          ),
        ],
        if (extra > 0) ...[
          const SizedBox(width: 4),
          _boardChip('+$extra'),
        ],
      ],
    );
  }

  /// One rounded chip used inside [_buildInfoPillRow] — same shape as
  /// the rating pill so the row reads as a set. Long labels ellipsize
  /// inside the chip; the parent [Flexible] lets the chip itself
  /// shrink if the header runs out of horizontal room.
  Widget _boardChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffDDE2EE)),
      ),
      child: CustomText(
        label,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryTextColor,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Inline distance + " | " + address row — matches
  /// `service_business_card.dart._buildLocationRow` exactly so both
  /// discover cards share the same location styling (pin +
  /// primary-coloured distance + secondary-coloured address).
  Widget _buildLocationRow(String distanceText, String address) {
    return Row(
      children: [
        LocalAssets(
          imagePath: AppIconAssets.location_outline,
          imgColor: AppColors.primaryColor,
          height: 10,
          width: 10,
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
                      fontSize: SizeConfig.size8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (distanceText.isNotEmpty && address.isNotEmpty)
                  TextSpan(
                    text: '  |  ',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.size8,
                    ),
                  ),
                if (address.isNotEmpty)
                  TextSpan(
                    text: address,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.size8,
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

  Widget _statCell(String icon, String label) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
          SizedBox(width: SizeConfig.size6),
          // Flexible so long labels (e.g. "English, Hindi …+2")
          // ellipsize inside the cell instead of overflowing the Row.
          Flexible(
            child: CustomText(
              label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.grey7E,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow({required String label, required String value}) {
    final hasValue = value.isNotEmpty;
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          hasValue
              ? Container(
                  padding: EdgeInsets.all(SizeConfig.size6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(24),
                    // border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: LocalAssets(
                    imagePath: AppIconAssets.multiPersonsIcon,
                    imgColor: AppColors.primaryColor,
                  ),
                )
              : SizedBox.shrink(),
          SizedBox(width: SizeConfig.size6),
          Expanded(
            child: hasValue
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        label,
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                      // const SizedBox(height: 2),
                      CustomText(
                        value,
                        fontSize: SizeConfig.size16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(6),
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

  // Figma spec: 50×50 avatar (matches CachedAvatarWidget size used in
  // service_business_card.dart).
  static const double _schoolLogoSize = 50;

  Widget _schoolLogo(String url) {
    if (url.isEmpty) return _brokenSchoolLogo();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: _schoolLogoSize,
        height: _schoolLogoSize,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: _schoolLogoSize,
          height: _schoolLogoSize,
          color: AppColors.greyE5,
        ),
        errorWidget: (_, __, ___) => _brokenSchoolLogo(),
      ),
    );
  }

  Widget _brokenSchoolLogo() => Container(
        width: _schoolLogoSize,
        height: _schoolLogoSize,
        decoration: BoxDecoration(
          color: AppColors.greyE5,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.school_outlined,
          size: SizeConfig.size28,
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

/// Full-width dashed horizontal rule. Copied verbatim from
/// `service_business_card.dart` so both discover cards share the
/// same divider treatment between the header block and body.
class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(color: color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  static const double _dashWidth = 4;
  static const double _dashSpace = 4;
  static const double _thickness = 1;

  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _thickness
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      final endX = (x + _dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(endX, y), paint);
      x += _dashWidth + _dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
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
