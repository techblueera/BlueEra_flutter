import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_visting_cards.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/language_localization_service/language_controller_new.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../../widgets/common_dialog.dart';
import '../../../../widgets/custom_btn.dart';
import '../../../business/auth/controller/view_business_details_controller.dart';
import '../../../business/visiting_card/view/business_own_profile_screen.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/auth/service/location_update_service.dart';
import '../../../personal/auth/controller/view_personal_details_controller.dart';
import '../../../personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import '../../../personal/personal_profile/view/create_profile_screen.dart';
import '../../../personal/personal_profile/view/app_tutorial/view/app_tutorial.dart';
import '../../../personal/personal_profile/view/franchise/request_to_franchise.dart';
import '../../../personal/personal_profile/view/help_and_support_screen/help_and_support_screen.dart';
import '../../../personal/personal_profile/view/manage_notification/notification.dart';
import '../../../personal/personal_profile/view/payment/view/payment_setting_screen.dart';
import '../../../personal/personal_profile/view/profile_setup_new_screen.dart';
import '../../../personal/personal_profile/view/widget/changes_languages_screen.dart';
import '../../../subscription/view/subscrption_new.dart';
import '../../auth/controller/auth_controller.dart';
import '../../referral/view/referral_page.dart';
import '../view/home_screen.dart';
import '../view/saved_feed_screen.dart';

class ProfileMenuDrawer extends StatefulWidget {
  const ProfileMenuDrawer({super.key});

  @override
  State<ProfileMenuDrawer> createState() => _ProfileMenuDrawerState();
}

class _ProfileMenuDrawerState extends State<ProfileMenuDrawer> {
  final viewProfileController = getOrPut(() => ViewPersonalDetailsController());
  final viewBusinessProfileController =
  Get.put(ViewBusinessDetailsController());

