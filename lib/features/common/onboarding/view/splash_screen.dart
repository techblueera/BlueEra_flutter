  import 'dart:async';
import 'dart:io';

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
import 'package:share_handler/share_handler.dart';

  class SplashScreen extends StatefulWidget {
    const SplashScreen({super.key});

    @override
    State<SplashScreen> createState() => _SplashScreenState();
  }

  class _SplashScreenState extends State<SplashScreen> {


    @override
    void initState() {
      super.initState();


      askLocationPermission();
      _openNextScreen();
    }


    Future<void> askLocationPermission() async {
     //  await SharedPreferenceUtils.setSecureValue(
     //      SharedPreferenceUtils.authToken, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOnsiX2lkIjoiNjg5ZGViN2FhYzhiZWIxMDUzN2UzMTA3IiwiYWNjb3VudF90eXBlIjoiSU5ESVZJRFVBTCIsImNvbnRhY3Rfbm8iOiI3Nzk4ODcxNDY0IiwiYnVzaW5lc3NfaWQiOm51bGx9LCJpYXQiOjE3NTc0MTM3OTQsImV4cCI6MTc3Mjk2NTc5NH0.QzildWHvDot-O_HI0TnEhrEW8qMYZ9_yWApTezS6Tz0");
     // await SharedPreferenceUtils.setSecureValue(
     //      SharedPreferenceUtils.accountType,"personal");
     //
     //
     // await SharedPreferenceUtils.setSecureValue(
     //      SharedPreferenceUtils.isUserLogin,"true");
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
        Get.to(()=>PostDeatilPage(),
            arguments: {"postId": (uri.toString().split("/").last)});
      } on Exception catch (e) {
        print(e.toString());
      }

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
  class ChatScreen extends StatelessWidget {
    final String? sharedText;
    List<SharedAttachment?>? sharedFiles=[];
    // final List<SharedMediaFile>? sharedFiles;

     ChatScreen({Key? key, this.sharedText, this.sharedFiles})
        : super(key: key);

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat Screen')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sharedText != null)
                Text("📩 Shared Text:\n$sharedText",
                    style: const TextStyle(fontSize: 16)),
              if (sharedFiles != null && sharedFiles!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sharedFiles!
                      .map(
                        (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.file(
                        File(f?.path??""),
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      .toList(),
                ),
              const SizedBox(height: 20),
              const Text(
                "Now you can send this to your contacts 💬",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
  }