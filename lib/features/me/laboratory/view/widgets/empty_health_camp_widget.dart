import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/view/health_camp_detail_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The "Health Camp" tile on the lab owner's overview: opens the owner's
/// health camp screen, which fetches the camp itself.
class EmptyHealthCampWidget extends StatefulWidget {
  const EmptyHealthCampWidget({super.key});

  @override
  State<EmptyHealthCampWidget> createState() => _EmptyHealthCampWidgetState();
}

class _EmptyHealthCampWidgetState extends State<EmptyHealthCampWidget> {
  static const String _backgroundAsset = 'assets/category/medical/health_camp_bg.png';
  static const String _emptyIconAsset = 'assets/category/medical/empty_white_data.png';
  static const double _stackHeight = 220;

  void _navigateToDetail() {
    Get.to(() => const HealthCampDetailScreen());
  }

  @override
  Widget build(BuildContext context) {
    return _buildOwnProfileView();
  }

  /// Standard rounded white shell that every variant of this widget shares.
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(AppStrings.healthCamp, fontWeight: FontWeight.w700),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Standard rounded image stack used as the body of every variant.
  /// Pass [imageUrl] to render a network header (with the asset as a fallback);
  /// pass null to use only the asset background.
  Widget _buildImageStack({
    required Widget content,
    String? imageUrl,
    bool overlay = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              height: _stackHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _assetBackground(),
            )
          else
            _assetBackground(),
          if (overlay)
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          Padding(padding: const EdgeInsets.all(20.0), child: content),
        ],
      ),
    );
  }

  Widget _assetBackground() => Image.asset(
        _backgroundAsset,
        height: _stackHeight,
        width: double.infinity,
        fit: BoxFit.cover,
      );

  /// Own profile: tap to manage health camp (add/edit/delete in detail screen)
  Widget _buildOwnProfileView() {
    return InkWell(
      onTap: _navigateToDetail,
      child: _buildCard(
        child: _buildImageStack(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalAssets(imagePath: _emptyIconAsset, width: 60, height: 60),
              const SizedBox(height: 12),
              CustomText(
                "no_tests_posted".tr,
                color: Colors.white,
                textAlign: TextAlign.center,
                fontSize: SizeConfig.size15,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white54),
                ),
                child: CustomText(
                  AppStrings.healthCamp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
