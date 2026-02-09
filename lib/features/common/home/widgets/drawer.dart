import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../../environment_config.dart';
import '../../../../widgets/common_dialog.dart';
import '../../../../widgets/custom_btn.dart';
import '../../../../widgets/webview_common.dart';
import '../../../business/auth/controller/view_business_details_controller.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/auth/service/location_update_service.dart';
import '../../../personal/auth/controller/view_personal_details_controller.dart';
import '../../../personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import '../../../personal/personal_profile/view/create_profile_screen.dart';
import '../../../personal/personal_profile/view/app_tutorial/view/app_tutorial.dart';
import '../../../personal/personal_profile/view/documents.dart';
import '../../../personal/personal_profile/view/help_and_support_screen/help_and_support_screen.dart';
import '../../../personal/personal_profile/view/payment/view/payment_setting_screen.dart';
import '../../../personal/personal_profile/view/profile_settings_new_screen.dart';
import '../../../subscription/view/subscription_screen.dart';
import '../../../subscription/view/subscrption_new.dart';
import '../../auth/controller/auth_controller.dart';
import '../../referral/view/referral_page.dart';

class ProfileMenuDrawer extends StatefulWidget {
  const ProfileMenuDrawer({super.key});

  @override
  State<ProfileMenuDrawer> createState() => _ProfileMenuDrawerState();
}

class _ProfileMenuDrawerState extends State<ProfileMenuDrawer> {
  final viewProfileController = getOrPut(() => ViewPersonalDetailsController());
  final viewBusinessProfileController = Get.put(ViewBusinessDetailsController());


  String accountProfileName(){
    if (accountTypeGlobal != "BUSINESS") {
      return _capitalizeFirstLetter(
        viewProfileController
            .personalProfileDetails.value.user?.name ??
            '',
      );
    }else{
      return _capitalizeFirstLetter(
        viewBusinessProfileController.businessProfileDetails?.data?.businessName ??
            '',
      );
    }
  }
  String accountProfileImage(){
    if (accountTypeGlobal != "BUSINESS") {
      return Get
          .find<AuthController>()
          .imgPath
          .value;
    }else{
      return
        viewBusinessProfileController.imagePath?.value??"";
    }
  }

  String userDesigination(){
    if (accountTypeGlobal != "BUSINESS") {
      return viewProfileController.personalProfileDetails.value
          .user?.designation??'';
    }else{
      return _capitalizeFirstLetter(
        viewBusinessProfileController.businessProfileDetails?.data?.categoryDetails?.name ??
            '',
      );
    }
  }


  Future<void> _loadInitialData() async {
    if (accountTypeGlobal != "BUSINESS") {
      await viewProfileController.viewPersonalProfile();
    }else{
      viewBusinessProfileController.viewBusinessProfile();
    }
    if (userProfileTypeGlobal == SELF_EMPLOYED &&
        earnServiceCreatedStatusGlobal == 'false') {
      viewProfileController.partiallyForceToCreateService();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    _loadInitialData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.white,
        child: Column(
          children: [
            Obx(() {
              return _header();
            }),
            _walletRow(),
            const SizedBox(height: 6),
            Expanded(child: _menuList()),
            _footer(),
          ],
        ),
      ),
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                SizedBox(height: 4),
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
    );
  }
  final LiveLocationService locationService = LiveLocationService();

  Future<void> clearAllLocalDataOnLogout() async {
    try {
      // 1️⃣ Clear all Hive boxes
      await Hive.deleteFromDisk();

      // 2️⃣ Clear stored media files
      final dir = await getApplicationDocumentsDirectory();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }


    } catch (e) {

    }
  }
  Widget _walletRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryColor),
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.blueShade.withOpacity(0.1)
              ),
              child: Row(
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.walletIcon,
                    height: 20,
                    width: 20,
                    imgColor: AppColors.secondaryTextColor,
                  ),
                  SizedBox(width: 6),
                  CustomText(
                    "Wallet",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  CustomText(
                    "  ₹522",
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8,),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.whiteE5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: const CustomText(
                "Cards",
                fontSize: 13,
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
          onTap: () => Get.to(() => AppTutorialScreen())

      ),
      MenuItemModel(
        title: "Refer & Earn",
        onTap: () => Get.to(() => ReferralPage()),
      ),
      if(accountTypeGlobal!="BUSINESS")
      MenuItemModel(
        title: "Earn with BlueEra",
        onTap: () {
          if (viewProfileController
              .personalProfileDetails.value.isProfileCreated ==
              false) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CreateProfileScreen()));
          } else {
            Get.toNamed(
                RouteHelper.getEarnServiceAvailableOptionsScreenRoute()
            );
          }
        },

      ),
      MenuItemModel(
          title: "Subscription",
          onTap: () => Get.to(() => SubscriptionScreenNew())
      ),
      MenuItemModel(
        title: "Payment",
        onTap: () => Get.to(() => PaymentSettingScreen()),

      ),
      MenuItemModel(
        title: "My Channel",
        onTap: () {
          if (channelId.isNotEmpty) {
            Get.toNamed(
              RouteHelper.getChannelScreenRoute(),
              arguments: {
                ApiKeys.argAccountType: accountTypeGlobal,
                ApiKeys.channelId: channelId,
                ApiKeys.authorId:
                (accountTypeGlobal == AppConstants.individual)
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
          onTap: () => Get.to(() => AddYourDocumentScreen())

      ),
      MenuItemModel(
        title: "Franchise Inquiry",
        onTap: () =>
            Get.to(
                  () =>
                  CommonWebView(
                    urlLink: takeFranchise,
                    urlTitle: AppStrings.applyForFranchise,
                  ),
            ),
      ),
      MenuItemModel(
        title: "Account Settings",
        onTap: () => Get.to(() => AccountSettingScreen()),
      ),
      // MenuItemModel(
      //   title: "Profile Settings",
      //   onTap: () => Get.to(() => ProfileSettingsNewScreen()),
      //
      // ),
      MenuItemModel(
        title: "Manage Notification",
        onTap: () => Get.toNamed(RouteHelper.getNotificationScreenRoute()),


      ),
      MenuItemModel(
        title: "Help & Support",
        onTap: () => Get.to(HelpAndSupportScreen()),
      ),

    ];

    return ListView.separated(
      itemCount: menus.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: AppColors.whiteE5),
      itemBuilder: (context, index) {
        final item = menus[index];

        return InkWell(
          onTap: item.onTap,
          child: ListTile(
            leading: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.whiteE5,
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 20,
                color: AppColors.secondaryTextColor,
              ),
            ),

            title: GestureDetector(
              onTap: item.onTap,
              child: CustomText(
                item.title,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            subtitle: const CustomText(
              "Learn how to earn with BlueEra",
              fontSize: 10,
              maxLines: 1,
              color: AppColors.secondaryTextColor,
            ),

            trailing: GestureDetector(
              onTap: item.onTap,
              child: const Icon(
                Icons.chevron_right,
                size: 30,
                color: AppColors.secondaryTextColor,
              ),
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
                              (Route<dynamic> route) => false);
                    },
                    cancelCallback: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    confirmText: AppStrings.yes,
                    cancelText: AppStrings.no);
              },
              title: AppStrings.logout,
              bgColor: Colors.white,
              textColor: AppColors.red,
              borderColor: AppColors.red,
              radius: 10.0),
          SizedBox(height: 10,),
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
            children: const [
              CustomText(
                "English",
                fontSize: 10,
              ),
              SizedBox(width: 6),
              CustomText(
                "Change Language?",
                fontSize: 10,
                color: AppColors.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CustomText(
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
