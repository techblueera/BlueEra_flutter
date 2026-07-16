import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Owner "more" overflow actions surfaced on the self-listed card.
enum _OwnerAction { edit, delete }

/// Rich Discover-side vehicle card.
///
/// Modelled on the marketing reference: a tall hero image with a rating
/// pill + share/favourite actions overlaid, the title/description, a row
/// of three spec tiles (fuel / engine / mileage), the ex-showroom vs
/// on-road price split, an EMI strip and the Chat / Book-Now CTA row.
/// Every block is rendered only when the backing field is present, so a
/// sparsely-filled listing still degrades gracefully.
class VehicleDiscoverCard extends StatelessWidget {
  final Vehicle vehicle;

  /// Tapping anywhere on the body (image/title) — wired to the detail screen.
  final VoidCallback? onTap;
  final VoidCallback? onChat;
  final VoidCallback? onBook;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  /// Owner-side mode. When true the card renders **identically** to the
  /// public Discover card and additionally surfaces a "more" (3-dot)
  /// overflow on the hero with Edit / Delete — used on the self-listed
  /// "My Vehicles" tab so the owner's own listings look exactly like the
  /// Discover ones while still exposing owner CRUD.
  final bool showOwnerActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VehicleDiscoverCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onChat,
    this.onBook,
    this.onShare,
    this.onFavorite,
    this.isFavorite = false,
    this.showOwnerActions = false,
    this.onEdit,
    this.onDelete,
  });

  static const _blue = Color(0xFF1E88FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          _buildHero(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size14,
              SizeConfig.size14,
              SizeConfig.size14,
              SizeConfig.size14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        vehicle.name,
                        fontSize: SizeConfig.large18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black22,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((vehicle.description ?? '').trim().isNotEmpty) ...[
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          vehicle.description!.trim(),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_specs.isNotEmpty) ...[
                  SizedBox(height: SizeConfig.size12),
                  _buildSpecRow(),
                ],
                if (_hasPriceRow || _hasEmi) ...[
                  SizedBox(height: SizeConfig.size12),
                  _buildPriceEmiCard(),
                ],
                SizedBox(height: SizeConfig.size14),
                _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero image with overlays ──────────────────────────────────────
  Widget _buildHero() {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: _CoverImage(url: vehicle.coverImage ?? _firstImage),
          ),
          if (vehicle.isVerified ?? false)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    CustomText(
                      AppStrings.verified.tr,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
                // Owner-side "more" overflow — Edit / Delete live here so the
                // card otherwise renders identically to the public Discover one.
                if (showOwnerActions) ...[
                  _buildMoreMenu(),
                  const SizedBox(height: 10),
                ],
                _circleAction(AppIconAssets.share_bold, onShare),
                const SizedBox(height: 8),
                _circleAction(
                  AppIconAssets.star_rounded,
                  onFavorite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction(String icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.black25,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LocalAssets(
            imagePath: icon,
            imgColor: AppColors.white,
          ),
        ),
      ),
    );
  }

  // ─── Owner "more" overflow (Edit / Delete) ─────────────────────────
  Widget _buildMoreMenu() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<_OwnerAction>(
        tooltip: AppStrings.more.tr,
        padding: EdgeInsets.zero,
        icon:
            const Icon(Icons.more_vert_rounded, size: 19, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (action) {
          switch (action) {
            case _OwnerAction.edit:
              onEdit?.call();
              break;
            case _OwnerAction.delete:
              onDelete?.call();
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _OwnerAction.edit,
            child: Row(
              children: [
                const Icon(Icons.edit_rounded, size: 18, color: _blue),
                SizedBox(width: SizeConfig.size10),
                CustomText(
                  AppStrings.edit.tr,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: _OwnerAction.delete,
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.red.shade400),
                SizedBox(width: SizeConfig.size10),
                CustomText(
                  AppStrings.delete.tr,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Spec tiles ────────────────────────────────────────────────────
  List<_Spec> get _specs {
    final out = <_Spec>[];
    if (vehicle.fuelType != null) {
      out.add(_Spec(
        icon: "assets/svg/petrol.svg",
        label: _humanFuel(vehicle.fuelType!),
      ));
    }
    if (vehicle.engineCapacityCc != null) {
      out.add(_Spec(
        icon: "assets/svg/engine.svg",
        label: '${vehicle.engineCapacityCc} ${AppStrings.ccUnit.tr}',
      ));
    }
    if ((vehicle.mileage ?? '').trim().isNotEmpty) {
      out.add(_Spec(
        icon: "assets/svg/kmroad.svg",
        label: _mileageLabel(vehicle.mileage!.trim()),
      ));
    }
    return out;
  }

  Widget _buildSpecRow() {
    final specs = _specs;
    return Row(
      children: [
        for (int i = 0; i < specs.length; i++) ...[
          Expanded(child: _SpecTile(spec: specs[i])),
          if (i != specs.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  String _mileageLabel(String raw) {
    // If the stored mileage is a bare number, append the unit; otherwise
    // trust the server-provided string (e.g. "35 km/L").
    final isBareNumber = double.tryParse(raw) != null;
    return isBareNumber ? '$raw ${AppStrings.kmplUnit.tr}' : raw;
  }

  // ─── Price split ───────────────────────────────────────────────────
  bool get _hasPriceRow =>
      vehicle.exShowroomPrice != null || vehicle.onRoadPrice != null;

  /// Prices + EMI rendered as a single card so the tinted price row and the
  /// white EMI row read as one unit (matches the marketing reference). Both
  /// halves are optional; the divider only appears when both are visible.
  Widget _buildPriceEmiCard() {
    final showPrices = _hasPriceRow;
    final showEmi = _hasEmi;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (showPrices)
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: _priceColumn(
                        AppStrings.exShowroomPrice.tr,
                        vehicle.exShowroomPrice ?? vehicle.price,
                      ),
                    ),
                  ),
                  Container(width: 1, color: const Color(0xFFE2E7EE)),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF5F7FA),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: _priceColumn(
                        AppStrings.onRoadPrice.tr,
                        vehicle.onRoadPrice,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (showPrices && showEmi)
            Container(height: 1, color: const Color(0xFFE8ECF2)),
          if (showEmi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: _buildEmiContent(),
            ),
        ],
      ),
    );
  }

  Widget _priceColumn(String label, double? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size4),
        CustomText(
          value != null ? _price(value) : '—',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── EMI strip ─────────────────────────────────────────────────────
  bool get _hasEmi =>
      (vehicle.emiAvailable ?? false) &&
      (vehicle.downPayment != null || vehicle.monthlyEmi != null);

  /// Just the inner content of the EMI row — wrapped by
  /// [_buildPriceEmiCard] so the padding/border live on the parent card.
  Widget _buildEmiContent() {
    return Row(
      children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 16, color: AppColors.mainTextColor),
        const SizedBox(width: 6),
        CustomText(
          '${AppStrings.emiLabel2.tr} :',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (vehicle.downPayment != null)
                _emiPair(AppStrings.downPaymentLabel.tr,
                    _price(vehicle.downPayment!)),
              if (vehicle.downPayment != null && vehicle.monthlyEmi != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: CustomText('|',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFC4CBD4)),
                ),
              if (vehicle.monthlyEmi != null)
                _emiPair(AppStrings.monthly.tr, _price(vehicle.monthlyEmi!)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emiPair(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label - ',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── CTA row ───────────────────────────────────────────────────────
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _chatButton(),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: onBook,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    AppStrings.inquiry.tr,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chatButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Text("Coming Soon");
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
              color: Color(0xffF2F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xffCFE8FF))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: LocalAssets(
                    imagePath: "assets/icons/showroom.png",
                    imgColor: AppColors.primaryColor),
              ),
              // const SizedBox(width: 6),
              CustomText(
                "Showrooms",
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat() {
    final userId = vehicle.userId ?? '';
    if (userId.trim().isEmpty) return;
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final bId = vehicle.id?.trim();
    if (bId != null && bId.isNotEmpty) {
      ChatClickTracker.track(
        userId: bId,
        source: ChatClickSource.searchResult,
      );
    }
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.checkChatConnectionAndOpenChat(
      userId: userId,
      name: vehicle.name,
      profile: vehicle.coverImage,
      route: AppConstants.route_discover,
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────
  String? get _firstImage =>
      vehicle.images.isNotEmpty ? vehicle.images.first : null;

  String _price(double v) {
    final cur = (vehicle.currency ?? 'INR').toUpperCase();
    final symbol = cur == 'INR' ? '₹' : '$cur ';
    return '$symbol${_compactNumber(v)}';
  }

  String _compactNumber(double v) {
    if (v >= 1e7) {
      return '${_trim(v / 1e7)} ${AppStrings.compactUnitCr.tr}';
    }
    if (v >= 1e5) {
      return '${_trim(v / 1e5)} ${AppStrings.compactUnitLac.tr}';
    }
    if (v >= 1e3) {
      return '${_trim(v / 1e3)}${AppStrings.compactUnitThousand.tr}';
    }
    return _trim(v);
  }

  /// Drops a trailing ".0" so 5.0 → "5" while 4.22 stays "4.22".
  String _trim(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _humanFuel(VehicleFuelType f) {
    switch (f) {
      case VehicleFuelType.petrol:
      case VehicleFuelType.diesel:
      case VehicleFuelType.cng:
        return f.name.capitalizeFirst.toString();
      case VehicleFuelType.electric:
        return AppStrings.fuelElectric.tr;
      case VehicleFuelType.hybrid:
        return AppStrings.fuelHybrid.tr;
      case VehicleFuelType.other:
        return AppStrings.fuelOther.tr;
    }
  }
}

class _Spec {
  final String icon;
  final String label;
  const _Spec({required this.icon, required this.label});
}

class _SpecTile extends StatelessWidget {
  final _Spec spec;
  const _SpecTile({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size6, horizontal: SizeConfig.size6),
      decoration: BoxDecoration(
          // color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5, width: 0.5)),
      child: Column(
        children: [
          LocalAssets(
            imagePath: spec.icon,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            spec.label,
            fontSize: 14,
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
}

class _CoverImage extends StatelessWidget {
  final String? url;
  const _CoverImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFEAF2FB),
        alignment: Alignment.center,
        child: Icon(
          Icons.directions_car_rounded,
          size: 40,
          color: AppColors.primaryColor.withValues(alpha: 0.5),
        ),
      );
}
