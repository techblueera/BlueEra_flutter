import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_availability_widget.dart';
import 'package:BlueEra/features/business/widgets/rating_widget.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Display fields sourced from the `/other-service/business-profile/{id}/full`
/// endpoint. When passed to [VisitBusinessHero.overrides], each non-null
/// field takes priority over the same field read from
/// [VisitBusinessHero.details]. This lets the finance and other-service
/// detail screens render the hero directly from their `/full` payload
/// (via [FinanceDiscoverController.selectedDetail] or
/// [OtherServiceBusinessSearchController.selectedDetail]) instead of the
/// stale/partial shared business-profile endpoint.
///
/// Only the fields the hero renders are here — anything else (management,
/// gallery, contactUs, etc.) belongs on the parent screen's body, not the
/// hero.
class VisitBusinessHeroOverrides {
  final String? coverUrl;
  final String? logoUrl;
  final String? businessName;
  final String? chipLabel;
  final double? avgRating;
  final int? totalRatings;
  final String? address;
  final String? description;
  final double? latitude;
  final double? longitude;

  /// Passed to the rate dialog. On the `/full` payload this is
  /// `profile.businessId` (be_user_service `businesses._id`).
  final String? businessId;

  /// Passed to the follow / share buttons and deep-link builder. On the
  /// `/full` payload this is `profile.userId`.
  final String? userId;

  /// Initial follow state — the shared business-profile controller owns
  /// this normally, but if the caller has a fresher value from the /full
  /// flow it can pass it here.
  final bool? isFollowing;

  const VisitBusinessHeroOverrides({
    this.coverUrl,
    this.logoUrl,
    this.businessName,
    this.chipLabel,
    this.avgRating,
    this.totalRatings,
    this.address,
    this.description,
    this.latitude,
    this.longitude,
    this.businessId,
    this.userId,
    this.isFollowing,
  });
}

/// Edge-to-edge business hero used by the Discover visitor detail screens
/// (others service, finance, school, hotel). Renders the cover photo, an
/// overlay app-bar (back / rate / share), avatar + follow pill straddling
/// the cover, and the identity block below (name, category chip, rating,
/// address + distance, availability, description, stats card).
///
/// Because it embeds its own back button, host screens should omit
/// `Scaffold.appBar` and set `extendBodyBehindAppBar: true`.
class VisitBusinessHero extends StatefulWidget {
  final BusinessProfileDetails? details;
  final VoidCallback? onFollowChanged;
  final VoidCallback? onRated;

  /// Category-specific timings override. When non-null and non-empty this
  /// replaces `details.availability?.schedule` in the availability row —
  /// used by the Discover education / other-service / finance detail
  /// screens whose canonical timings live on their own endpoints
  /// (`/education-service/schools/{id}/timings`,
  /// `/other-service/business-profile/{id}/full`) rather than on the
  /// user-service availability document. Every other host (hotel, lab,
  /// healthcare) keeps passing `null` and falls back to the user-service
  /// schedule as before.
  final List<Schedule>? scheduleOverride;

  /// Optional field-by-field overrides sourced from the `/full` endpoint
  /// (see [VisitBusinessHeroOverrides]). When a field is non-null on the
  /// override it wins over the same field on [details]; when it's null the
  /// hero falls back to [details] as before. Used by the finance and
  /// other-service detail screens so the hero reflects the authoritative
  /// `/full` payload rather than the shared business-profile endpoint.
  final VisitBusinessHeroOverrides? overrides;

  const VisitBusinessHero({
    super.key,
    required this.details,
    this.onFollowChanged,
    this.onRated,
    this.scheduleOverride,
    this.overrides,
  });

  @override
  State<VisitBusinessHero> createState() => _VisitBusinessHeroState();
}

class _VisitBusinessHeroState extends State<VisitBusinessHero> {
  final _storeController = getOrPut(() => StoreController());
  final RxBool _isFollowed = false.obs;
  bool _descExpanded = false;

  BusinessProfileDetails? get details => widget.details;

  @override
  void initState() {
    super.initState();
    _isFollowed.value =
        widget.overrides?.isFollowing ?? widget.details?.is_following ?? false;
  }

