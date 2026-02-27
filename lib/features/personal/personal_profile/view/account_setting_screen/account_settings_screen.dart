import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/two_step_verify_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/shared_preference_utils.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../../../widgets/common_dialog.dart';
import '../../../../business/auth/controller/view_business_details_controller.dart';
import '../../../../chat/auth/controller/chat_view_controller.dart';
import '../../../../chat/auth/service/location_update_service.dart';
import '../../../../subscription/view/subscrption_new.dart';
import '../widget/changes_languages_screen.dart';

class AccountSettingScreen extends StatefulWidget {
  const AccountSettingScreen({super.key});

  @override
  State<AccountSettingScreen> createState() => _AccountSettingScreenState();
}

class _AccountSettingScreenState extends State<AccountSettingScreen> {

  final controller = getOrPut(() => LanguageControllerNew());
  final LiveLocationService locationService = LiveLocationService();

  final viewBusinessProfileController = Get.put(ViewBusinessDetailsController());
  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(

        title: AppStrings.accountSettings,
        isLeading: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8,vertical: 12),
        child: Obx(() {
          // ✅ Safe Navigation
          // if (accountController.index == '1') {
          //   Future.microtask(() {
          //     accountController.setIndex('0');
          //     navigatePushTo(context, UpdateProfileScreen());
          //   });
          //   return SizedBox();
          // } else if (accountController.index == '2') {
          //   return Column(
          //     children: [
          //       // SizedBox(height: SizeConfig.size20),
          //       // _buildHelpFormSection(accountController),
          //     ],
          //   );
          // } else if (accountController.index == '3') {
          //   return Text("Data");
          //   // QueriesCard();
          // } else if (accountController.index == '4') {
          //   Future.microtask(() {
          //     accountController.setIndex('0');
          //     navigatePushTo(context, ChangeLanguageScreen());
          //   });
          //   return SizedBox();
          // }

          return ListView(
            children: [



              // _helpServiceCard(
              //   AppIconAssets.app_setting_edit_profile,
              //   AppStrings.editProfile,
              //       () {
              //     accountController.setIndex("1");
              //     accountController.setTitle("Edit Profile");
              //   },
              // ),

              // _helpServiceCard(
              //   AppIconAssets.editIcon,
              //   "Edit Category",
              //       () {
              //     accountController.setIndex("9");
              //     accountController.setTitle("Edit Category");
              //   },
              // ),
              //
              // _helpServiceCard(
              //   AppIconAssets.app_setting_change_phone_number,
              //   AppStrings.changePhoneNumber,
              //       () {
              //     accountController.setIndex("2");
              //     accountController.setTitle("Change Phone number");
              //   },
              // ),

              // _helpServiceCard(
              //   AppIconAssets.emotionUpdate,
              //   "Change Your Email",
              //       () {
              //     accountController.setIndex("10");
              //     accountController.setTitle("Change Email");
              //   },
              // ),
              //
              // _helpServiceCard(
              //   AppIconAssets.verifiedIcon,
              //   "Email Verification",
              //       () {},
              //   slugId: "Email Verification",
              // ),

              _helpServiceCard(
                AppIconAssets.app_setting_language,
                AppStrings.language,
                    () {
                      navigatePushTo(context, ChangeLanguageScreen());
                },
                slugId: "Language",
              ),
              if(accountTypeGlobal == "BUSINESS")
                _helpServiceCard(
                AppIconAssets.app_setting_verification,
                AppStrings.verificationStatus,
                    () {
                      // navigatePushTo(context, UpdateProfileScreen());
                },
                slugId: "Verification Status",
                  isVerified: viewBusinessProfileController.isBusinessVerified.value
              ),

              _helpServiceCard(
                AppIconAssets.app_setting_manage_subscription,
                AppStrings.manageSubscription,
                    () {
                      Get.to(()=> SubscriptionScreenNew());
                  // accountController.setIndex("6");
                  // accountController.setTitle("Manage Subscription");
                },
                slugId: "Manage Subscription",
              ),

              _helpServiceCard(
               'assets/images/two_step.png',
                "Two Step Authentication",
                    () {
                      navigatePushTo(context, TwoStepVerifyScreen());

                },
              ),

              _helpServiceCard(
                AppIconAssets.deleteIcon,
                "Account Delete",
                    () async{

                        await showCommonDialog(
                        context: context,
                        text: AppStrings.deleteAccountConfirmationMessage,
                        confirmCallback: () async {
                          await SharedPreferenceUtils.clearPreference();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              RouteHelper.getMobileNumberLoginRoute(),
                                  (Route<dynamic> route) => false);
                        },
                        cancelCallback: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        confirmText: AppStrings.yes,
                        cancelText: AppStrings.no);

                  // accountController.setIndex("8");
                  // accountController.setTitle("Delete Account");
                },
              ),

              _helpServiceCard(
                AppIconAssets.logout,

                "Device Logout",
                    () async{
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
                  // accountController.setIndex("11");
                  // accountController.setTitle("Device Logout");
                },
              ),

              SizedBox(height: SizeConfig.size30),
            ],
          );
        }),
      ),
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

