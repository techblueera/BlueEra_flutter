import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/medical_cart_controller.dart';
import 'package:BlueEra/features/me/medical/view/medical_cart_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Sticky bottom cart bar. Replaces the "Send Enquiry" bar on the pharmacy
/// screen once the cart has items. Single-store scope — no expandable
/// multi-cart panel like grocery, since pharmacy detail is per-listing.
class MedicalFloatingCart extends StatelessWidget {
  final MedicalCartController controller;

  const MedicalFloatingCart({super.key, required this.controller});

  static const Color _primary = AppColors.primaryColor;
  static const Color _primaryDeep = AppColors.blue5CAF;

  void _openCart() {
    Navigator.push(
      Get.context!,
      MaterialPageRoute(builder: (_) => const MedicalCartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Subscribe to add/remove; render nothing when empty.
      // ignore: unused_local_variable
      final _ = controller.cartQuantities.length;
      if (controller.isEmpty) return const SizedBox.shrink();

      final items = controller.totalItemsCount;
      final total = controller.totalSellingPrice;
      final savings = controller.totalSavings;
      final imgs = controller.previewImages;
      final hasRx = controller.hasAnyPrescriptionItem;

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              SizeConfig.size12, 0, SizeConfig.size12, SizeConfig.size10),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.greyE5, width: 0.6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                _overlap(imgs, size: 40, step: 24),
                SizedBox(width: SizeConfig.size10),
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
                            SizedBox(width: SizeConfig.size6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
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
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          CustomText(
                            '$items ${items == 1 ? 'item' : 'items'}',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor,
                          ),
                          if (hasRx) ...[
                            SizedBox(width: SizeConfig.size4),
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
                SizedBox(width: SizeConfig.size8),
                InkWell(
                  onTap: _openCart,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_primaryDeep, _primary]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.32),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText('View Cart',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white),
                        const SizedBox(width: 5),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 15, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _overlap(List<String?> imgs,
      {required double size, required double step}) {
    final shown = imgs.take(3).toList();
    if (shown.isEmpty) return _circle(null, size);
    return SizedBox(
      width: size + (shown.length - 1) * step,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(left: i * step, child: _circle(shown[i], size)),
        ],
      ),
    );
  }

  Widget _circle(String? url, double size) {
    final fallback = Container(
      color: AppColors.whiteF3,
      alignment: Alignment.center,
      child: Icon(Icons.medical_services_outlined,
          size: size * 0.42, color: _primary.withValues(alpha: 0.5)),
    );
    final inner = (url == null || url.isEmpty)
        ? fallback
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) => Container(color: AppColors.whiteF3),
            errorWidget: (_, __, ___) => fallback,
          );
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
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
}
