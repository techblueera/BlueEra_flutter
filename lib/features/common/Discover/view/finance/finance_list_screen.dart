import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/business/widgets/rating_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/finance_search_res_model.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_profile_navigation.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Tinted surface set for a finance card. Mirrors the palette used by the
/// hotel `PropertyCard` (and `ServiceBusinessCard` / lab discover) so all
/// discover directories share the same visual family — the outer card is
/// the lighter wash, the inner "Account Types" tile uses white per design.
class _CardPalette {
  final Color cardBg;
  final Color cardBorder;
  final Color tileBorder;
  final Color dividerLine;
  final Color bodyDashedDivider;

  const _CardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.tileBorder,
    required this.dividerLine,
    required this.bodyDashedDivider,
  });
}

const List<_CardPalette> _cardPalettes = <_CardPalette>[
  _CardPalette(
    cardBg: Color(0xFFEDFCFE),
    cardBorder: Color(0xFFCFEEF2),
    tileBorder: Color(0xFFBFE9EE),
    dividerLine: Color(0xFFBFE9EE),
    bodyDashedDivider: Color(0xFFBBE3E8),
  ),
  _CardPalette(
    cardBg: Color(0xFFFBF2FF),
    cardBorder: Color(0xFFEDD3F7),
    tileBorder: Color(0xFFE5C6F5),
    dividerLine: Color(0xFFE5C6F5),
    bodyDashedDivider: Color(0xFFE3D4E9),
  ),
];

class FinanceListScreen extends StatefulWidget {
  final String categorySlugId;

  const FinanceListScreen({super.key, required this.categorySlugId});

  @override
  State<FinanceListScreen> createState() => _FinanceListScreenState();
}

class _FinanceListScreenState extends State<FinanceListScreen> {
  late final FinanceDiscoverController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => FinanceDiscoverController());
    controller.fetchInitial(widget.categorySlugId);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return false;
    if (metrics.pixels >= metrics.maxScrollExtent - 200) {
      controller.fetchMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
            "No services found",
            fontSize: SizeConfig.medium,
            color: AppColors.grey9B,
          ),
        );
      }
      return RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () async {
          await controller.fetchInitial(widget.categorySlugId);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: Builder(
            builder: (context) {
              final rows = buildNativeAdRows(controller.profiles.length);
              return ListView.builder(
                itemCount:
                    rows.length + (controller.isLoadingMore.value ? 1 : 0),
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index == rows.length) {
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: SizeConfig.size12),
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryColor)),
                    );
                  }
                  final row = rows[index];
                  if (row.isAd) {
                    return NativeAdSlot(
                      adOrdinal: row.adOrdinal,
                      keyPrefix: 'finance_native_ad',
                    );
                  }
                  final item = controller.profiles[row.contentIndex];
                  return _FinanceCard(item: item, index: row.contentIndex);
                },
              );
            },
          ),
        ),
      );
    });
  }
}

class _FinanceCard extends StatelessWidget {
  final FinanceBusinessItem item;

  /// Card position in the list — drives the palette rotation.
  final int index;

  const _FinanceCard({required this.item, required this.index});

  _CardPalette get _palette =>
      _cardPalettes[index.abs() % _cardPalettes.length];