Widget _helpServiceCard(
    String iconPath,
    String title,
    GestureTapCallback? onTap, {
      String? slugId,
      bool? isVerified
    }) {
  final lang = getOrPut(() => LanguageControllerNew());

  return Padding(
    padding: EdgeInsets.only(bottom: SizeConfig.size10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.whiteE5,
            width: 1,
          ),

        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              visualDensity: VisualDensity.compact, // removes extra layout space

              splashRadius: 12,
              iconSize: 20,
              icon: LocalAssets(
                imagePath: iconPath,
                height: 20,
                width: 20,
                boxFix: BoxFit.cover,
                imgColor: AppColors.secondaryTextColor,
              ),
            )
            ,

            SizedBox(width: SizeConfig.size8),

            // Title
            Expanded(
              child: CustomText(
                title,
                fontSize: SizeConfig.medium,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Right Side Controls (as per image)
            if (slugId == "Email Verification")
              _statusChip((isVerified==true)?"Verified":"Pending", isGreen: isVerified==true),

            if (slugId == "Language")
              _statusChip(lang.selectedLang.value, isGrey: true),

            if (slugId == "Verification Status")
              _statusChip("Owner Verified", isGreen: true),

            if (slugId == "Manage Subscription")
              CustomText(
                "Free Plan",
                color: AppColors.primaryColor,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
              ),

          ],
        ),
      ),
    ),
  );
}
Widget _statusChip(
    String text, {
      bool isGreen = false,
      bool isGrey = false,
    }) {
  Color bgColor;
  Color textColor;

  if (isGreen) {
    bgColor = AppColors.green4F;
    textColor = Colors.white;
  } else if (isGrey) {
    bgColor = Colors.grey.shade200;
    textColor = AppColors.mainTextColor;
  } else {
    bgColor = Colors.grey.shade200;
    textColor = AppColors.mainTextColor;
  }

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: SizeConfig.size12,
      vertical: SizeConfig.size6,
    ),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: CustomText(
      text,
      fontSize: SizeConfig.size10,
      color: textColor,
      fontWeight: FontWeight.w500,
    ),
  );
}
Widget _greenChip(String text) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: SizeConfig.size14,
      vertical: SizeConfig.size6,
    ),
    decoration: BoxDecoration(
      color: AppColors.green4F,
      borderRadius: BorderRadius.circular(20),
    ),
    child: CustomText(
      text,
      fontSize: SizeConfig.size10,
      color: Colors.white,
    ),
  );
}
Widget _greyChip(String text) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: SizeConfig.size14,
      vertical: SizeConfig.size6,
    ),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
    ),
    child: CustomText(
      text,
      fontSize: SizeConfig.size10,
      color: AppColors.mainTextColor,
    ),
  );
}


Widget buildSettingItem({
  required String imagePath,
  required String title,
  required Widget control,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: SizeConfig.size14),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size14,
        vertical: SizeConfig.size14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          LocalAssets(
            imagePath: imagePath,
            height: 22,
            width: 22,
          ),
          SizedBox(width: SizeConfig.size14),
          Expanded(
            child: CustomText(title),
          ),
          control,
        ],
      ),
    ),
  );
}
Widget buildToggleSwitch({
  required RxBool value,
  required VoidCallback onChanged,
}) {
  return Obx(() => Transform.scale(
    scale: 0.75, // Adjust scale to reduce size
    child: Switch(
      value: value.value,
      onChanged: (val) => onChanged(),
      activeColor: AppColors.primaryColor,
      activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.3),
      inactiveTrackColor: Colors.grey[300],
      inactiveThumbColor: Colors.grey[400],
    ),
  ));
}

Widget buildToggleSwitchChip({
  required RxBool value,
  required VoidCallback onChanged,
}) {
  return Obx(() => Transform.scale(
    scale: 0.6, // Adjust scale to reduce size
    child: Switch(
      value: value.value,
      onChanged: (val) => onChanged(),
      activeColor: AppColors.white,
      activeTrackColor: AppColors.primaryColor,
      inactiveTrackColor: Colors.grey[300],
      inactiveThumbColor: Colors.grey[400],
    ),
  ));
}