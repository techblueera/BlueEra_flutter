import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GuestDashBoardScreen extends StatefulWidget {
  const GuestDashBoardScreen({super.key});

  @override
  State<GuestDashBoardScreen> createState() => _GuestDashBoardScreenState();
}

class _GuestDashBoardScreenState extends State<GuestDashBoardScreen> {
  // Soft pastel page background like the reference mock.
  static const Color _earnCardBg = Color(0xFFE8F0FF);
  static const Color _businessCardBg = Color(0xFFFEF9EF);
  static const Color _professionCardBg = Color(0xFFFBF4FF);

  // Per-card borders (0.5 px) and a shared subtle drop shadow.
  static const Color _earnCardBorder = Color(0xFFCFDDFF);
  static const Color _businessCardBorder = Color(0xFFFFF0D3);
  static const Color _professionCardBorder = Color(0xFFF2DCFF);
  // Shadow #00122314 → ARGB (alpha 0x14 ≈ 8%, RGB 0x001223).
  static const Color _featureCardShadow = Color(0x14001223);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: false,
        appBarColor: AppColors.white,
        isShadowShow: false,
        isGuestLogout: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => createProfileScreen(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size16,
              SizeConfig.size20,
              SizeConfig.size16,
              kBottomNavigationBarHeight + SizeConfig.size24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _hero(SizeConfig.size200)),
                SizedBox(height: SizeConfig.size12),
                CustomText(
                  'Scratch & Earn Bonus',
                  fontSize: SizeConfig.size20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: SizeConfig.size16),
                _title(),
                SizedBox(height: SizeConfig.size10),
                Center(child: _statusPill()),
                SizedBox(height: SizeConfig.size12),
                _bodyCopy(),
                SizedBox(height: SizeConfig.size20),
                _featureCard(
                  bgColor: _earnCardBg,
                  borderColor: _earnCardBorder,
                  iconBg: AppColors.white,
                  iconAsset: AppImageAssets.loanSector,
                  title: AppStrings.earnWithBlueEra.tr,
                  subtitle: AppStrings.earnWithBlueEraDesc.tr,
                ),
                SizedBox(height: SizeConfig.paddingXSL),
                _featureCard(
                  bgColor: _businessCardBg,
                  borderColor: _businessCardBorder,
                  iconBg: AppColors.white,
                  iconAsset: AppImageAssets.listCardBoard,
                  title: AppStrings.listYourBusiness.tr,
                  subtitle: AppStrings.listYourBusinessDesc.tr,
                ),
                SizedBox(height: SizeConfig.paddingXSL),
                _featureCard(
                  bgColor: _professionCardBg,
                  borderColor: _professionCardBorder,
                  iconBg: AppColors.white,
                  iconAsset: AppImageAssets.professionalDiscover,
                  title: AppStrings.listYourProfession.tr,
                  subtitle: AppStrings.listYourProfessionDesc.tr,
                ),
                SizedBox(height: SizeConfig.size24),
                _ctaBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(double size) {
    // Same footprint as the previous hand-drawn hero (width: size,
    // height: size * 0.85) — now rendered from the dummy_scratch asset.
    return LocalAssets(
      imagePath: AppImageAssets.dummyScratch,
      width: size,
      height: size * 0.85,
    );
  }

  Widget _title() {
    return CustomText(
      AppStrings.completeProfile.tr,
      fontSize: SizeConfig.size24,
      color: AppColors.primaryColor,
      fontWeight: FontWeight.w600,
      textAlign: TextAlign.center,
    );
  }

  Widget _statusPill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 16,
            color: AppColors.primaryColor,
          ),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            AppStrings.browsingAsGuest.tr,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _bodyCopy() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CustomText(
        AppStrings.guestCreateAccountMessage.tr,
        fontSize: SizeConfig.medium,
        textAlign: TextAlign.center,
        fontWeight: FontWeight.w400,
        color: AppColors.mainTextColor,
      ),
    );
  }

  Widget _ctaBar() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => createProfileScreen(),
        child: Container(
          height: SizeConfig.size50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                AppStrings.createAccount.tr,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
              SizedBox(width: SizeConfig.size10),
              const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required Color bgColor,
    required Color borderColor,
    required Color iconBg,
    required String iconAsset,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: _featureCardShadow,
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: SizeConfig.size48,
            height: SizeConfig.size48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
            ),
            padding: EdgeInsets.all(SizeConfig.size8),
            child: LocalAssets(
              imagePath: iconAsset,
              boxFix: BoxFit.contain,
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: 6),
                CustomText(
                  subtitle,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
