import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/medical_cart_controller.dart';
import 'package:BlueEra/features/me/medical/view/medical_cart_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Zomato-style floating cart for pharmacy self-pickup — the same shape as
/// [CustomerGrocerySelfPickupCart].
///
/// Collapsed it's a compact pill previewing the cart's product photos. Tapping
/// the "View Cart" pill makes a panel **rise up from the bottom**; closing
/// slides it back down. Both states end in a single **Checkout**.
///
/// Differs from grocery in one way only: the pharmacy cart is **single-store**
/// (see `MedicalProductCard._ensureSameBusiness`), so the panel shows one
/// pharmacy chip and the header never carries a store count.
class MedicalFloatingCart extends StatefulWidget {
  final MedicalCartController controller;

  const MedicalFloatingCart({super.key, required this.controller});

  @override
  State<MedicalFloatingCart> createState() => _MedicalFloatingCartState();
}

class _MedicalFloatingCartState extends State<MedicalFloatingCart> {
  static const Color _primary = AppColors.primaryColor;
  static const Color _primaryDeep = AppColors.blue5CAF;

  // Soft tinted backdrop for the open panel (not plain white).
  static const Color _panelTop = Color(0xFFE7F0FF);
  static const Color _panelBottom = Color(0xFFF4F8FF);

  bool _expanded = false;

