import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/reel/view/channel/channel_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/channel_setting_screen/channel_setting_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/earn_blueera_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory_screen/inventory_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents_screen/my_documents_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/payment_setting_screen.dart';
import 'package:BlueEra/features/subscription/view/subscription_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../../widgets/common_back_app_bar.dart';
import '../booking_enquiries_screen/bookings_enquiries.dart';

class ProfileSettingsScreen extends StatelessWidget {
  final viewProfileController = Get.put(ViewPersonalDetailsController());
  final viewBusinessController = Get.put(ViewBusinessDetailsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: "",
        isLogout: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10, vertical: SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (accountTypeGlobal.toUpperCase() == AppConstants.business)
              Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(SizeConfig.size3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.primaryColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey,
                        backgroundImage: viewBusinessController
                                    .businessProfileDetails?.data?.logo !=
                                null
                            ? NetworkImage(viewBusinessController
                                    .businessProfileDetails?.data?.logo ??
                                "")
                            : null,
                        child: viewBusinessController
                                    .businessProfileDetails?.data?.logo ==
                                null
                            ? CustomText(
                                (viewBusinessController.businessProfileDetails
                                            ?.data?.businessName ??
                                        '')
                                    .trim()
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .take(2)
                                    .join()
                                    .toUpperCase(),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          viewBusinessController
                                  .businessProfileDetails?.data?.businessName ??
                              "",
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.large,
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Row(
                          children: [
                            CustomText(
                              viewBusinessController.businessProfileDetails
                                  ?.data?.natureOfBusiness,
                              fontSize: SizeConfig.size12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.subHeadGray,
                            ),
                            // SizedBox(width: SizeConfig.size4),
                            // SvgPicture.asset(AppIconAssets.profile_copy)
                          ],
                        ),
                        SizedBox(height: SizeConfig.size6),
                        // Row(
                        //   children: [
                        //     CustomText(
                        //         "+91 ${viewProfileController.personalProfileDetails.value.user?.contactNo ?? ""}",
                        //         fontSize: SizeConfig.size12),
                        //     SizedBox(width: SizeConfig.size6),
                        //     Icon(
                        //       Icons.mode_edit_outlined,
                        //       size: SizeConfig.size12,
                        //       color: Color.fromRGBO(78, 80, 106, 1),
                        //     )
                        //   ],
                        // ),
                      ],
                    )
                  ],
                ),
              ),
            if (accountTypeGlobal.toUpperCase() == AppConstants.individual)
              Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(SizeConfig.size3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.primaryColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey,
                        backgroundImage: viewProfileController
                                    .personalProfileDetails
                                    .value
                                    .user
                                    ?.profileImage !=
                                null
                            ? NetworkImage(viewProfileController
                                .personalProfileDetails
                                .value
                                .user!
                                .profileImage!)
                            : null,
                        child: viewProfileController.personalProfileDetails
                                    .value.user?.profileImage ==
                                null
                            ? CustomText(
                                (viewProfileController.personalProfileDetails
                                            .value.user?.name ??
                                        '')
                                    .trim()
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .take(2)
                                    .join()
                                    .toUpperCase(),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          viewProfileController
                                  .personalProfileDetails.value.user?.name ??
                              "",
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.large,
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Row(
                          children: [
                            CustomText(
                              "${viewProfileController.personalProfileDetails.value.user?.profession ?? "OTHERS"}",
                              // "${ProfessionTypeExtension.fromString(viewProfileController.personalProfileDetails.value.user?.profession ?? "OTHERS").displayName}",
                              fontSize: SizeConfig.size12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.subHeadGray,
                            ),
                            // SizedBox(width: SizeConfig.size4),
                            // SvgPicture.asset(AppIconAssets.profile_copy)
                          ],
                        ),
                        SizedBox(height: SizeConfig.size6),
                        // Row(
                        //   children: [
                        //     CustomText(
                        //         "+91 ${viewProfileController.personalProfileDetails.value.user?.contactNo ?? ""}",
                        //         fontSize: SizeConfig.size12),
                        //     SizedBox(width: SizeConfig.size6),
                        //     Icon(
                        //       Icons.mode_edit_outlined,
                        //       size: SizeConfig.size12,
                        //       color: Color.fromRGBO(78, 80, 106, 1),
                        //     )
                        //   ],
                        // ),
                      ],
                    )
                  ],
                ),
              ),
            if (Platform.isAndroid) ...[
              SizedBox(height: SizeConfig.size20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(35, 153, 245, 0.2),
                      side: BorderSide(color: Colors.lightBlueAccent),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: SvgPicture.asset(AppIconAssets.diamond_premium),
                    label: CustomText(
                      "Upgrade Now",
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  SizedBox(
                    height: 36, // Reduce height
                    width: 86, // Optional: Reduce width if needed
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(RouteHelper.getWalletScreenRoute());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(35, 153, 245, 0.2),
                        side: const BorderSide(color: Colors.lightBlueAccent),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        // reduce inner spacing
                        minimumSize: const Size(0, 36), // minimum height
                      ),
                      icon: SvgPicture.asset(
                        AppIconAssets.walletIcon,
                        height: 16, // reduce icon size
                        width: 16,
                      ),
                      label: CustomText(
                        "Wallet",
                        fontSize: 12, // optional: reduce font size
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: SizeConfig.size10),
                        child: CustomText("₹ 0",
                            fontWeight: FontWeight.bold,
                            fontSize: SizeConfig.large),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: SizeConfig.size10),
                        child: CustomText(
                          "Current Balance",
                          fontSize: SizeConfig.size10,
                          color: AppColors.black80,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 12),
              child: Divider(
                height: 30,
                thickness: 1,
                color: Color.fromRGBO(186, 199, 210, 1),
              ),
            ),
            _buildTile(
                AppIconAssets.cards, "My Cards", "View/Share Cards.",
                onTap: () =>  Get.toNamed(RouteHelper.getMoreCardsScreenRoute())),
            if (Platform.isAndroid) ...[
              _buildTile(
                AppIconAssets.earnWithBlueEra,
                "Earn with BlueEra",
                "Learn how to earn with BlueEra",
                onTap: () {
                  Get.to(() => EarnBlueeraScreen());
                  // Get.toNamed(RouteHelper.getearnBlueeraScreenRoute());
                },
              ),
            ],
            if (isBusiness())
            _buildTile(AppIconAssets.inventory, "Inventory",
                "Add/Edit/Delete/Draft Products", onTap: () {
                  Get.toNamed(RouteHelper.getInventoryScreenRoute());
            }),
            _buildTile(AppIconAssets.bookingEnquiries, "Booking & Enquiries",
                "Set/Receive/Earn through your videos",
                onTap: () => Get.to(() => BookingsScreen())),
            if (Platform.isAndroid) ...[
              _buildTile(AppIconAssets.subscription, "Subscription",
                  "Add/Cancel/Subscribe",
                  onTap: () => Get.to(() => SubscriptionScreen())),
              _buildTile(
                  AppIconAssets.payment, "Payment", "Pay & Manage Account",
                  onTap: () => Get.to(() => PaymentSettingScreen())),
            ],
            if (isIndividual())
              _buildTile(AppIconAssets.channelNew, "Channel",
                  "Create/Edit/Delete Channel & Videos", onTap: () {
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
              }),
            // onTap: () => Get.toNamed(RouteHelper.getChannelScreenRoute(),
            //     arguments: {'isOwnChannel': true})),
            _buildTile(
              AppIconAssets.myDocuments,
              "My Documents",
              "Add / Delete your Documents",
              onTap: () => Get.to(() => MyDocumentsScreen()),
            ),
            _buildTile(AppIconAssets.accountSetting, "Account Settings",
                "Language/Delete Account & More",
                onTap: () => Get.to(() => AccountSettingScreen())),
            _buildTile(
              AppIconAssets.helpSupport,
              "Help & Support",
              "FAQ's, Customer Support, Your Queries",
              onTap: () => Get.to(() => HelpAndSupportScreen()),
            ),
            // _buildTile(
            //   AppIconAssets.profile_settings_doc,
            //   "Languages",
            //   onTap: () => Get.to(() => ChangeLanguageScreen()),
            // ),
            SizedBox(height: 20),
            CustomBtn(
              onTap: () async {
                await showCommonDialog(
                    context: context,
                    text:
                        AppLocalizations.of(context)!.areYouSureYouWantToLogout,
                    confirmCallback: () async {
                      await SharedPreferenceUtils.clearPreference();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteHelper.getMobileNumberLoginRoute(),
                          (Route<dynamic> route) => false);
                    },
                    cancelCallback: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    confirmText: AppLocalizations.of(context)!.yes,
                    cancelText: AppLocalizations.of(context)!.no);
              },
              title: "Logout",
              bgColor: Colors.white,
              textColor: AppColors.primaryColor,
              borderColor: AppColors.primaryColor,
            ),
            SizedBox(height: 20),
            CustomBtn(
              onTap: () async {
                await showCommonDialog(
                    context: context,
                    text: "Are you sure you want to delete account?",
                    confirmCallback: () async {
                      // Get.find<AuthController>().deleteUserController();
                      await SharedPreferenceUtils.clearPreference();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteHelper.getMobileNumberLoginRoute(),
                          (Route<dynamic> route) => false);
                    },
                    cancelCallback: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    confirmText: AppLocalizations.of(context)!.yes,
                    cancelText: AppLocalizations.of(context)!.no);
              },
              title: "Delete My Account",
              bgColor: Colors.white,
              textColor: AppColors.red00,
              borderColor: AppColors.red00,
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontFamily: AppConstants.OpenSans,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Get.to(CommonWebView(
                                  urlLink: tncLink,
                                  urlTitle: 'Terms & Conditions',
                                ));
                                // Handle Terms & Conditions tap
                                print('Tapped Terms & Conditions');
                              },
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy.',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontFamily: AppConstants.OpenSans,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Get.to(CommonWebView(
                                  urlLink: privacyLink,
                                  urlTitle: 'Privacy Policy',
                                ));

                                // Handle Privacy Policy tap
                                print('Tapped Privacy Policy');
                              },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Text("Terms & Conditions, Privacy Policy",
                  //     style: TextStyle(fontSize: 12)),
                  // Text("See all policies",
                  //     style: TextStyle(
                  //         fontSize: 12,
                  //         fontWeight: FontWeight.bold,
                  //         color: Colors.blue)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        "v ${appVersion} | ",
                        fontSize: 12,
                      ),
                      LocalAssets(imagePath: AppIconAssets.india_flag),
                      CustomText(
                        " Make in India",
                        fontSize: 12,
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTile(String icon, String title, String subtitle,
      {VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: SvgPicture.asset(icon),
          title: CustomText(
            title,
            fontFamily: "Roboto",
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          subtitle: CustomText(
            subtitle,
            fontSize: 12,
            fontFamily: "Roboto",
            color: const Color.fromRGBO(122, 139, 154, 1),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Color.fromRGBO(122, 139, 154, 1),
          ),
          onTap: onTap,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Divider(
            thickness: 1,
            color: Color.fromRGBO(186, 199, 210, 1),
          ),
        ),
      ],
    );
  }
}
