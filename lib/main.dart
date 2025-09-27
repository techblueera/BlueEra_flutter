import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/deeplink_network_resources.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/notifications/one_signal_services.dart';
import 'package:BlueEra/core/theme/themes.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/global_message_service.dart';
import 'package:app_links/app_links.dart';
import 'package:camera/camera.dart';
import 'package:croppy/croppy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:BlueEra/core/services/workmanager_upload_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/services/home_cache_service.dart';
import 'core/services/notifications/firebase_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Get.put(AuthController());
  ///GET LOGIN USER DATA...
  await getUserLoginStatus();
  await getUserLoginData();
  await getChannelId();
  unFocus();
  Get.put(NavigationHelperController());
  Get.put(GlobalMessageService());
  PackageInfo? packageInfo = await PackageInfo.fromPlatform();
  appVersion = packageInfo.version;
  FirebaseNotificationService().init();
  ///SET YOUR API CALLING ENV.
  await projectKeys(environmentType: AppConstants.prod);

  ///APP ORIENTATIONS....
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize workmanager for background tasks
  await WorkmanagerUploadService.initialize();

  /// Hive Database
  await Hive.initFlutter();

  /// Initialize Home Feed Cache Service
  await HiveServices.init();

  /// Initialize Home Cache Service
  await HomeCacheService.init();

  /// initializeMappls Map
  await initializeMappls();

  await MobileAds.instance.initialize();

  await OnesignalService().initialize();

  cameras = await availableCameras();
  runApp(MyApp());
}

Future<void> initializeMappls() async {
  MapplsAccountManager.setMapSDKKey(AppConstants.restApiKey);
  MapplsAccountManager.setRestAPIKey(AppConstants.restApiKey);
  MapplsAccountManager.setAtlasClientId(AppConstants.atlasClientId);
  MapplsAccountManager.setAtlasClientSecret(AppConstants.atlasClientSecret);
}

late List<CameraDescription> cameras;
final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }
  void _initDeepLinks() {
    _appLinks = AppLinks();

    logs("added deepLink");

    // Handle app launched via link (cold start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // Handle links when app is already running (warm)
    _appLinks.uriLinkStream.listen((uri) {
      if (uri.path.isNotEmpty) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async{
    debugPrint(
        "=====================================Deep link received:========================= $uri");
    try {
      final segments = uri.pathSegments; // e.g., [app, post, 123]
      if (segments.length >= 3 && segments[0] == 'app') {
        final type = segments[1]; // post | video | short | job
        final id = segments[2];
        switch (type) {
          case 'post':
            Get.to(() => PostDeatilPage(), arguments: {"postId": id});
            break;
          case 'video':
            // TODO: Navigate to video detail screen with id
             await deepLinkNetworkResources.navigateToVideoDetail(id);
            logs('Deep link -> video id: $id');
            break;
          // case 'short':
          //   // TODO: Navigate to short/reel detail screen with id
          //   logs('Deep link -> short id: $id');
          //   break;
          case 'job':
            // TODO: Navigate to job detail screen with id
            logs('Deep link -> job id: $id');
            break;
          case 'profile':
            // TODO: Navigate to profile screen with user id
            //TODO: we have three profile screen first is normal user profile screen and then other are
            // the profile screen of the users whose post are visible on home, they use two different screen to show
            // there profile Visiting_profile_screen.dart and Header_widget.dart both has sharing funtionaity.
            
            logs('Deep link -> profile userId: $id');
            break;
          default:
            logs('Unknown deep link type: $type');
        }
      } else {
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    // NavigatorService.setNavigatorKey(navKey);
    return GetMaterialApp(
      builder: (context, child) {
        return Stack(
          children: [
            child!, // ← your whole app
            const GlobalMessage(), // ← sits above everything
          ],
        );
      },
      // home: JobsScreen(onHeaderVisibilityChanged: (bool isVisible) {  },),
      // key: NavigatorService.navigatorKey,
      title: AppStrings.appName,
      theme: AppThemes.light,
      initialRoute: RouteHelper.getSplashScreenRoute(),
      onGenerateRoute: RouteHelper.generateRoute,
      navigatorObservers: [RouteHelper.routeObserver],
      debugShowCheckedModeBanner: false,
      supportedLocales: getSupportedLocales(),
      localizationsDelegates: [
        AppLocalizations.delegate,
        CroppyLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
