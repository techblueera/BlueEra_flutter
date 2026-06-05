import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/language_localization_service/language_controller_new.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../business/auth/controller/view_business_details_controller.dart';
import '../../../contribution/view/contribution_screen.dart';
import '../../../personal/auth/controller/view_personal_details_controller.dart';
import '../../../personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import '../../../personal/personal_profile/view/app_tutorial/view/app_tutorial.dart';
import '../../../personal/personal_profile/view/franchise/request_to_franchise.dart';
import '../../../personal/personal_profile/view/help_and_support_screen/help_and_support_screen.dart';
import '../../../personal/personal_profile/view/manage_notification/notification.dart';
import '../../../personal/personal_profile/view/payment/view/payment_setting_screen.dart';
import '../../../personal/personal_profile/view/wallet/wallet_screen.dart';
import '../../../personal/personal_profile/view/widget/changes_languages_screen.dart';
import '../../auth/controller/auth_controller.dart';
import '../../connect/view/connect_main_page.dart';
import '../view/saved_feed_screen.dart';

/// Editorial profile drawer — frosted-glass shell over an aurora hero
/// header, a premium wallet card, and color-coded menu sections. Each
/// section anchors its items to a tonal accent so the eye groups by
/// color rather than position. Mirrors the aurora hero on the
/// ContributionScreen for cross-screen recognition.
class ProfileMenuDrawer extends StatefulWidget {
  const ProfileMenuDrawer({super.key});

  @override
  State<ProfileMenuDrawer> createState() => _ProfileMenuDrawerState();
}

class _ProfileMenuDrawerState extends State<ProfileMenuDrawer> {
  final viewProfileController = getOrPut(() => ViewPersonalDetailsController());
  final viewBusinessProfileController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  final lang = getOrPut(() => LanguageControllerNew());

  // Section accent palette — each menu group is anchored to a tonal
  // family so the eye groups items by color rather than position.
  static const _indigo = Color(0xFF4F46E5);
  static const _violet = Color(0xFF7C3AED);
  static const _emerald = Color(0xFF059669);
  static const _amber = Color(0xFFD97706);
  static const _gold = Color(0xFFF59E0B);
  static const _teal = Color(0xFF0D9488);
  static const _blue = Color(0xFF2563EB);
  static const _slate = Color(0xFF475569);
  static const _copper = Color(0xFFB7781F);
  static const _rose = Color(0xFFE11D48);
  static const _cyan = Color(0xFF0891B2);

  @override
  void initState() {
    _loadInitialData();
    super.initState();
  }

