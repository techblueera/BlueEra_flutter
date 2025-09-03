  import 'dart:async';

  import 'package:BlueEra/core/api/apiService/api_keys.dart';
  import 'package:BlueEra/core/constants/app_colors.dart';
  import 'package:BlueEra/core/constants/app_icon_assets.dart';
  import 'package:BlueEra/core/constants/app_image_assets.dart';
  import 'package:BlueEra/core/constants/shared_preference_utils.dart';
  import 'package:BlueEra/core/constants/size_config.dart';
  import 'package:BlueEra/core/routes/route_helper.dart';
  import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
  import 'package:BlueEra/widgets/custom_text_cm.dart';
  import 'package:BlueEra/widgets/local_assets.dart';
  import 'package:app_links/app_links.dart';
  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
  import '../../../../core/services/notifications/one_signal_services.dart';

  class SplashScreen extends StatefulWidget {
    const SplashScreen({super.key});

    @override
    State<SplashScreen> createState() => _SplashScreenState();
  }

  class _SplashScreenState extends State<SplashScreen> {
    @override
    void initState() {
      super.initState();
      _openNextScreen();
    }

    void _openNextScreen() async {
      final tempLoginType = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.accountType);
      accountTypeGlobal = tempLoginType.toString();

      dynamic isLoginStatus = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.isUserLogin);
      if (isLoginStatus == null) isLoginStatus = "false";

      // ✅ Check if app was updated
      // final logoutRequired = await _shouldLogoutAfterUpdate();

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

      await OnesignalService().initialize();
    }

    Future<bool> _shouldLogoutAfterUpdate() async {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final lastVersion = await SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.lastVersion);

      if (lastVersion != null && lastVersion.isNotEmpty && _isVersionChanged(lastVersion, currentVersion)) {
        // 🔴 App updated → logout
        await SharedPreferenceUtils.clearPreference();

        // ✅ Save new version after clearing
        await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.lastVersion, currentVersion);
        return true;
      }

      // First launch OR same version → just update the stored version
      await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.lastVersion, currentVersion);
      return false;
    }

    bool _isVersionChanged(String oldV, String newV) {
      final oldParts = oldV.split('.').map(int.parse).toList();
      final newParts = newV.split('.').map(int.parse).toList();

      // normalize length (e.g., 1.2 vs 1.2.0)
      while (oldParts.length < 3) oldParts.add(0);
      while (newParts.length < 3) newParts.add(0);

      for (int i = 0; i < 3; i++) {
        if (newParts[i] > oldParts[i]) return true; // version increased
        if (newParts[i] < oldParts[i]) return false; // shouldn’t happen (downgrade)
      }
      return false; // equal
    }

  late final AppLinks _appLinks;

    Future<bool> _initDeepLinks()async {
      _appLinks = AppLinks();


    //  _appLinks.uriLinkStream.listen((uri) {
    //     if (uri.data != null) _handleDeepLink(uri);
    //   });
      // _appLinks.getInitialLink();
      // _appLinks.getInitialLinkString();
      // Handle app launched via link
     var uri=await _appLinks.getInitialLink();
        if (uri != null) {_handleDeepLink(uri);return true;}else{
          return false;
        }

      // Handle links when app is already running

    }

    void _handleDeepLink(Uri uri) {
      debugPrint(
          "=====================================Deep link received:========================= $uri");
      try {
        print("iiiiidddddddddddddddddddddddddd  " +
            (uri.toString().split("/").last));

        Get.to(()=>PostDeatilPage(),
            arguments: {"postId": (uri.toString().split("/").last)});
      } on Exception catch (e) {
        print(e.toString());
      }
      // if (uri.path.contains("BlueEraPostLink")) {
      //   navKey.currentState?.pushNamed(RouteHelper.getPostScreen(), arguments: uri.queryParameters);
      // } else if (uri.path.contains("BlueEraReferLink")) {
      //   navKey.currentState?.pushNamed(RouteHelper.getReferScreen(), arguments: uri.queryParameters);
      // }
    }



    @override
    Widget build(BuildContext context) {
      return FutureBuilder(
        future: Future.wait([
          Future.value(OneSignal.User.pushSubscription.optedIn),
          Future.value(OneSignal.User.pushSubscription.id),
          Future.value(OneSignal.User.pushSubscription.token),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();


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
        },
      );
    }
  }