  @override
  void didUpdateWidget(covariant VisitBusinessHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync when the parent supplies a refreshed profile (pull-to-refresh
    // or silent post-follow reload). Guard against clobbering a pending
    // optimistic toggle by only syncing when the server value actually
    // changed. Prefer the override when the caller provides one.
    final newValue =
        widget.overrides?.isFollowing ?? widget.details?.is_following ?? false;
    final oldValue = oldWidget.overrides?.isFollowing ??
        oldWidget.details?.is_following ??
        false;
    if (oldValue != newValue && _isFollowed.value != newValue) {
      _isFollowed.value = newValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = details;
    final o = widget.overrides;
    // Override wins when non-null/non-empty; otherwise fall back to the
    // shared business-profile fields.
    String pickString(String? overrideVal, String fallback) {
      final ov = overrideVal?.trim() ?? '';
      return ov.isNotEmpty ? ov : fallback;
    }

    final name = pickString(o?.businessName, (d?.businessName ?? '').trim());
    final subCategoryName = (d?.subCategoryDetails?.name ?? '').trim();
    final detailsChip = subCategoryName.isNotEmpty
        ? subCategoryName
        : (d?.categoryOfBusiness ?? '').trim();
    final chipLabel = pickString(o?.chipLabel, detailsChip);
    final avgRating = o?.avgRating ?? d?.avg_rating;
    final totalRatings = o?.totalRatings ?? (d?.total_ratings ?? 0).toInt();
    final address = pickString(o?.address, (d?.address ?? '').trim());
    final description =
        pickString(o?.description, (d?.businessDescription ?? '').trim());
    final lat = o?.latitude ?? d?.businessLocation?.lat?.toDouble() ?? 0.0;
    final lng = o?.longitude ?? d?.businessLocation?.lon?.toDouble() ?? 0.0;
    final distanceKm = calculateDistance(lat, lng);
    final hasDistance = distanceKm != null && distanceKm > 0;
    final override = widget.scheduleOverride;
    final effectiveSchedule = (override != null && override.isNotEmpty)
        ? override
        : d?.availability?.schedule;
    final hasAvailability =
        effectiveSchedule != null && effectiveSchedule.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCover(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  CustomText(
                    name,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (chipLabel.isNotEmpty || totalRatings > 0) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (chipLabel.isNotEmpty) _buildChip(chipLabel),
                      if (totalRatings > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFB400), size: 16),
                            const SizedBox(width: 3),
                            CustomText(
                              '${avgRating?.toStringAsFixed(1) ?? '0.0'} ($totalRatings reviews)',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
                if (address.isNotEmpty || hasDistance) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.location_outline,
                          height: 15,
                          width: 15,
                          imgColor: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        if (hasDistance) ...[
                          CustomText(
                            '${distanceKm.toStringAsFixed(0)} KM',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 1,
                            height: 12,
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.35),
                          ),
                        ],
                        Expanded(
                          child: CustomText(
                            address,
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hasAvailability) ...[
                  const SizedBox(height: 12),
                  BusinessAvailabilityWidget(
                    hasAvailability: true,
                    schedule: effectiveSchedule,
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDescription(description),
                ],
                const SizedBox(height: 12),
                VisitBusinessStatsCard(details: d),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    const coverBodyHeight = 180.0;
    // Extra room below the cover so straddling widgets (avatar, follow
    // pill) live INSIDE the Stack bounds — otherwise Flutter's hit-test
    // stops at the parent's bounds and the follow pill draws but can't
    // be tapped, even with clipBehavior: Clip.none.
    const straddleBelow = 40.0;
    final topInset = MediaQuery.of(context).padding.top;
    final coverHeight = coverBodyHeight + topInset;
    final stackHeight = coverHeight + straddleBelow;
    final overrideCover = widget.overrides?.coverUrl?.trim() ?? '';
    final coverUrl = overrideCover.isNotEmpty
        ? overrideCover
        : (details?.coverimage ?? '').trim();
    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: coverHeight,
            width: double.infinity,
            child: coverUrl.isEmpty
                ? _coverFallback()
                : CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _coverFallback(),
                    errorWidget: (_, __, ___) => _coverFallback(),
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + 60,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom scrim — anchored to the cover-image edge, not the
          // stack bottom (which sits `straddleBelow` px lower).
          Positioned(
            left: 0,
            right: 0,
            bottom: straddleBelow,
            height: 70,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _glassButton(
                  icon: AppIconAssets.back_arrow,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                _glassButton(
                  icon: AppIconAssets.star_rounded,
                  onTap: _onRateTap,
                ),
                const SizedBox(width: 8),
                _glassButton(
                  icon: AppIconAssets.share_bold,
                  onTap: _onShareTap,
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            bottom: straddleBelow - 32,
            child: _buildAvatar(),
          ),
          Positioned(
            right: 14,
            bottom: 0,
            child: _buildFollowPill(),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required String icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.black25,
          shape: BoxShape.circle,
        ),
        child: LocalAssets(
          imagePath: icon,
          imgColor: AppColors.white,
          height: 16,
          width: 16,
        ),
      ),
    );
  }

  Future<void> _onRateTap() async {
    final overrideBusinessId = widget.overrides?.businessId?.trim() ?? '';
    final businessId = overrideBusinessId.isNotEmpty
        ? overrideBusinessId
        : (details?.id ?? '').trim();
    if (businessId.isEmpty) return;
    final success = await showDialog(
      context: context,
      builder: (_) => RatingFeedbackDialog(
        businessId: businessId,
        reviewFor: AppConstants.business,
      ),
    );
    if (success == true) widget.onRated?.call();
  }

  Future<void> _onShareTap() async {
    final overrideName = widget.overrides?.businessName?.trim() ?? '';
    final name = overrideName.isNotEmpty
        ? overrideName
        : (details?.businessName ?? 'this profile').trim();
    final userIdForLink =
        widget.overrides?.userId?.trim().isNotEmpty ?? false
            ? widget.overrides!.userId
            : details?.userId;
    final link = serviceDeepLinkBusiness(id: userIdForLink);
    await ShareService.instance.openShareSheet(
      text: 'Check out $name on BlueEra:\n$link',
      subject: name,
    );
  }

  Widget _buildAvatar() {
    final overrideLogo = widget.overrides?.logoUrl?.trim() ?? '';
    final logoUrl = overrideLogo.isNotEmpty
        ? overrideLogo
        : (details?.logo ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: 64,
          height: 64,
          child: logoUrl.isEmpty
              ? _avatarFallback()
              : CachedNetworkImage(
                  imageUrl: logoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _avatarFallback(),
                  errorWidget: (_, __, ___) => _avatarFallback(),
                ),
        ),
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

  Widget _avatarFallback() => Container(
        color: AppColors.greyLite,
        child: Icon(
          Icons.storefront_rounded,
          color: AppColors.secondaryTextColor,
          size: 26,
        ),
      );

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.grey7E,
        ),
      ),
      child: CustomText(
        label,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.grey7E,
      ),
    );
  }

  Widget _buildFollowPill() {
    return Obx(() {
      final followed = _isFollowed.value;
      // Prefer override ids (from /full) when supplied; otherwise fall back
      // to the shared business-profile ids.
      final overrideBusinessId = widget.overrides?.businessId?.trim() ?? '';
      final overrideUserId = widget.overrides?.userId?.trim() ?? '';
      final businessId = overrideBusinessId.isNotEmpty
          ? overrideBusinessId
          : details?.id;
      final ownerUserId =
          overrideUserId.isNotEmpty ? overrideUserId : details?.userId;
      return GestureDetector(
        onTap: () async {
          if (isGuestUser()) {
            createProfileScreen();
            return;
          }
          final store = GetAllStoreResModel(
            id: businessId,
            userId: ownerUserId,
          );
          if (followed) {
            await _storeController.unFollowBusinessUser(
              businessId: ownerUserId,
              store: store,
            );
            _isFollowed.value = false;
          } else {
            await _storeController.followBusinessUser(
              businessId: ownerUserId,
              store: store,
            );
            _isFollowed.value = true;
          }
          widget.onFollowChanged?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: followed ? Colors.white : AppColors.primaryColor,
            borderRadius: BorderRadius.circular(24),
            border: followed ? Border.all(color: AppColors.greyE5) : null,
            boxShadow: [
              BoxShadow(
                color: (followed ? Colors.black : AppColors.primaryColor)
                    .withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                followed ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
                size: 15,
                color: followed ? AppColors.secondaryTextColor : Colors.white,
              ),
              const SizedBox(width: 4),
              CustomText(
                followed ? AppStrings.unfollow : AppStrings.follow,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: followed ? AppColors.secondaryTextColor : Colors.white,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDescription(String description) {
    const collapsedLines = 3;
    final style = TextStyle(
      fontSize: 12.5,
      color: AppColors.secondaryTextColor,
      height: 1.4,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: description, style: style),
          maxLines: collapsedLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = tp.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              maxLines: _descExpanded ? null : collapsedLines,
              overflow:
                  _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: style,
            ),
            if (overflows) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _descExpanded = !_descExpanded),
                child: CustomText(
                  _descExpanded ? 'Read Less' : 'Read More',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
