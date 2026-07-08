import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/widget/service_enquiry_sheet.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/share_service.dart';
class SelfEmployeeViewDiscoverScreen extends StatefulWidget {
  final ServiceData? service;
  final String? userId;
  final bool isSelfPreview;

  const SelfEmployeeViewDiscoverScreen({
    super.key,
    this.service,
    this.userId,
    this.isSelfPreview = false,
  });

  @override
  State<SelfEmployeeViewDiscoverScreen> createState() => _SelfEmployeeViewDiscoverScreenState();
}

class _SelfEmployeeViewDiscoverScreenState extends State<SelfEmployeeViewDiscoverScreen> {
  ServiceData? _service;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    log("🔎 SelfEmployeeViewDiscover service data → ${_service?.toJson()}");
    if (_service == null && (widget.userId?.isNotEmpty ?? false)) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final controller = getOrPut(() => DiscoverController());
    final result = await controller.getEarnServiceByUserId(widget.userId!);
    log("🔎 SelfEmployeeViewDiscover fetched service data → ${result?.toJson()}");
    if (!mounted) return;
    setState(() {
      _service = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    if (service != null) {
      return _SelfEmployeeContent(
        service: service,
        isSelfPreview: widget.isSelfPreview,
        userId: service.id ?? widget.userId,
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // leading: Icon(Icons.arrow_back_ios_new),
        iconTheme: const IconThemeData(color: AppColors.mainTextColor,),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined, size: 48, color: AppColors.secondaryTextColor),
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    AppStrings.noDataFound.tr,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Refined provider profile — cover hero, identity block, a price/hours
/// ribbon, editorial section cards, a weekly availability schedule, and a
/// sticky price + booking CTA.
class _SelfEmployeeContent extends StatelessWidget {
  final ServiceData service;
  final bool isSelfPreview;
  final String? userId;

  const _SelfEmployeeContent({
    required this.service,
    this.isSelfPreview = false,
    this.userId,
  });

  static const _accent = LinearGradient(
    colors: [AppColors.blue5CAF, AppColors.primaryColor],
  );

  // ── Display values derived from [service] ──────────────────────────────
  // Previously these were computed at every call site and passed in as four
  // separate params; now the screen owns the derivation so callers only need
  // to hand over the [ServiceData].
  bool get _isRange => service.priceData?.effectiveIsRange ?? false;

  String get priceDisplay {
    final p = service.priceData;
    final min = p?.effectiveMin ?? 0;
    final max = p?.effectiveMax ?? 0;
    // No usable price → blank (preserves the self-preview's empty price and
    // avoids showing a misleading "₹0" for providers without a rate).
    if (min == 0 && max == 0) return '';
    return _isRange
        ? '₹${formatIndianNumber(min)}-${formatIndianNumber(max)}'
        : '₹${formatIndianNumber(min)}';
  }

  /// Price for display with a dash fallback so the ribbon / bottom bar never
  /// render an empty slot when the provider hasn't set a rate.
  String get priceDisplayOrDash => priceDisplay.isNotEmpty ? priceDisplay : '--';

  /// Non-empty timing/text fallback — server may send null or empty strings.
  String _orDash(String? value) =>
      (value != null && value.trim().isNotEmpty) ? value : '--';

  String get priceBadgeText =>
      (service.priceData?.feeType ?? service.priceData?.priceType ?? '').capitalizeFirst ?? '';

  Color get priceBadgeColor => _isRange ? AppColors.green1A : AppColors.primaryColor;

  Map<String, String> get timingMap => _getMinMaxTimings(service.service?.effectiveTimings);

  Map<String, String> _getMinMaxTimings(List<Timings>? timingsList) {
    if (timingsList == null || timingsList.isEmpty) {
      return {'start': '--', 'end': '--'};
    }
    Timings? earliest = timingsList.first;
    Timings? latest = timingsList.first;
    for (final t in timingsList) {
      if (_parse12HourTime(t.start ?? '00:00 AM').isBefore(_parse12HourTime(earliest?.start ?? '00:00 AM'))) {
        earliest = t;
      }
      if (_parse12HourTime(t.end ?? '00:00 AM').isAfter(_parse12HourTime(latest?.end ?? '00:00 AM'))) {
        latest = t;
      }
    }
    return {'start': earliest?.start ?? '--', 'end': latest?.end ?? '--'};
  }

  DateTime _parse12HourTime(String timeStr) {
    final match = RegExp(r'(\d+):(\d+)\s*(AM|PM)').firstMatch(timeStr.trim());
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3);
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return DateTime(0, 1, 1, hour, minute);
    }
    return DateTime(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: isSelfPreview ? null : _buildBottomBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: SizeConfig.size12),
        child: Column(
          children: [
            // Shared white backdrop behind the hero + stats ribbon so both
            // read as one continuous white header block.
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.0)),
              ),
              child: Column(
                children: [
                  _buildHeaderSection(context),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.size12,
                      SizeConfig.size4,
                      SizeConfig.size12,
                      SizeConfig.size12,
                    ),
                    child: _buildStatsRibbon(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size12,
                SizeConfig.size12,
                SizeConfig.size12,
                0,
              ),
              child: Builder(
                builder: (_) {
                  final sectionWidgets = _joinWithGap(
                    _sections(),
                    gap: SizedBox(height: SizeConfig.size12),
                  );
                  // Provider hasn't filled any service details yet → show a
                  // friendly placeholder instead of a blank area.
                  if (sectionWidgets.isEmpty) return _buildEmptyDetails();
                  return Column(children: sectionWidgets);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shown when the provider has no service details filled in yet.
  Widget _buildEmptyDetails() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F001022),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 26,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            'No details added yet',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            "This provider hasn't added their service details yet.",
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTIONS — each renders only when it carries data.
  // ─────────────────────────────────────────────────────────────
  List<Widget> _sections() {
    final svc = service.service;
    return [
      // Availability sits right under the price/time ribbon.
      if (svc?.availability?.schedule?.isNotEmpty ?? false) _buildAvailabilityCard(svc!.availability!),
      if (svc?.serviceType?.isNotEmpty == true)
        _buildChipsCard(
          icon: Icons.business_center_outlined,
          title: 'Service Type',
          items: svc!.serviceType!,
        ),
      if (svc?.expertise?.isNotEmpty == true)
        _buildChipsCard(
          icon: Icons.workspace_premium_outlined,
          title: AppStrings.expertiseLabel.tr,
          items: svc!.expertise!,
        ),
      if (svc?.serviceOffered?.isNotEmpty == true)
        _buildBulletCard(
          icon: Icons.handyman_outlined,
          title: 'Services Offered',
          items: svc!.serviceOffered!,
          checked: true,
        ),
      if (svc?.typesOfWork?.isNotEmpty == true)
        _buildChipsCard(
          icon: Icons.construction_outlined,
          title: 'Types of Work',
          items: svc!.typesOfWork!,
        ),
      if (svc?.workCategories?.isNotEmpty == true)
        _buildChipsCard(
          icon: Icons.category_outlined,
          title: 'Work Categories',
          items: svc!.workCategories!,
        ),
      if (svc?.whyChooseMe?.isNotEmpty == true)
        _buildBulletCard(
          icon: Icons.verified_outlined,
          title: 'Why Choose Me',
          items: svc!.whyChooseMe!,
          checked: true,
        ),
      if (svc?.facilities?.isNotEmpty == true)
        _buildBulletCard(
          icon: Icons.description_outlined,
          title: AppStrings.serviceDescription.tr,
          items: svc!.facilities!,
        ),
      if (service.skills?.isNotEmpty == true)
        _buildChipsCard(
          icon: Icons.psychology_outlined,
          title: 'Skills',
          items: service.skills!,
        ),
      if (service.experiences?.isNotEmpty == true)
        _buildBulletCard(
          icon: Icons.work_outline_rounded,
          title: AppStrings.workExperience.tr,
          items: service.experiences!,
        ),
      if (service.serviceMedia?.photos?.isNotEmpty == true)
        _section(
          icon: Icons.photo_library_outlined,
          title: AppStrings.gallery.tr,
          child: SocialGalleryGrid(imageUrls: service.serviceMedia!.photos!),
        ),
    ];
  }

  // ─────────────────────────────────────────────────────────────
  // HERO — cover image + scrim + glass controls + ringed avatar.
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeaderSection(BuildContext context) {
    final profileImage = service.profileImage ?? '';
    final topInset = MediaQuery.of(context).padding.top;
    const coverHeight = 210.0;

    return SizedBox(
      height: coverHeight + topInset + 44, // room for the straddling avatar
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover image
          SizedBox(
            height: coverHeight + topInset,
            width: double.infinity,
            child: profileImage.isEmpty
                ? _coverFallback()
                : CachedNetworkImage(
                    imageUrl: profileImage,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _coverFallback(),
                    errorWidget: (_, __, ___) => _coverFallback(),
                  ),
          ),
          // Legibility scrim (top for the controls, bottom for the seam)
          Positioned.fill(
            bottom: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.32),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.28),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Top bar: back + share
          Positioned(
            top: topInset + 6,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                _glassButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                _glassButton(
                  assetPath: AppIconAssets.profile_share,
                  onTap: () async {
                    final id = userId ?? service.id;
                    if (id == null || id.isEmpty) return;
                    await ShareService.instance.shareProfile(
                      userId: id,
                      subject: service.name,
                    );
                  },
                ),
              ],
            ),
          ),
          // Straddling avatar with ring + online dot
          Positioned(
            left: SizeConfig.size16,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CachedAvatarWidget(
                    imageUrl: profileImage,
                    size: SizeConfig.size80,
                    borderColor: Colors.transparent,
                    borderRadius: SizeConfig.size40,
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
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

  Widget _coverFallback() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.blue5CAF, AppColors.primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  Widget _glassButton({
    IconData? icon,
    String? assetPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: icon != null
            ? Icon(icon, color: Colors.white, size: 19)
            : LocalAssets(
                imagePath: assetPath!,
                width: 17,
                height: 17,
                imgColor: Colors.white,
              ),
      ),
    );
  }

  // Identity block — name / profession pill / rating / bio.
  Widget _buildIdentity() {
    final name = (service.name ?? '').trim();
    final profession = (service.profession ?? '').trim();
    final designation = (service.designation ?? '').trim();
    final bio = (service.bio ?? '').trim();
    final eyebrow = designation.isNotEmpty ? designation : profession;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size10,
        SizeConfig.size16,
        SizeConfig.size4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow.isNotEmpty)
            Text(
              eyebrow.toUpperCase(),
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
                letterSpacing: 1.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (eyebrow.isNotEmpty) SizedBox(height: SizeConfig.size4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (name.isNotEmpty)
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: AppConstants.OpenSans,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (profession.isNotEmpty) ...[
                SizedBox(width: SizeConfig.size8),
                _professionPill(profession),
              ],
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          CommonRatingRow(
            rating: double.tryParse(service.rating.toString()) ?? 0.0,
            reviews: service.reviewCount ?? 0,
            distance: '${service.distance ?? 0} ${AppStrings.km.tr}',
          ),
          if (bio.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size10),
            ExpandableText(
              text: bio,
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
    );
  }

  Widget _professionPill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.25)),
      ),
      child: CustomText(
        text,
        fontSize: SizeConfig.small,
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PRICE / HOURS RIBBON — price emphasised, open/close flanking it.
  // ─────────────────────────────────────────────────────────────
  Widget _buildStatsRibbon() {
    return Column(
      children: [
        _buildIdentity(),
        SizedBox(height: SizeConfig.size12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14, vertical: SizeConfig.size14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.primaryColor.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: const Color(0xFFEDEFF4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F001022),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _statBlock(
                icon: Icons.payments_outlined,
                color: priceBadgeColor,
                label: AppStrings.priceLabel.tr,
                value: priceDisplayOrDash,
                hint: priceBadgeText.isNotEmpty ? priceBadgeText : null,
                emphasised: true,
              ),
              _ribbonDivider(),
              _statBlock(
                icon: Icons.wb_sunny_outlined,
                color: const Color(0xFF16A34A),
                label: AppStrings.opens.tr,
                value: _orDash(timingMap['start']),
              ),
              _ribbonDivider(),
              _statBlock(
                icon: Icons.nightlight_outlined,
                color: AppColors.redB4,
                label: AppStrings.closes.tr,
                value: _orDash(timingMap['end']),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ribbonDivider() => Container(
        width: 1,
        height: 44,
        margin: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
        color: AppColors.greyE5,
      );

  Widget _statBlock({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? hint,
    bool emphasised = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          SizedBox(height: SizeConfig.size6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: CustomText(
              value,
              fontSize: emphasised ? 15 : 13,
              fontWeight: FontWeight.w800,
              color: emphasised ? color : AppColors.mainTextColor,
            ),
          ),
          const SizedBox(height: 2),
          CustomText(
            (hint ?? label).toUpperCase(),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryTextColor,
            letterSpacing: 0.6,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION SHELL — spec-sheet panel: a gradient accent spine marks
  // each header, the title reads in title-case, and list sections
  // carry a count badge. A hairline rule splits header from content.
  // ─────────────────────────────────────────────────────────────
  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
    int? count,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEEF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size16,
          SizeConfig.size14,
          SizeConfig.size16,
          SizeConfig.size16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Accent spine — the section marker that ties the
                // detail panels together without repeating a boxed icon.
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: _accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Icon(icon, size: 18, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppConstants.OpenSans,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count != null && count > 0) ...[
                  SizedBox(width: SizeConfig.size8),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      '$count',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            Container(height: 1, color: const Color(0xFFF0F2F6)),
            SizedBox(height: SizeConfig.size14),
            child,
          ],
        ),
      ),
    );
  }

  // ─── Chips card ───
  Widget _buildChipsCard({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    final values = items.where((e) => e.trim().isNotEmpty).toList();
    if (values.isEmpty) return const SizedBox.shrink();
    return _section(
      icon: icon,
      title: title,
      count: values.length,
      child: _ExpandableChips(items: values, collapsedCount: 6),
    );
  }

  // ─── Bulleted list card (dot, or a check badge for benefit lists) ───
  Widget _buildBulletCard({
    required IconData icon,
    required String title,
    required List<String> items,
    bool checked = false,
  }) {
    final values = items.where((e) => e.trim().isNotEmpty).toList();
    if (values.isEmpty) return const SizedBox.shrink();
    return _section(
      icon: icon,
      title: title,
      count: values.length,
      child: _ExpandableBullets(items: values, checked: checked, collapsedCount: 4),
    );
  }

  // ─── Weekly availability — day rows with Open/Closed pills + Today tag ───
  Widget _buildAvailabilityCard(Availability availability) {
    final days = availability.schedule ?? const <DaySchedule>[];
    if (days.isEmpty) return const SizedBox.shrink();
    final today = _todayName();
    return _section(
      icon: Icons.calendar_month_outlined,
      title: 'Availability',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: days.map((d) {
          final dayName = d.day ?? '';
          final isToday = dayName.toLowerCase() == today.toLowerCase();
          final slots = (d.timeSlots ?? const <TimeSlot>[])
              .where((s) => (s.startTime ?? '').isNotEmpty && (s.endTime ?? '').isNotEmpty)
              .map((s) => '${_format24(s.startTime)} – ${_format24(s.endTime)}')
              .join(',  ');
          final isOpen = (d.isOpen == true) && slots.isNotEmpty;
          return Container(
            margin: EdgeInsets.only(bottom: SizeConfig.size6),
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size8),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isToday ? Border.all(color: AppColors.primaryColor.withValues(alpha: 0.18)) : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          dayName,
                          fontSize: SizeConfig.small,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isToday ? AppColors.primaryColor : AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomText(
                    isOpen ? slots : 'Closed',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                    color: isOpen ? AppColors.secondaryTextColor : AppColors.redB4,
                  ),
                ),
                _openClosedPill(isOpen),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _openClosedPill(bool isOpen) {
    final color = isOpen ? const Color(0xFF16A34A) : AppColors.redB4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          CustomText(
            isOpen ? 'Open' : 'Closed',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STICKY BOTTOM BAR — price summary + gradient booking CTA.
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size12,
        SizeConfig.size16,
        SizeConfig.size14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.greyE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                priceDisplayOrDash,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              CustomText(
                priceBadgeText.isNotEmpty ? 'Per ${priceBadgeText.toLowerCase()}' : 'Starting price',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: GestureDetector(
              onTap: () => ServiceEnquirySheet.open(context, service),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  gradient: _accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.chat,
                      width: 19,
                      height: 19,
                      imgColor: Colors.white,
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      AppStrings.enquire.tr,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────
  String _todayName() {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[DateTime.now().weekday - 1];
  }

  // 24-hour ("10:00") → 12-hour ("10:00 AM"); leaves already-12h strings as-is.
  String _format24(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final t = raw.trim();
    if (RegExp(r'(AM|PM)', caseSensitive: false).hasMatch(t)) return t;
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return t;
    final period = h >= 12 ? 'PM' : 'AM';
    var hour12 = h % 12;
    if (hour12 == 0) hour12 = 12;
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }

  // Inserts `gap` between every rendered child; absent (shrink) sections still
  // get a gap, so filter them before joining.
  List<Widget> _joinWithGap(List<Widget> items, {required Widget gap}) {
    final visible = items.where((w) => w is! SizedBox || w.height != 0).toList();
    if (visible.isEmpty) return const [];
    final result = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      if (i > 0) result.add(gap);
      result.add(visible[i]);
    }
    return result;
  }
}

// ─────────────────────────────────────────────────────────────
// EXPANDABLE CHIP LIST — collapses long chip sets (expertise,
// service type, work categories …) to a few rows with a
// Show more / Show less toggle.
// ─────────────────────────────────────────────────────────────
class _ExpandableChips extends StatefulWidget {
  final List<String> items;
  final int collapsedCount;

  const _ExpandableChips({required this.items, this.collapsedCount = 6});

  @override
  State<_ExpandableChips> createState() => _ExpandableChipsState();
}

class _ExpandableChipsState extends State<_ExpandableChips> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final showToggle = items.length > widget.collapsedCount;
    final visible = (!_expanded && showToggle)
        ? items.take(widget.collapsedCount).toList()
        : items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: SizeConfig.size8,
          runSpacing: SizeConfig.size8,
          children: visible
              .map((e) => Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFE6EAF0)),
                    ),
                    child: CustomText(
                      e,
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ))
              .toList(),
        ),
        if (showToggle)
          _ShowMoreToggle(
            expanded: _expanded,
            hiddenCount: items.length - widget.collapsedCount,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EXPANDABLE BULLET LIST — collapses long bullet sets (services
// offered, why choose me …) with a Show more / Show less toggle.
// ─────────────────────────────────────────────────────────────
class _ExpandableBullets extends StatefulWidget {
  final List<String> items;
  final bool checked;
  final int collapsedCount;

  const _ExpandableBullets({
    required this.items,
    this.checked = false,
    this.collapsedCount = 4,
  });

  @override
  State<_ExpandableBullets> createState() => _ExpandableBulletsState();
}

class _ExpandableBulletsState extends State<_ExpandableBullets> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final showToggle = items.length > widget.collapsedCount;
    final visible = (!_expanded && showToggle)
        ? items.take(widget.collapsedCount).toList()
        : items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visible.length; i++)
          Padding(
            padding: EdgeInsets.only(
                bottom: i == visible.length - 1 ? 0 : SizeConfig.size12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.checked)
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 13, color: AppColors.primaryColor),
                  )
                else
                  // Blueprint-margin dash marker for plain lists.
                  Container(
                    margin: const EdgeInsets.only(top: 9.0),
                    width: 12,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: CustomText(
                    visible[i],
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mainTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        if (showToggle)
          _ShowMoreToggle(
            expanded: _expanded,
            hiddenCount: items.length - widget.collapsedCount,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
      ],
    );
  }
}

// Shared "Show more (N) / Show less" toggle used by the expandable cards.
class _ShowMoreToggle extends StatelessWidget {
  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;

  const _ShowMoreToggle({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(top: SizeConfig.size12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              expanded ? 'Show less' : 'Show $hiddenCount more',
              fontSize: SizeConfig.small,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(width: 2),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
