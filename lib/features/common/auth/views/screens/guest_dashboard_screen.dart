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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size16,
            SizeConfig.size12,
            SizeConfig.size16,
            SizeConfig.size16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _hero()),
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
              SizedBox(height: SizeConfig.paddingXL),
              _ctaBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final size = SizeConfig.size220;
    return SizedBox(
      width: size,
      height: size * 0.85,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Soft circle backdrop.
          Positioned.fill(
            child: Center(
              child: Container(
                width: size * 0.78,
                height: size * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
          // Decorative micro-sparkles around the halo.
          ..._sparkles(size),
          // White profile card front.
          Center(
            child: Container(
              width: size * 0.55,
              height: size * 0.7,
              padding: EdgeInsets.all(SizeConfig.size12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(SizeConfig.size12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: SizeConfig.size48,
                    height: SizeConfig.size48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  _line(width: size * 0.34),
                  SizedBox(height: SizeConfig.size6),
                  _line(width: size * 0.26),
                ],
              ),
            ),
          ),
          // Lock badge — top-right corner of the card.
          Positioned(
            top: size * 0.08,
            right: size * 0.18,
            child: _badge(
              bg: AppColors.white,
              child: Icon(
                Icons.lock,
                size: 16,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          // Verified shield — bottom-left corner of the card.
          Positioned(
            bottom: size * 0.06,
            left: size * 0.16,
            child: _badge(
              bg: AppColors.primaryColor,
              size: SizeConfig.size40,
              child: const Icon(
                Icons.verified_user,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line({required double width}) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _badge({required Color bg, required Widget child, double? size}) {
    final s = size ?? SizeConfig.size34;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }

  List<Widget> _sparkles(double size) {
    final color = AppColors.primaryColor.withValues(alpha: 0.45);
    const spots = <Offset>[
      Offset(0.10, 0.18),
      Offset(0.86, 0.22),
      Offset(0.18, 0.78),
      Offset(0.88, 0.70),
      Offset(0.50, 0.04),
    ];
    return [
      for (final p in spots)
        Positioned(
          left: size * p.dx - 2,
          top: size * 0.85 * p.dy - 2,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
    ];
  }

  Widget _title() {
    return CustomText(
      AppStrings.guestUserTitle.tr,
      fontSize: SizeConfig.size26,
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
            width: SizeConfig.size50,
            height: SizeConfig.size50,
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
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: 6),
                CustomText(
                  subtitle,
                  fontSize: SizeConfig.medium,
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