  Future<void> _loadInitialData() async {
    if (accountTypeGlobal != "BUSINESS") {
      await viewProfileController.viewPersonalProfile();
    } else {
      viewBusinessProfileController.viewBusinessProfile();
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Closes the drawer, then runs [action]. Action is deferred to the
  /// next microtask so the drawer's about-to-deactivate context is no
  /// longer in use when the destination screen pushes.
  void _closeAndRun(VoidCallback action) {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
    Future.microtask(action);
  }

  String accountProfileName() {
    if (accountTypeGlobal != "BUSINESS") {
      return _capitalizeFirstLetter(
        viewProfileController.personalProfileDetails.value.user?.name ?? '',
      );
    } else {
      return _capitalizeFirstLetter(
        viewBusinessProfileController.businessProfileDetails.value?.data?.businessName ?? '',
      );
    }
  }

  String accountProfileImage() {
    if (accountTypeGlobal != "BUSINESS") {
      return Get.find<AuthController>().imgPath.value;
    } else {
      return viewBusinessProfileController.imagePath?.value ?? "";
    }
  }

  String userDesigination() {
    if (accountTypeGlobal != "BUSINESS") {
      return viewProfileController.personalProfileDetails.value.user?.designation ?? '';
    } else {
      return _capitalizeFirstLetter(
        viewBusinessProfileController.businessProfileDetails.value?.data?.categoryDetails?.name ?? '',
      );
    }
  }

  /// Letter-spaced label for the hero pill — surfaces the user's role
  /// at a glance ("BUSINESS", "PROFESSIONAL", etc.) and falls back to
  /// "MEMBER" when no profile-type signal is available.
  String _accountTypeLabel() {
    if (accountTypeGlobal == "BUSINESS") return AppStrings.accountTypeBusiness.tr;
    if (userProfileTypeGlobal == SOCIAL_PROFILE) return AppStrings.accountTypeSocial.tr;
    if (userProfileTypeGlobal == PROFESSIONAL) return AppStrings.accountTypeProfessional.tr;
    if (userProfileTypeGlobal == SELF_EMPLOYED) return AppStrings.accountTypeSelfEmployed.tr;
    if (userProfileTypeGlobal == GIG_WORKER) return AppStrings.accountTypeGigWorker.tr;
    return AppStrings.accountTypeMember.tr;
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Color(0x29000000),
            offset: Offset(2, 0),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: const BoxDecoration(
              // Glossy white — diagonal sheen from a bright top-left
              // highlight (#FFFFFF) through a cool mid (#F7FAFE) into
              // a faint pale-blue bottom (#EAF0F8). Reads as a polished
              // pane catching light rather than a flat white surface.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF7FAFE),
                  Color(0xFFEAF0F8),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: radius,
              border: Border(
                right: BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => _heroHeader()),
                    SizedBox(height: SizeConfig.size12),
                    _walletCard(),
                    SizedBox(height: SizeConfig.size16),
                    ..._buildSectionedMenu(),
                    SizedBox(height: SizeConfig.size8),
                    _footer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HERO HEADER — Aurora gradient with floating orbs, gold-ringed
  // avatar, glass tier pill, name in display weight, and designation
  // underneath. Recognition twin of the ContributionScreen hero.
  // ─────────────────────────────────────────────
  Widget _heroHeader() {
    final image = accountProfileImage();
    final name = accountProfileName();
    final designation = userDesigination();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D2B1B5C),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1F1B5C),
                      Color(0xFF5E2BA8),
                      Color(0xFFB2308C),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              right: 30,
              top: 60,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFC07A).withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFCD34D),
                          Color(0xFFF59E0B),
                          Color(0xFFB7781F),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66FCD34D),
                          blurRadius: 14,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: image.isNotEmpty
                          ? Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _avatarFallback(),
                            )
                          : _avatarFallback(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 11,
                                color: Color(0xFFFFD9B0),
                              ),
                              const SizedBox(width: 4),
                              CustomText(
                                _accountTypeLabel(),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomText(
                          name.isNotEmpty ? name : AppStrings.blueEraMember.tr,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        CustomText(
                          designation.isNotEmpty ? designation : AppStrings.tapToViewProfile.tr,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.78),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: Colors.white,
      child: const Icon(Icons.person_rounded, size: 28, color: Color(0xFF5E2BA8)),
    );
  }

  // ─────────────────────────────────────────────
  // WALLET CARD — primary-tinted gradient surface, circular gradient
  // badge, large rupee + amount display, solid forward chevron CTA.
  // ─────────────────────────────────────────────
  Widget _walletCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _closeAndRun(() => Get.to(() => WalletScreen())),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.primaryColor.withValues(alpha: 0.05),
                  AppColors.primaryColor.withValues(alpha: 0.14),
                ],
              ),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A001120),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withValues(alpha: 0.78),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        AppStrings.wallet.tr.toUpperCase(),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryTextColor,
                        letterSpacing: 1.2,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          CustomText(
                            '₹',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 2),
                          CustomText(
                            '0',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.mainTextColor,
                            letterSpacing: -0.5,
                          ),
                          const SizedBox(width: 6),
                          CustomText(
                            AppStrings.availableLabel.tr,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTIONED MENU — items grouped into ACCOUNT / EARNINGS /
  // MEMBERSHIP / WORKSPACE / SETTINGS. Each tile gets a tonal Material
  // icon chip — its accent codes the section.
  // ─────────────────────────────────────────────
  List<Widget> _buildSectionedMenu() {
    final isIndividual = accountTypeGlobal == AppConstants.individual;
    final isNotSocial = userProfileTypeGlobal != SOCIAL_PROFILE;

    final sections = <_DrawerSection>[
      _DrawerSection(AppStrings.accountSectionLabel.tr, [
        _DrawerItem(
          icon: Icons.school_outlined,
          color: _indigo,
          title: AppStrings.appTutorial.tr,
          onTap: () => Get.to(() => AppTutorialScreen()),
        ),
        _DrawerItem(
          icon: Icons.bookmark_outline_rounded,
          color: _amber,
          title: AppStrings.saved.tr,
          onTap: () {
            Get.to(() => SavedFeedScreen(selectedTab: SavedFeedTab.posts, headerHeight: SizeConfig.size30));
          },
        ),
      ]),
      _DrawerSection(AppStrings.earningsSectionLabel.tr, [
        _DrawerItem(
          icon: Icons.share_outlined,
          color: _violet,
          title: AppStrings.referAndEarn.tr,
          onTap: () => Get.to(() => ReferralPage()),
        ),
        if (isIndividual)
          _DrawerItem(
            icon: Icons.work_outline_rounded,
            color: _emerald,
            title: AppStrings.earnWithBlueEra.tr,
            onTap: () {
              final earnTypes = viewProfileController.earnProfileType;
              debugPrint('[drawer.earnWithBlueEra] earnTypes=$earnTypes');
              if (earnTypes.isEmpty) {
                Get.toNamed(RouteHelper.getChooseEarnServiceScreenRoute());
              } else {
                Get.toNamed(RouteHelper.getEarnServiceDashboardViewRoute());
              }
            },
          ),
      ]),
      _DrawerSection(AppStrings.membershipSectionLabel.tr, [
        if (isNotSocial)
          _DrawerItem(
            icon: Icons.workspace_premium_rounded,
            color: _gold,
            title: AppStrings.contribution.tr,
            onTap: () => Get.to(() => const ContributionScreen()),
          ),
        _DrawerItem(
          icon: Icons.payments_outlined,
          color: _teal,
          title: AppStrings.payment.tr,
          onTap: () => Get.to(() => PaymentSettingScreen()),
        ),
      ]),
      _DrawerSection(AppStrings.workspaceSectionLabel.tr, [
        _DrawerItem(
          icon: Icons.podcasts_rounded,
          color: _blue,
          title: AppStrings.channelAndCommunity.tr,
          onTap: () {
            if (channelId.isNotEmpty) {
              Get.toNamed(
                RouteHelper.getChannelScreenRoute(),
                arguments: {
                  ApiKeys.argAccountType: accountTypeGlobal,
                  ApiKeys.channelId: channelId,
                  ApiKeys.authorId: (accountTypeGlobal == AppConstants.individual) ? userId : businessId
                },
              );
            } else {
              Navigator.pushNamed(
                context,
                RouteHelper.getManageChannelScreenRoute(),
              );
            }
          },
        ),
        _DrawerItem(
          icon: Icons.description_outlined,
          color: _slate,
          title: AppStrings.myDocuments.tr,
          onTap: () => Get.toNamed(
            RouteHelper.getAddDocumentScreenRoute(),
            arguments: {
              ApiKeys.showViewDocProof: true,
              ApiKeys.argDocumentVia:
                  isIndividual ? AppConstants.personalDocumentScreen : AppConstants.businessDocumentScreen
            },
          ),
        ),
        _DrawerItem(
          icon: Icons.business_outlined,
          color: _copper,
          title: AppStrings.franchiseInquiry.tr,
          onTap: () => Get.to(() => FranchiseInquiryScreen()),
        ),
      ]),
      _DrawerSection(AppStrings.settingsSectionLabel.tr, [
        _DrawerItem(
          icon: Icons.settings_outlined,
          color: _slate,
          title: AppStrings.accountSettings.tr,
          onTap: () => Get.to(() => AccountSettingScreen()),
        ),
        _DrawerItem(
          icon: Icons.notifications_outlined,
          color: _rose,
          title: AppStrings.manageNotification.tr,
          onTap: () => Get.to(NotificationSettingScreen()),
        ),
        _DrawerItem(
          icon: Icons.support_agent_rounded,
          color: _cyan,
          title: AppStrings.helpSupport.tr,
          onTap: () => Get.to(HelpAndSupportScreen()),
        ),
      ]),
    ];

    final widgets = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final s = sections[i];
      if (s.items.isEmpty) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: CustomText(
          s.label,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.secondaryTextColor,
          letterSpacing: 1.6,
        ),
      ));
      for (final item in s.items) {
        widgets.add(_menuTile(item));
      }
    }
    return widgets;
  }

  Widget _menuTile(_DrawerItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _closeAndRun(item.onTap),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.color.withValues(alpha: 0.20),
                    width: 0.8,
                  ),
                ),
                child: Icon(item.icon, size: 19, color: item.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CustomText(
                  item.title,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.secondaryTextColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER — rose-tinted ghost logout, dot-separated policy links,
  // brand-tinted language toggle pill, tight version line.
  // ─────────────────────────────────────────────
  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _closeAndRun(
                  () => LogoutHelper.showLogoutDialog(Get.context ?? context)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 17, color: Color(0xFFE11D48)),
                    const SizedBox(width: 8),
                    CustomText(
                      AppStrings.logout.tr,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFE11D48),
                      letterSpacing: 0.4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                AppStrings.termsLabel.tr,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              const CustomText(
                '  ·  ',
                fontSize: 10,
                color: AppColors.secondaryTextColor,
              ),
              CustomText(
                AppStrings.privacyLabel.tr,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              const CustomText(
                '  ·  ',
                fontSize: 10,
                color: AppColors.secondaryTextColor,
              ),
              CustomText(
                AppStrings.policiesLabel.tr,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _closeAndRun(() => Get.to(() => ChangeLanguageScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.20),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.translate_rounded, size: 12, color: AppColors.primaryColor),
                  const SizedBox(width: 5),
                  CustomText(
                    lang.selectedLang.toUpperCase(),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                    letterSpacing: 0.6,
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.swap_horiz_rounded, size: 12, color: AppColors.primaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CustomText(
                'v 1.0.1',
                fontSize: 10,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(width: 6),
              const CustomText(
                '·',
                fontSize: 10,
                color: AppColors.secondaryTextColor,
              ),
              const SizedBox(width: 6),
              CustomText(
                AppStrings.madeInIndia.tr,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerSection {
  final String label;
  final List<_DrawerItem> items;
  const _DrawerSection(this.label, this.items);
}

class _DrawerItem {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });
}
