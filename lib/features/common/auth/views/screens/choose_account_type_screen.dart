import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/views/screens/new_screens/create_account_type_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Landing screen where the user picks one of three account flavors
/// (Business Listing, Professional Account, Personal Account) before
/// entering the detailed [CreateAccountTypeScreen]. The two individual
/// cards (Professional + Personal) both map to `accountType = individual`;
/// the business card maps to `accountType = business`.
class ChooseAccountTypeScreen extends StatefulWidget {
  const ChooseAccountTypeScreen({super.key});

  @override
  State<ChooseAccountTypeScreen> createState() =>
      _ChooseAccountTypeScreenState();
}

class _ChooseAccountTypeScreenState extends State<ChooseAccountTypeScreen> {
  int _selectedIndex = 0; // default: Business Listing

  // Shared card border color across all three cards (per spec).
  static const Color _cardBorderColor = Color(0xFFDEDCFE);

  // Card titles, subtitles and chip labels are stored as translation keys
  // (see AppStrings) and resolved with `.tr` at render time so the screen
  // updates instantly when the user switches language.
  late final List<_AccountCardData> _cards = [
    _AccountCardData(
      titleKey: AppStrings.businessListing,
      subtitleKey: AppStrings.shopStoreServices,
      iconAsset: AppImageAssets.businessListing,
      chipKeys: const [
        AppStrings.grocery,
        AppStrings.chipFood,
        AppStrings.chipHealthCare,
        AppStrings.education,
        AppStrings.chipAutomotive,
        AppStrings.chipHotel,
        AppStrings.chipRestaurant,
        AppStrings.chipFinance,
        AppStrings.chipMore,
      ],
      accountType: AppConstants.business,
      chipBg: const Color(0xFFECF6ED),
      chipText: const Color(0xFF2C3F25),
    ),
    _AccountCardData(
      titleKey: AppStrings.professionalAccount,
      subtitleKey: AppStrings.selfEmployeeConsultant,
      iconAsset: AppImageAssets.socialAccount,
      chipKeys: const [
        AppStrings.rider,
        AppStrings.chipDriver,
        AppStrings.chipAdvocate,
        AppStrings.chipTeacher,
        AppStrings.chipConsultant,
        AppStrings.electrician,
        AppStrings.plumber,
        AppStrings.chipRenovator,
        AppStrings.chipMore,
      ],
      accountType: AppConstants.individual,
      chipBg: const Color(0xFFE6F1FB),
      chipText: const Color(0xFF0C447C),
      // Professional → Skill Work / Self Employee (2nd entry in the
      // individual sidebar of CreateAccountTypeScreen).
      individualPreselectIndex: 1,
    ),
    _AccountCardData(
      titleKey: AppStrings.personalAccount,
      subtitleKey: AppStrings.socialProfile,
      iconAsset: AppImageAssets.professionalAccounts,
      chipKeys: const [
        AppStrings.politician,
        AppStrings.director,
        AppStrings.chipStudents,
        AppStrings.farmer,
        AppStrings.artist,
        AppStrings.chipGovtPvtEmployee,
        AppStrings.journalist,
        AppStrings.chipMore,
      ],
      accountType: AppConstants.individual,
      chipBg: const Color(0xFFEEEDFE),
      chipText: const Color(0xFF3C3489),
      // Personal → Social profile (1st entry in the individual sidebar).
      individualPreselectIndex: 0,
    ),
  ];

  void _onContinue() {
    if (_selectedIndex < 0 || _selectedIndex >= _cards.length) {
      commonSnackBar(message: AppStrings.pleaseChooseAccountType.tr);
      return;
    }
    final selected = _cards[_selectedIndex];
    Get.to(
      () => CreateAccountTypeScreen(
        accountType: selected.accountType,
        initialIndividualIndex: selected.individualPreselectIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: AppStrings.chooseYourAccountType.tr,
        onBackTap: () {
          Get.offNamedUntil(
            RouteHelper.getBottomNavigationBarScreenRoute(),
            (route) => false,
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(_cards.length, (index) {
                    final card = _cards[index];
                    final selected = _selectedIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.size10),
                      child: _AccountCard(
                        data: card,
                        selected: selected,
                        borderColor: _cardBorderColor,
                        onTap: () => setState(() => _selectedIndex = index),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size8,
                SizeConfig.size8,
                SizeConfig.size8,
                SizeConfig.size16,
              ),
              child: CustomBtn(
                onTap: _onContinue,
                title: AppStrings.continueText.tr,
                bgColor: AppColors.primaryColor,
                textColor: AppColors.white,
                radius: 10,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size8,
                0,
                SizeConfig.size8,
                SizeConfig.size16,
              ),
              child: CustomBtn(
                onTap: () {
                  Get.offNamedUntil(
                    RouteHelper.getBottomNavigationBarScreenRoute(),
                    (route) => false,
                  );
                },
                title: AppStrings.skip.tr,
                bgColor: AppColors.transparent,
                textColor: AppColors.primaryColor,
                borderColor: AppColors.primaryColor,
                radius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCardData {
  /// Translation key for the card title (resolved with `.tr` at render time).
  final String titleKey;

  /// Translation key for the card subtitle.
  final String subtitleKey;
  final String iconAsset;

  /// Translation keys for each chip label inside the card.
  final List<String> chipKeys;
  final String accountType;
  final Color chipBg;
  final Color chipText;

  /// When [accountType] is individual, the index of the item in
  /// `individualOnboardingProfilesCategory` that
  /// [CreateAccountTypeScreen] should pre-select. Business cards leave
  /// this as `0` (unused on that branch).
  final int individualPreselectIndex;

  _AccountCardData({
    required this.titleKey,
    required this.subtitleKey,
    required this.iconAsset,
    required this.chipKeys,
    required this.accountType,
    required this.chipBg,
    required this.chipText,
    this.individualPreselectIndex = 0,
  });
}

class _AccountCard extends StatelessWidget {
  final _AccountCardData data;
  final bool selected;
  final Color borderColor;
  final VoidCallback onTap;

  const _AccountCard({
    required this.data,
    required this.selected,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primaryColor : borderColor,
              width: selected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ]
            // boxShadow: selected
            //     ? [
            //         BoxShadow(
            //           color:
            //               AppColors.primaryColor.withValues(alpha: 0.12),
            //           blurRadius: 16,
            //           offset: const Offset(0, 3),
            //         ),
            //       ]
            //     : [
            //         BoxShadow(
            //           color: Colors.black.withValues(alpha: 0.04),
            //           blurRadius: 6,
            //           offset: const Offset(0, 2),
            //         ),
            //       ],
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: icon + title + subtitle ──
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: LocalAssets(
                      imagePath: data.iconAsset,
                      boxFix: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          data.titleKey.tr,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          data.subtitleKey.tr,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size6),
            // ── Chips ──
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A878FB0),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ]),
              child: Wrap(
                spacing: SizeConfig.size6,
                runSpacing: SizeConfig.size6,
                children: data.chipKeys
                    .map((key) => _chip(key, data.chipBg, data.chipText))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String labelKey, Color bg, Color textColor) {
    final isMore = labelKey == AppStrings.chipMore;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: isMore ? AppColors.whiteF3 : bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        labelKey.tr,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: isMore ? AppColors.secondaryTextColor : textColor,
      ),
    );
  }
}