  final LiveLocationService locationService = LiveLocationService();
  final lang = getOrPut(() => LanguageControllerNew());

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
    if (userProfileTypeGlobal == SELF_EMPLOYED &&
        earnServiceCreatedStatusGlobal == 'false') {
      viewProfileController.partiallyForceToCreateService();
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String accountProfileName() {
    if (accountTypeGlobal != "BUSINESS") {
      return _capitalizeFirstLetter(
        viewProfileController.personalProfileDetails.value.user?.name ?? '',
      );
    } else {
      return _capitalizeFirstLetter(
        viewBusinessProfileController
            .businessProfileDetails?.data?.businessName ??
            '',
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
      return viewProfileController
          .personalProfileDetails.value.user?.designation ??
          '';
    } else {
      return _capitalizeFirstLetter(
        viewBusinessProfileController
            .businessProfileDetails?.data?.categoryDetails?.name ??
            '',
      );
    }
  }

  Future<void> clearAllLocalDataOnLogout() async {
    try {
      await Hive.deleteFromDisk();
      final dir = await getApplicationDocumentsDirectory();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Obx(() => _header()),
              _walletRow(),
              const SizedBox(height: 6),
              _menuList(),
              Divider(color: AppColors.whiteE5),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: InkWell(
        onTap: () {
          if (isGuestUser()) {
            createProfileScreen();
          } else if (isIndividualUser()) {
            navigatePushTo(context, PersonalProfileSetupNewScreen());
          } else if (isBusinessUser()) {
            navigatePushTo(context, BusinessOwnProfileScreen());
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(accountProfileImage()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    accountProfileName(),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    userDesigination(),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryColor),
                borderRadius: BorderRadius.circular(10),
                color: AppColors.blueShade.withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.walletIcon,
                    height: 20,
                    width: 20,
                    imgColor: AppColors.secondaryTextColor,
                  ),
                  const SizedBox(width: 6),
                  const CustomText(
                    "Wallet",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  const CustomText(
                    "  ₹0",
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {

              if(accountTypeGlobal == AppConstants.individual){
                final viewProfileController = Get.find<ViewPersonalDetailsController>();
                Get.to(()=> AllVisitingCards(
                    personalDetails: viewProfileController.personalProfileDetails.value,
                    showAppBar: true
                )
                );
              }else{
                final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController());
                Get.to(()=> AllVisitingCards(
                    businessDetails: viewBusinessDetailsController.businessProfileDetails?.data,
                    showAppBar: true
                  )
                );
              }

              // Get.toNamed(
              //   RouteHelper.getMoreCardsScreenRoute(),
              //   arguments: {ApiKeys.isFromHomeScreen: false},
              // );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.whiteE5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: CustomText(
                  "Cards",
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuList() {
    final List<MenuItemModel> menus = [
      MenuItemModel(
        title: "App Tutorial",
        onTap: () => Get.to(AppTutorialScreen()),
      ),
      MenuItemModel(
        title: "Refer & Earn",
        onTap: () => Get.to(ReferralPage()),
      ),
      if (accountTypeGlobal != "BUSINESS")
        MenuItemModel(
          title: "Earn with BlueEra",
          onTap: () {
            if (viewProfileController.personalProfileDetails.value
                .isProfileCreated ==
                false) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateProfileScreen(),
                ),
              );
            } else {
              Get.toNamed(
                  RouteHelper.getEarnServiceAvailableOptionsScreenRoute());
            }
          },
        ),
      MenuItemModel(
        title: "Saved",
        onTap: (){
          Get.to( SavedFeedScreen(
              selectedTab:SavedFeedTab.posts,
              headerHeight: SizeConfig.size30));
         ;
        },
      ),
      MenuItemModel(
        title: "Subscription",
        onTap: () => Get.to(SubscriptionScreenNew()),
      ),
      MenuItemModel(
        title: "Payment",
        onTap: () => Get.to(PaymentSettingScreen()),
      ),
      MenuItemModel(
        title: "Channel & Community",
        onTap: () {
          if (channelId.isNotEmpty) {
            Get.toNamed(
              RouteHelper.getChannelScreenRoute(),
              arguments: {
                ApiKeys.argAccountType: accountTypeGlobal,
                ApiKeys.channelId: channelId,
                ApiKeys.authorId: (accountTypeGlobal ==
                    AppConstants.individual)
                    ? userId
                    : businessId
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
      MenuItemModel(
        title: "My Documents",
        onTap: () => Get.toNamed(
          RouteHelper.getAddDocumentScreenRoute(),
          arguments: {
            ApiKeys.showViewDocProof:true,
            ApiKeys.argDocumentVia: isIndividual()
                ? AppConstants.personalDocumentScreen
                : AppConstants.businessDocumentScreen
          },
        ),
      ),
      MenuItemModel(
        title: "Franchise Inquiry",
        onTap: () => Get.to(FranchiseInquiryScreen()),
      ),
      MenuItemModel(
        title: "Account Settings",
        onTap: () => Get.to(AccountSettingScreen()),
      ),
      MenuItemModel(
        title: "Manage Notification",
        onTap: () => Get.to(NotificationSettingScreen()),
      ),
      MenuItemModel(
        title: "Help & Support",
        onTap: () => Get.to(HelpAndSupportScreen()),
      ),
    ];

    List icons = [
      'assets/images/tutorial.png',
      'assets/images/refer.png',
      'assets/images/earn.png',
      'assets/images/subscrption.png',
      'assets/images/subscrption.png',
      'assets/images/payment.png',
      'assets/images/channel.png',
      'assets/images/documents.png',
      'assets/images/franchise.png',
      'assets/images/profilesetting.png',
      'assets/images/notify.png',
      'assets/images/help.png'
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount: menus.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: AppColors.whiteE5),
      itemBuilder: (context, index) {
        final item = menus[index];
        return InkWell(
          onTap: item.onTap,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.circleBg,
              ),
              child: LocalAssets(
                imagePath: icons[index],
                height: 24,
                width: 24,
              ),
            ),
            title: CustomText(
              item.title,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            subtitle: const CustomText(
              "Learn how to earn with BlueEra",
              fontSize: 10,
              maxLines: 1,
              color: AppColors.secondaryTextColor,
            ),
            trailing: const Icon(
              Icons.chevron_right,
              size: 30,
              color: AppColors.secondaryTextColor,
            ),
          ),
        );
      },
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          CustomBtn(
            onTap: () async {
              await showCommonDialog(
                context: context,
                text: AppStrings.logoutConfirmationMessage,
                confirmCallback: () async {
                  deleteIfRegistered<ChatViewController>();
                  await SharedPreferenceUtils.clearPreference();
                  locationService.stop();
                  await clearAllLocalDataOnLogout();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    RouteHelper.getMobileNumberLoginRoute(),
                        (Route<dynamic> route) => false,
                  );
                },
                cancelCallback: () {
                  Navigator.of(context).pop();
                },
                confirmText: AppStrings.yes,
                cancelText: AppStrings.no,
              );
            },
            title: AppStrings.logout,
            bgColor: Colors.white,
            textColor: AppColors.primaryColor,
            borderColor: AppColors.primaryColor,
            radius: 10.0,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CustomText(
                "Terms & Conditions ",
                fontSize: 10,
                color: AppColors.secondaryTextColor,
              ),
              CustomText(
                "Privacy Policy ",
                fontSize: 10,
                color: AppColors.secondaryTextColor,
              ),
              CustomText(
                "See all policies ",
                fontSize: 10,
                color: AppColors.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                lang.selectedLang.toUpperCase(),
                fontSize: 10,
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Future.microtask(() {
                    navigatePushTo(context, ChangeLanguageScreen());
                  });
                },
                child: const CustomText(
                  "Change Language?",
                  fontSize: 10,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CustomText(
                "v 1.0.1",
                fontSize: 11,
                color: AppColors.secondaryTextColor,
              ),
              Icon(Icons.flag, size: 14),
              SizedBox(width: 4),
              CustomText(
                "Made in India",
                fontSize: 11,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MenuItemModel {
  final String title;
  final VoidCallback onTap;

  MenuItemModel({required this.title, required this.onTap});
}