  /// Checkout opens the cart screen to review + place the order (it does NOT
  /// place the order directly).
  void _openCartScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MedicalCartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = widget.controller;
      // ignore: unused_local_variable
      final _ = c.cartQuantities.length; // subscribe to add / remove
      if (c.isEmpty) {
        _expanded = false;
        return const SizedBox.shrink();
      }
      // SafeArea lives HERE, not at the call sites: every caller pins this to
      // `bottom: 0` of a Stack, so without it the bar sits under the gesture
      // bar / home indicator. Keeping it inside means a new call site can't
      // forget it. `top: false` — only the bottom inset matters.
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          // Height morphs while the content slides in from below → the panel
          // visibly *rises from the bottom* on open and drops back on close.
          child: AnimatedSize(
            duration: const Duration(milliseconds: 320),
            reverseDuration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.antiAlias,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              reverseDuration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1), // start fully below → slide up
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.bottomCenter,
                children: [...previous, if (current != null) current],
              ),
              child: _expanded
                  ? _buildPanel(c, const ValueKey('panel'))
                  : _buildCollapsed(c, const ValueKey('pill')),
            ),
          ),
        ),
      );
    });
  }

  // ── Collapsed bar — photos (left) · Checkout (right) · a "View Cart" pill
  //    straddling the top-center edge (half-in/half-out) to open the panel. ──
  Widget _buildCollapsed(MedicalCartController c, Key key) {
    final items = c.totalItemsCount;
    final total = c.totalSellingPrice;
    final savings = c.totalSavings;
    final hasRx = c.hasAnyPrescriptionItem;

    return Stack(
      key: key,
      clipBehavior: Clip.none,
      children: [
        // The bar (top margin leaves room for the protruding pill).
        Container(
          margin: const EdgeInsets.fromLTRB(8, 15, 8, 0),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.greyE5),
            // Even halo on all sides (zero offset + spread) so it reads on a
            // white screen without pooling at the bottom.
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 1,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Row(
            children: [
              // Left — product photos + total / items.
              _overlap(c.previewImages, size: 44, step: 27, ring: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomText(
                          '${AppConstants.rupeeSymbol}${total.toStringAsFixed(0)}',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w900,
                          color: AppColors.mainTextColor,
                        ),
                        if (savings > 0) ...[
                          const SizedBox(width: 6),
                          _savePill(savings),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        CustomText(
                          '$items ${items == 1 ? 'item' : 'items'}',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                        if (hasRx) ...[
                          const SizedBox(width: 4),
                          CustomText(
                            '· Rx required',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right — Checkout.
              _checkoutButton(onTap: _openCartScreen),
            ],
          ),
        ),
        // "View Cart" pill — straddles the top edge (half in / half out).
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: _viewCartPill()),
        ),
      ],
    );
  }

  Widget _savePill(double savings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.green00.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomText(
        'Save ${AppConstants.rupeeSymbol}${savings.toStringAsFixed(0)}',
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: AppColors.green00,
      ),
    );
  }

  Widget _viewCartPill() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_primary, _primaryDeep]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.keyboard_arrow_up_rounded,
                size: 16, color: Colors.white),
            const SizedBox(width: 4),
            CustomText(
              'View Cart',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 0.2,
            ),
          ],
        ),
      ),
    );
  }

  // ── Expanded "Your Cart" panel — tinted backdrop, white pharmacy chip ──────
  Widget _buildPanel(MedicalCartController c, Key key) {
    final items = c.totalItemsCount;
    final total = c.totalSellingPrice;

    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_panelTop, _panelBottom],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 26,
            spreadRadius: 1,
            offset: Offset.zero,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab handle
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.medical_services_rounded,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                CustomText(
                  'Your Cart',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _expanded = false),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border:
                          Border.all(color: _primary.withValues(alpha: 0.15)),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.secondaryTextColor),
                  ),
                ),
              ],
            ),
          ),
          // The single pharmacy this cart belongs to.
          _pharmacyChip(c),
          // Checkout footer
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomText(
                            '$items ${items == 1 ? 'item' : 'items'}',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextColor,
                          ),
                          if (c.hasAnyPrescriptionItem) ...[
                            const SizedBox(width: 4),
                            CustomText(
                              '· Rx required',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w700,
                              color: AppColors.red,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        '${AppConstants.rupeeSymbol}${total.toStringAsFixed(0)}',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w900,
                        color: AppColors.mainTextColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _checkoutButton(onTap: _openCartScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The cart's pharmacy as a compact white chip: logo + name + count + small
  /// circular product photos. Mirrors grocery's per-store chip; there is only
  /// ever one, because the pharmacy cart is single-store.
  Widget _pharmacyChip(MedicalCartController c) {
    final b = c.business.value;
    final name =
        (b?.businessName ?? '').isNotEmpty ? b!.businessName : 'Pharmacy';
    final count = c.totalItemsCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 5, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: _primaryDeep.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _circle(b?.logo, 32, ring: Colors.white, storeFallback: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  name,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                CustomText(
                  '$count ${count == 1 ? 'item' : 'items'}',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _overlap(c.previewImages, size: 36, step: 22, ring: Colors.white),
        ],
      ),
    );
  }

  /// Classic overlapping circular product photos.
  Widget _overlap(List<String?> imgs,
      {required double size, required double step, required Color ring}) {
    final shown = imgs.take(3).toList();
    if (shown.isEmpty) return _circle(null, size, ring: ring);
    return SizedBox(
      width: size + (shown.length - 1) * step,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
                left: i * step, child: _circle(shown[i], size, ring: ring)),
        ],
      ),
    );
  }

  Widget _circle(String? url, double size,
      {required Color ring, bool storeFallback = false}) {
    final fallback = Container(
      color: const Color(0xFFEFF3FA),
      alignment: Alignment.center,
      child: Icon(
        storeFallback
            ? Icons.storefront_rounded
            : Icons.medical_services_rounded,
        size: size * 0.42,
        color: _primary.withValues(alpha: 0.5),
      ),
    );
    final inner = (url == null || url.isEmpty)
        ? fallback
        : CachedNetworkImage(
            imageUrl: url,
            // contain, not cover — medicine packs are product shots on white
            // and get cropped badly by cover.
            fit: BoxFit.contain,
            placeholder: (_, __) => Container(color: Colors.grey.shade200),
            errorWidget: (_, __, ___) => fallback,
          );
    // White ring (separates overlapping photos) + a light hairline border +
    // a soft shadow, so the circle reads clearly on any background.
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring,
        border: Border.all(color: AppColors.greyE5, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(child: SizedBox.expand(child: inner)),
    );
  }

  Widget _checkoutButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_primaryDeep, _primary]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              'Checkout',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 0.2,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded,
                size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