  @override
  Widget build(BuildContext context) {
    final String address = _resolveAddress(item);
    final String category = item.category ?? item.type ?? '';

    // Hero shows the cover banner, never the logo. Falls back to gallery
    // images only when the business hasn't uploaded a cover yet.
    final List<String> coverImages = <String>[];
    if ((item.coverUrl ?? '').isNotEmpty) {
      coverImages.add(item.coverUrl!);
    }
    if (coverImages.isEmpty && item.gallery != null) {
      for (final g in item.gallery!) {
        if (g.imageUrls != null) {
          coverImages.addAll(g.imageUrls!.where((u) => u.trim().isNotEmpty));
        }
      }
    }

    final double? ratingValue = item.rating;
    final String rating = (ratingValue != null && ratingValue > 0)
        ? ratingValue.toStringAsFixed(1)
        : '';

    final String distance = _distanceFromUser(item);
    final ({String label, Color color}) openBadge = _todayOpenBadge(item);
    final String registryLabel =
        item.rbiRegistered == true ? 'RBI Registered' : 'Not RBI Reg.';
    final Color registryColor =
        item.rbiRegistered == true ? AppColors.greenShade : AppColors.grey83;

    final List<String> serviceTags = <String>[
      ...?item.accountType?.where((s) => s.trim().isNotEmpty),
    ];
    final bool showTagsRow =
        serviceTags.isNotEmpty || category.trim().isNotEmpty;

    final palette = _palette;

    return Padding(
      padding: EdgeInsets.only(right: SizeConfig.size8, bottom: SizeConfig.size10, left: SizeConfig.size8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Routed through openVisitProfile so the type→screen mapping stays in
        // one place. The lightweight list item goes with it and seeds
        // `selectedDetail`, so the detail screen renders at once and upgrades
        // itself to the full record.
        onTap: () => openVisitProfile(
          accountType: AppConstants.business,
          typeOfBusiness: BusinessType.Finance.name,
          businessId: item.businessProfileId ?? item.id,
          userId: item.userId,
          financeData: item,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.cardBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14001120),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(images: coverImages),
              _buildBody(
                palette: palette,
                address: address,
                distance: distance,
                rating: rating,
                registryLabel: registryLabel,
                registryColor: registryColor,
                openLabel: openBadge.label,
                openColor: openBadge.color,
                showTagsRow: showTagsRow,
                serviceTags: serviceTags,
                category: category,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required _CardPalette palette,
    required String address,
    required String distance,
    required String rating,
    required String registryLabel,
    required Color registryColor,
    required String openLabel,
    required Color openColor,
    required bool showTagsRow,
    required List<String> serviceTags,
    required String category,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(SizeConfig.size14, SizeConfig.size12, SizeConfig.size14, 0),
          child: _buildHeaderRow(
            address: address,
            distance: distance,
            rating: rating,
            registryLabel: registryLabel,
            registryColor: registryColor,
            openLabel: openLabel,
            openColor: openColor,
          ),
        ),
        if (showTagsRow) ...[
          SizedBox(height: SizeConfig.size12),
          _DashedDivider(color: palette.bodyDashedDivider),
          SizedBox(height: SizeConfig.size12),
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size14, 0, SizeConfig.size14, 0),
            child: _buildTagsWrap(
              serviceTags: serviceTags,
              category: category,
            ),
          ),
        ],
        SizedBox(height: SizeConfig.size14),
        Padding(
          padding: EdgeInsets.fromLTRB(SizeConfig.size14, 0, SizeConfig.size14, SizeConfig.size10),
          child: _buildFooterRow(),
        ),
      ],
    );
  }

  String _resolveAddress(FinanceBusinessItem item) {
    // Mirror the header (visit_business_common_header.dart:318): pipe the
    // resolved address through `getLocalityAddress` so both surfaces show
    // the same "<locality>, <city>" truncation instead of the full string.
    final candidates = <String?>[
      item.location?.address,
      item.location?.name,
    ];
    for (final c in candidates) {
      final t = c?.trim() ?? '';
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  Future<void> _openRateDialog() async {
    final businessId = (item.businessId ?? '').trim();
    if (businessId.isEmpty) return;
    final ctx = Get.context;
    if (ctx == null) return;
    final submitted = await showDialog<bool>(
      context: ctx,
      builder: (_) => RatingFeedbackDialog(
        businessId: businessId,
        reviewFor: AppConstants.business,
      ),
    );
    if (submitted == true) {
      final controller = Get.find<FinanceDiscoverController>();
      controller.fetchInitial(controller.selectedCategory.value);
    }
  }

  Future<void> _shareFinance(FinanceBusinessItem item) async {
    final name = (item.profileName?.trim().isNotEmpty ?? false)
        ? item.profileName!.trim()
        : 'this finance service';
    final address = _resolveAddress(item);
    final website = item.effectiveWebsite ?? '';

    final lines = <String>['Check out $name on BlueEra'];
    if (address.isNotEmpty) lines.add(address);
    if (item.rbiRegistered == true) lines.add('RBI Registered');
    final types =
        item.accountType?.where((s) => s.trim().isNotEmpty).toList() ??
            const [];
    if (types.isNotEmpty) lines.add('Accounts: ${types.join(', ')}');
    if (website.isNotEmpty) lines.add(website);
    final shareLink = financialDeepLink(
      businessId: item.userId,
    );

    await ShareService.instance.openShareSheet(
      text:
          "Check out ${item.profileName ?? 'this profile'} on BlueEra:\n$shareLink",
      subject: item.profileName,
    );
  }

  /// Opens a chat with the finance business owner — same behaviour as the
  /// hospital list card: guest gate, chat-click tracking against the business
  /// id, then opens the discover chat lane.
  void _openChat() {
    final userId = item.userId ?? '';
    if (userId.trim().isEmpty) return;
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final bId = item.id?.trim();
    if (bId != null && bId.isNotEmpty) {
      ChatClickTracker.track(
        userId: bId,
        source: ChatClickSource.searchResult,
      );
    }
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.checkChatConnectionAndOpenChat(
      userId: userId,
      name: item.profileName,
      profile: item.logoUrl,
      route: AppConstants.route_discover,
    );
  }

  String _distanceFromUser(FinanceBusinessItem item) {
    // Match the header (visit_business_common_header.dart:297): always show
    // `X.XX KM`, no unit-tiered rewrite, no "Away" suffix. Coords come from
    // the GeoJSON `[lng, lat]` array on the finance model (the header pulls
    // from named lat/lon fields on BusinessProfileDetails). Empty string
    // signals "no distance" so the header row hides that slice entirely.
    final coords = item.contactUs?.firstOrNull?.branch?.location?.coordinates ??
        item.location?.coordinates;
    if (coords == null || coords.length < 2) return '';
    final lng = coords[0];
    final lat = coords[1];
    if (lat == 0.0 || lng == 0.0) return '';
    final km = calculateDistance(lat, lng);
    if (km == null) return '';
    return '${km.toStringAsFixed(2)} KM';
  }

  Widget _hero({required List<String> images}) {
    final Widget imageWidget = images.isNotEmpty
        ? GestureDetector(
            onTap: () => Get.to(() => ImageViewScreen(
                  subTitle: item.type ?? 'Finance',
                  appBarTitle: AppStrings.imageViewer,
                  imageUrls: images,
                  initialIndex: 0,
                )),
            child: CachedNetworkImage(
              imageUrl: images.first,
              height: 175,
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
            height: 175,
            width: double.infinity,
            color: AppColors.liteWhite,
            child: LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.cover,
            ),
          );

    return SizedBox(
      height: 175,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _circleIconBtn(AppIconAssets.share_bold,
                    onTap: () => _shareFinance(item)),
                // Rate CTA is only shown when the listing carries the
                // be_user_service `businesses._id` (see
                // lib/docs/rating-ui-integration.md §1) — without it the
                // POST to /business/{businessId}/ratings would 404.
                if ((item.businessId ?? '').trim().isNotEmpty) ...[
                  SizedBox(height: SizeConfig.size8),
                  _circleIconBtn(AppIconAssets.star_rounded,
                      onTap: _openRateDialog),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn(String icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size8),
          child: LocalAssets(
            imagePath: icon,
            imgColor: AppColors.white,
            height: SizeConfig.size14,
            width: SizeConfig.size14,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow({
    required String address,
    required String distance,
    required String rating,
    required String registryLabel,
    required Color registryColor,
    required String openLabel,
    required Color openColor,
  }) {
    bool isMeaningful(String s) => s.isNotEmpty && s != 'N/A';
    final bool showDistance = isMeaningful(distance);
    final bool showAddress = isMeaningful(address);
    final bool hasLocation = showDistance || showAddress;
    final bool hasRating = rating.isNotEmpty;
    // Time pill hides when the source only produces "Open | N/A" — the
    // finance model returns that string for listings that never set hours,
    // and rendering it inline looks broken next to real values.
    final bool hasTime = !openLabel.trim().endsWith('N/A');
    final bool hasPillsRow = hasRating || hasTime;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo / name open the owning business profile; the rest of the
        // card still opens the finance listing detail.
        DiscoverProfileTap(
          accountType: AppConstants.business,
          businessId: item.businessProfileId,
          userId: item.userId,
          child: ClipOval(
            child: Container(
              width: 50,
              height: 50,
              color: AppColors.liteWhite,
              child: (item.logoUrl?.isNotEmpty ?? false)
                  ? CachedNetworkImage(
                      imageUrl: item.logoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => LocalAssets(
                          imagePath: AppIconAssets.place_holder_image),
                      errorWidget: (_, __, ___) => LocalAssets(
                          imagePath: AppIconAssets.place_holder_image),
                    )
                  : LocalAssets(imagePath: AppIconAssets.place_holder_image),
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DiscoverProfileTap(
                accountType: AppConstants.business,
                businessId: item.businessProfileId,
                userId: item.userId,
                child: CustomText(
                  (item.profileName?.isNotEmpty ?? false)
                      ? item.profileName
                      : 'Unknown',
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black22,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasPillsRow) ...[
                SizedBox(height: SizeConfig.size6),
                // Rating + RBI + time pill on the same row. `Wrap` handles
                // the long-time-pill overflow case so the row spills to a
                // second line instead of clipping.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (hasRating) _ratingPill(rating),
                    _pill(
                      icon: Icons.verified_outlined,
                      label: registryLabel,
                      color: registryColor,
                    ),
                    if (hasTime)
                      _pill(
                        icon: Icons.access_time,
                        label: openLabel,
                        color: openColor,
                      ),
                  ],
                ),
              ],
              if (hasLocation) ...[
                SizedBox(height: SizeConfig.size6),
                Row(
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
                            if (showDistance)
                              TextSpan(
                                text: distance,
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: SizeConfig.size8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (showDistance && showAddress)
                              TextSpan(
                                text: '  |  ',
                                style: TextStyle(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.size8,
                                ),
                              ),
                            if (showAddress)
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
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Bordered rating pill — matches the hotel / lab / service-business
  /// cards. Caller gates on rating being non-empty.
  Widget _ratingPill(String rating) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffDDE2EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.fill_star,
            width: SizeConfig.size10,
            height: SizeConfig.size10,
            imgColor: AppColors.yellow,
          ),
          SizedBox(width: SizeConfig.size3),
          CustomText(
            rating,
            fontSize: SizeConfig.size10,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  /// Compact icon+label pill used for both the RBI-status chip and the
  /// today's-hours chip on the rating row.
  Widget _pill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          SizedBox(width: SizeConfig.size3),
          CustomText(
            label,
            fontSize: SizeConfig.size10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ],
      ),
    );
  }

  /// Derives an "Open | HH:MM - HH:MM" / "Closed today" / N/A pill from
  /// the per-day `timings` payload, with a fallback to the legacy
  /// `businessHours` object when `timings` is absent.
  ({String label, Color color}) _todayOpenBadge(FinanceBusinessItem item) {
    final today = item.timings?.forWeekday(DateTime.now().weekday);
    if (today != null) {
      if (today.hasHours) {
        return (
          label: 'Open | ${today.openTime} - ${today.closeTime}',
          color: AppColors.greenShade,
        );
      }
      return (label: 'Closed today', color: AppColors.grey83);
    }
    final bh = item.businessHours;
    if (bh?.hasHours == true) {
      return (
        label: 'Open | ${bh!.openTime} - ${bh.closeTime}',
        color: AppColors.greenShade,
      );
    }
    return (label: 'Open | N/A', color: AppColors.grey83);
  }

  // ── Account Types — bare Wrap of white chips ─────────────────
  /// No outer tile container per design — just the chips sitting directly
  /// on the card's tint. Each chip's fill is white so the account-type
  /// pills read clearly against the pastel card background.
  Widget _buildTagsWrap({
    required List<String> serviceTags,
    required String category,
  }) {
    final tags = serviceTags.isNotEmpty
        ? serviceTags
        : (category.isNotEmpty
            ? [category.replaceAll('_', ' ').capitalize ?? category]
            : <String>[]);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map(_tagChip).toList(growable: false),
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE2EE), width: 0.5),
      ),
      child: CustomText(
        label,
        fontSize: SizeConfig.size12,
        fontWeight: FontWeight.w600,
        color: AppColors.grey7E,
      ),
    );
  }

  /// Full-width Inquiry button — kept as the original: height 44, primary
  /// fill, "Inquiry" (14 w600) + arrow_forward (18). The outer grey band
  /// has been dropped so the row inherits the card's tint, but the button
  /// itself is unchanged.
  Widget _buildFooterRow() {
    return Material(
      color: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => openVisitProfile(
          accountType: AppConstants.business,
          typeOfBusiness: BusinessType.Finance.name,
          businessId: item.businessProfileId ?? item.id,
          userId: item.userId,
          financeData: item,
        ),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                AppStrings.inquiry.tr,
                fontSize: SizeConfig.size14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
              SizedBox(width: SizeConfig.size6),
              Icon(Icons.arrow_forward,
                  size: SizeConfig.size18, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width dashed horizontal rule between the header block and the
/// Account Types tile — matches the hotel `PropertyCard` treatment.
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

