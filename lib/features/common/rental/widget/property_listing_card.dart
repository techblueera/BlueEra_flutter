import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/rental/model/property_model.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:BlueEra/features/common/rental/view/property_details_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Single card layout used on both the Discover feed and the Owner
/// "My Listings" screen. Visuals match the design spec from the
/// product image: hero photo with an action chip + pagination dots +
/// "+N" overlay, a tappable address row that opens the route-map
/// bottom sheet on Discover, a split price / area row, and a soft
/// grey footer with the lister's identity and chat / call shortcuts.
///
/// Owner-side difference: the chat + call shortcuts are hidden, the
/// hero-action chip becomes the 3-dots delete menu instead of share.
/// Everything else is identical so owners see exactly how their
/// listing reads to potential renters.
class PropertyListingCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final bool isOwner;
  final VoidCallback? onDeleted;

  const PropertyListingCard({
    super.key,
    required this.property,
    required this.onTap,
    this.isOwner = false,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _hero(context),
              _titleAndLocation(),
              // const _SoftDivider(),
              _stats(),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HERO ────────────────────────────────────────────────────────

  Widget _hero(BuildContext context) {
    final images = property.propertyImages;
    return _HeroPager(
      images: images,
      placeholder: _placeholder(),
      topRightAction: _topActionChip(context),
      topLeftBadge: _ratingBadge(),
    );
  }

  /// Rating pill shown at the top-left of the hero photo (matches the
  /// design: amber star + value on a translucent dark pill with a light
  /// outline). Hidden when the listing has no rating yet.
  Widget? _ratingBadge() {
    // if (property.rating <= 0) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mainTextColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15, color: AppColors.rating),
          const SizedBox(width: 4),
          CustomText(
            property.rating.toStringAsFixed(1),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _topActionChip(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isOwner) {
          _showOwnerMenu(context);
        } else {
          _shareListing();
        }
      },
      // Slimmer translucent disc — matches the lighter "+N" tile
      // styling below so the two hero affordances read as a set
      // instead of one solid primary button competing with the photo.
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.mainTextColor.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        // Owner → 3-dot menu; Discover → reel share icon.
        child: isOwner
            ? const Icon(Icons.more_vert_rounded, size: 16, color: Colors.white)
            : LocalAssets(
                imagePath: AppIconAssets.reelShare,
                height: 16,
                width: 16,
                imgColor: Colors.white,
              ),
      ),
    );
  }


  // ─── TITLE + LOCATION ───────────────────────────────────────────

  Widget _titleAndLocation() {
    final location = property.displayLocation;
    return Container(
      color: AppColors.whiteF9,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            property.propertyName.isNotEmpty
                ? property.propertyName
                : property.typeLabel,
            fontSize: SizeConfig.large18,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: isOwner ? null : () => _showMapBottomSheet(Get.context!),
              child: Row(
                children: [
                  LocalAssets(
                    imagePath:AppIconAssets.location_outline,
                    height: 16,
                    width: 16,
                    imgColor: isOwner ? AppColors.secondaryTextColor : AppColors.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  // Owner is viewing their own listing — distance from
                  // their current location to the property isn't
                  // useful, so we collapse the row to just the address.
                  if (!isOwner) ...[
                    CustomText(
                      _distanceLabel(),
                      fontSize: 13,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: AppColors.greyE5,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: CustomText(
                      location,
                      fontSize: 13,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _distanceLabel() {
    final lat = property.location?.latitude.toDouble() ?? 0.0;
    final lng = property.location?.longitude.toDouble() ?? 0.0;
    if (lat == 0.0 || lng == 0.0) return '— KM Away';
    final km = calculateDistanceKm(
      LocationService.lat,
      LocationService.lng,
      lat,
      lng,
    );
    return '${km.toStringAsFixed(0)}KM Away';
  }

  // ─── STATS ROW ──────────────────────────────────────────────────

  Widget _stats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Symmetric `SizedBox(12)` on either side of the divider
            // so the rule lands dead-center of the row instead of
            // being pushed left by the unbalanced spacer pattern that
            // was here before.
            Expanded(child: _priceColumn()),
            const SizedBox(width: 12),
            Container(width: 1, color: AppColors.greyE5),
            const SizedBox(width: 12),
            Expanded(child: _areaColumn()),
          ],
        ),
      ),
    );
  }

  Widget _priceColumn() {
    final priceText = _formattedHeadlinePrice();
    final priceSuffix = _priceSuffix();
    final depositLine = _depositLine();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: priceText,
                style: TextStyle(
                  fontFamily: AppConstants.OpenSans,
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  letterSpacing: -0.2,
                ),
              ),
              if (priceSuffix.isNotEmpty)
                TextSpan(
                  text: priceSuffix,
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
            ],
          ),
        ),
        if (depositLine.isNotEmpty) ...[
          const SizedBox(height: 4),
          CustomText(
            depositLine,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Price portion shown in big bold weight — strips the trailing
  /// "/mo" because we render that as a separate small suffix.
  String _formattedHeadlinePrice() {
    final raw = property.formattedPrice;
    final monthly = raw.endsWith('/mo');
    return monthly ? raw.substring(0, raw.length - 3) : raw;
  }

  /// Small suffix after the headline price. For rent listings this is
  /// derived from the price-type wire key (PerMonth → "/Month", etc.).
  String _priceSuffix() {
    if (property.listingType != 'Rent') return '';
    final pt = property.priceType;
    if (pt == null || pt.isEmpty) return '/Month';
    switch (pt) {
      case 'PerMonth':
        return '/Month';
      case 'PerQuarter':
        return '/Quarter';
      case 'Per6Months':
        return '/6 Months';
      case 'PerYear':
        return '/Year';
      case 'OneTime':
        return '';
      default:
        return '';
    }
  }

  /// Sub-line below the price. Shows "+ Deposit ₹X" when the
  /// listing has a deposit amount on file; otherwise omitted.
  String _depositLine() {
    final amount = property.securityDepositAmount;
    if (amount == null || amount.trim().isEmpty) return '';
    final n = num.tryParse(amount.trim());
    if (n == null || n <= 0) return '';
    return '+ Deposit ₹${PropertyModel.formatIndianPrice(n)}';
  }

  Widget _areaColumn() {
    final stat = _areaStat();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          stat.value,
          fontSize: SizeConfig.large18,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (stat.label.isNotEmpty) ...[
          const SizedBox(height: 4),
          CustomText(
            stat.label,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Right-side stat. Pulls a sensible "area + label" pair out of the
  /// type-specific sub-model so each listing kind shows the right
  /// detail (Plot Area vs Built-up Area vs Room Type). Falls back to
  /// the rating when there's no area to show.
  ({String value, String label}) _areaStat() {
    final ha = property.houseAndApartment;
    if (ha != null && (ha.areaDetails ?? '').isNotEmpty) {
      return (value: ha.areaDetails!, label: 'Built-up Area');
    }
    final lp = property.landAndPlots;
    if (lp?.plotAreaDetails?.totalArea != null &&
        lp!.plotAreaDetails!.totalArea!.isNotEmpty) {
      return (value: lp.plotAreaDetails!.totalArea!, label: 'Plot Area');
    }
    final so = property.shopAndOffices;
    if (so != null && (so.superBuiltupArea ?? '').isNotEmpty) {
      return (value: so.superBuiltupArea!, label: 'Built-up Area');
    }
    final np = property.newProjectsAndProperties;
    if (np != null && (np.area ?? '').isNotEmpty) {
      return (value: np.area!, label: 'Area');
    }
    final pg = property.pgAndGuestHouse;
    if (pg != null && (pg.roomType ?? '').isNotEmpty) {
      return (value: pg.roomType!, label: 'Room Type');
    }
    return (
      value: property.rating.toStringAsFixed(1),
      label: 'Rating',
    );
  }

  // ─── FOOTER ────────────────────────────────────────────────────

  Widget _footer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.whiteF9,
      ),
      child: isOwner ? _ownerFooterRow() : _discoverFooterRow(),
    );
  }

  /// Owner footer — single horizontal row with the lister name at
  /// the start and the role subline at the end. No chat / call
  /// shortcuts since the owner is viewing their own listing.
  Widget _ownerFooterRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: CustomText(
            _ownerDisplayName(),
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        CustomText(
          _ownerSubline(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Discover footer — name + subline stacked on the left, chat +
  /// call shortcut chips pinned to the right.
  Widget _discoverFooterRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                _ownerDisplayName(),
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                _ownerSubline(),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _circleIconAction(
          filled: false,
          child: LocalAssets(
            imagePath: AppIconAssets.chat,
            height: 18,
            width: 18,
            imgColor: AppColors.primaryColor,
          ),
          onTap: _openChat,
        ),
        // Call shortcut commented out for now — re-enable when an owner
        // phone number is available on the model.
        // const SizedBox(width: 8),
        // _circleIconAction(
        //   filled: true,
        //   child: const Icon(
        //     Icons.call_rounded,
        //     size: 18,
        //     color: Colors.white,
        //   ),
        //   onTap: _placeCall,
        // ),
      ],
    );
  }

  /// Square chip with rounded corners. `filled` flips between the
  /// outlined chat shortcut and the filled call shortcut so the two
  /// read as a related pair without competing for attention.
  Widget _circleIconAction({
    required bool filled,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: filled
              ? null
              : Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.7),
                  width: 1,
                ),
        ),
        child: child,
      ),
    );
  }

  String _ownerDisplayName() {
    // `listedByName` is now sent on every payload from each step-2
    // spec screen and echoed back on the response model — read it
    // first; only fall back to a generic label if a legacy listing
    // came through without it.
    final name = property.listedByName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return 'Property Owner';
  }

  String _ownerSubline() {
    // The lister role ('Owner' / 'Builder' / 'Dealer') is already
    // sent in the request body via `listedBy` on each type-specific
    // sub-model and echoed back in the response — pull it from
    // whichever sub-model carries it. Falls back to 'Owner' when
    // the field is missing on an older payload.
    final role = _listedByRole() ?? 'Owner';
    return isOwner ? 'You • $role' : role;
  }

  /// Pulls `listedBy` from whichever type-specific sub-model has it.
  /// Houses, lands, shops, and PGs all carry the field; new-projects
  /// listings don't, so they fall through to the null fallback.
  String? _listedByRole() {
    final ha = property.houseAndApartment?.listedBy;
    if (ha != null && ha.isNotEmpty) return ha;
    final lp = property.landAndPlots?.listedBy;
    if (lp != null && lp.isNotEmpty) return lp;
    final so = property.shopAndOffices?.listedBy;
    if (so != null && so.isNotEmpty) return so;
    final pg = property.pgAndGuestHouse?.listedBy;
    if (pg != null && pg.isNotEmpty) return pg;
    return null;
  }

  // ─── ACTIONS ────────────────────────────────────────────────────

  void _showMapBottomSheet(BuildContext context) {
    RouteMapBottomSheet.show(
      context: context,
      destinationName: property.propertyName,
      destinationAddress: property.displayLocation,
      destinationLat: property.location?.latitude.toDouble() ?? 0.0,
      destinationLng: property.location?.longitude.toDouble() ?? 0.0,
      livePhotos: property.propertyImages,
      visitCallback: () => Get.to(() => PropertyDetailsScreen(
            property: property,
            isOwner: false,
          )),
    );
  }

  void _shareListing() {
    // Share endpoint not wired through to the rental flow yet — keep
    // the chip visible so the layout matches the Discover design;
    // surface a hint so the tap isn't silent.
    commonSnackBar(message: 'Share coming soon');
  }

  void _openChat() {
    final ownerId = property.userId;
    if (ownerId == null || ownerId.isEmpty) {
      commonSnackBar(message: 'Owner not available for chat');
      return;
    }
    final chatController = Get.find<ChatViewController>();
    chatController.checkChatConnectionAndOpenChat(userId: ownerId);
  }

  // Call shortcut is commented out in the footer for now (see
  // _discoverFooterRow). Re-enable this together with it once the
  // backend adds an `ownerPhone` field.
  // void _placeCall() {
  //   commonSnackBar(message: 'Call number not available — try chat');
  // }

  void _showOwnerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE2EE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.redB4),
              title: CustomText(
                'Delete Property',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.redB4,
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText(
          'Delete Property',
          fontSize: SizeConfig.large18,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        content: CustomText(
          'Are you sure you want to delete "${property.propertyName}"? '
              'This action cannot be undone.',
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: CustomText(
              'Cancel',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _deleteProperty();
            },
            child: CustomText(
              'Delete',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.redB4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty() async {
    if (property.id == null) return;
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final repo = PropertyRepo();
      final response = await repo.deleteProperty(property.id!);
      Get.back();
      if (response.isSuccess) {
        commonSnackBar(message: 'Property deleted successfully');
        onDeleted?.call();
      } else {
        commonSnackBar(
            message: response.message ?? 'Failed to delete property');
      }
    } catch (_) {
      Get.back();
      commonSnackBar(message: 'Something went wrong');
    }
  }

  // ─── PLACEHOLDER ────────────────────────────────────────────────

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryColor.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.holiday_village_outlined,
          size: 44,
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

/// Thin neutral divider used between the title block and the stats
/// row. Sits flush to the card edges so the stats look like a separate
/// "data band" beneath the location.
// class _SoftDivider extends StatelessWidget {
//   const _SoftDivider();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 1,
//       width: double.infinity,
//       color: AppColors.greyE5,
//     );
//   }
// }

/// Swipeable hero carousel for the card. Owns its own `PageController`
/// + active index so each card paginates independently inside a list.
/// Renders the pagination dot strip and the "+N remaining" tile
/// reactively from the live index instead of the static first-image
/// snapshot the card previously used (which is why nothing scrolled).
class _HeroPager extends StatefulWidget {
  final List<String> images;
  final Widget placeholder;
  final Widget topRightAction;
  final Widget? topLeftBadge;

  const _HeroPager({
    required this.images,
    required this.placeholder,
    required this.topRightAction,
    this.topLeftBadge,
  });

  @override
  State<_HeroPager> createState() => _HeroPagerState();
}

class _HeroPagerState extends State<_HeroPager> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            widget.placeholder
          else
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => Image.network(
                images[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => widget.placeholder,
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: widget.topRightAction,
          ),
          if (widget.topLeftBadge != null)
            Positioned(
              top: 12,
              left: 12,
              child: widget.topLeftBadge!,
            ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(child: _dots(images.length, _index)),
            ),
          if (images.length > 1 && _index < images.length - 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: _plusTile(images.length - 1 - _index),
            ),
        ],
      ),
    );
  }

  /// Reactive dot strip. The active dot tracks `_index` so swiping
  /// updates it live. Capped at 5 dots so narrow phones don't push
  /// the row off-screen with very long galleries.
  Widget _dots(int count, int active) {
    final visible = count > 5 ? 5 : count;
    final activeMapped =
        count > 5 ? (active * (visible - 1) ~/ (count - 1)) : active;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(visible, (i) {
        final isActive = i == activeMapped;
        return Container(
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primaryColor : Colors.white,
            border: isActive
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 0.6,
                  ),
          ),
        );
      }),
    );
  }

  /// Compact "+N remaining" tile — slightly darker scrim + a touch
  /// larger so the count reads cleanly without becoming a button.
  Widget _plusTile(int n) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mainTextColor.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1,
        ),
      ),
      child: CustomText(
        '+$n',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
