import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/share_product_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // askLocationPermission();
    _openNextScreen();
  }

  // Future<void> askLocationPermission() async {
  //   //  await SharedPreferenceUtils.setSecureValue(
  //   //      SharedPreferenceUtils.authToken, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOnsiX2lkIjoiNjg5ZGViN2FhYzhiZWIxMDUzN2UzMTA3IiwiYWNjb3VudF90eXBlIjoiSU5ESVZJRFVBTCIsImNvbnRhY3Rfbm8iOiI3Nzk4ODcxNDY0IiwiYnVzaW5lc3NfaWQiOm51bGx9LCJpYXQiOjE3NTc0MTM3OTQsImV4cCI6MTc3Mjk2NTc5NH0.QzildWHvDot-O_HI0TnEhrEW8qMYZ9_yWApTezS6Tz0");
  //   // await SharedPreferenceUtils.setSecureValue(
  //   //      SharedPreferenceUtils.accountType,"personal");
  //   //
  //   //
  //   // await SharedPreferenceUtils.setSecureValue(
  //   //      SharedPreferenceUtils.isUserLogin,"true");
  // }

  void _openNextScreen() async {
    final tempLoginType = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.accountType);
    accountTypeGlobal = tempLoginType.toString();

    var isLoginStatus = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.isUserLogin);
    if (isLoginStatus == null) isLoginStatus = "false";

    // ✅ Check if app was updated
    // final logoutRequired = await _shouldLogoutAfterUpdate();
    // log('logout required--> $logoutRequired');

    Timer(const Duration(seconds: 2), () async {
      // if (logoutRequired) {
      //   // 🔴 Force user to login again after update
      //   Navigator.of(context).pushNamedAndRemoveUntil(
      //     RouteHelper.getOnboardingSliderScreenRoute(),
      //         (Route<dynamic> route) => false,
      //   );
      //   return;
      // }

      if (isLoginStatus == "true") {
        if (await _initDeepLinks()) {
          // handled deep link
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteHelper.getBottomNavigationBarScreenRoute(),
            arguments: {ApiKeys.initialIndex: 0},
            (Route<dynamic> route) => false,
          );
        }
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteHelper.getOnboardingSliderScreenRoute(),
          (Route<dynamic> route) => false,
        );
      }
    });

    // await OnesignalService().initialize();
  }

  late final AppLinks _appLinks;

  Future<bool> _initDeepLinks() async {
    _appLinks = AppLinks();
    var uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _handleDeepLink(uri);
      return true;
    } else {
      return false;
    }

    // Handle links when app is already running
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint(
        "=====================================Deep link received:========================= $uri");
    try {
      final segments = uri.pathSegments; // e.g., [app, post, 123]
      if (segments.length >= 3 && segments[0] == 'app') {
        final type = segments[1]; // post | video | short | job | product
        final id = segments[2];
        switch (type) {
          case 'post':
            Get.to(() => PostDeatilPage(), arguments: {"postId": id});
            break;
          case 'product':
            Get.to(() => ShareProductScreen(productId: id));
            break;
          case 'profile':
            final type = segments[3];
            final id = segments[2];
            redirectToProfileScreen(
                accountType: type,
                profileId: id,
                screenName: AppConstants.deepLinkScreen);
            break;
          default:
            logs('Unknown deep link type: $type');
        }
      } else {
        debugPrint("SEGMENTS==== ELSE");

        // Fallback: try last segment as id (legacy)
        final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (last.isNotEmpty) {
          Get.to(() => PostDeatilPage(), arguments: {"postId": last});
        }
      }
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Spacer(flex: 3),
          CustomText(
            "🇮🇳  MADE IN INDIA",
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
          ),
          Spacer(flex: 10),
          LocalAssets(
            imagePath: AppIconAssets.blueEraIcon,
            height: SizeConfig.size100,
          ),
          Spacer(flex: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size40),
            child: LocalAssets(
              imagePath: AppImageAssets.splashBgImage,
              height: SizeConfig.size70,
            ),
          ),
          Spacer(flex: 1),
        ],
      ),
    );
  }
}
