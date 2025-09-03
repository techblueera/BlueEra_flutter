import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/theme/themes.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/feed/hive_model/video_hive_model.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/reel/view/video/deeplink_video_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/global_message_service.dart';
import 'package:app_links/app_links.dart';
import 'package:camera/camera.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:BlueEra/core/services/workmanager_upload_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'features/common/feed/hive_model/post_hive_model.dart';
import 'core/services/home_cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AuthController());

  ///GET LOGIN USER DATA...
  await getUserLoginStatus();
  await getUserLoginData();
  await getChannelId();
  unFocus();
  Get.put(GlobalMessageService());
  PackageInfo? packageInfo = await PackageInfo.fromPlatform();
  appVersion = packageInfo.version;

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

  /// Hive Tables for posts
  Hive.registerAdapter(PostHiveModelAdapter());
  Hive.registerAdapter(PollAdapter());
  Hive.registerAdapter(PollOptionAdapter());
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox<PostHiveModel>('savedPosts');

  /// Hive Tables for videos/shorts
  Hive.registerAdapter(VideoFeedItemHiveAdapter());
  Hive.registerAdapter(VideoDataHiveAdapter());
  Hive.registerAdapter(AuthorHiveAdapter());
  Hive.registerAdapter(ChannelHiveAdapter());
  Hive.registerAdapter(CategoryHiveAdapter());
  Hive.registerAdapter(TaggedUserHiveAdapter());
  Hive.registerAdapter(LocationHiveAdapter());
  Hive.registerAdapter(SongHiveAdapter());
  Hive.registerAdapter(StatsHiveAdapter());
  await Hive.openBox<VideoFeedItemHive>('savedVideos');

  /// Initialize Home Cache Service
  await HomeCacheService.init();

  /// initializeMappls Map
  await initializeMappls();

 //  /// Initialize Google Mobile Ads
 // if(kDebugMode) {
 //   RequestConfiguration configuration = RequestConfiguration(
 //     testDeviceIds: ["D1B1EDEBD01A314C64BEB76BFB7777ED"],
 //   );
 //   MobileAds.instance.updateRequestConfiguration(configuration);
 // }

  await MobileAds.instance.initialize();

  Get.put(NavigationHelperController());
  cameras = await availableCameras();
  runApp(MyApp());
}

Future<void> initializeMappls() async {
  MapplsAccountManager.setMapSDKKey('7bcc45cef8c687a050402dbd88bdde16');
  MapplsAccountManager.setRestAPIKey('7bcc45cef8c687a050402dbd88bdde16');
  MapplsAccountManager.setAtlasClientId(
      '96dHZVzsAusiRU8_v7__Lme21MTOvTKFvJFyMCpUZQ-DjqUdfP_NqyXMwSnsdCRrb1ftHTtt-plKdAJTzjnhUw==');
  MapplsAccountManager.setAtlasClientSecret(
      'lrFxI-iSEg82Qjz1J8dUxpCA2o1ePCYyYAZjePa8-Us7fJAE_HGPruKUEikFMnPEmMo_PRhKKQi7owz4QDM_5JFVXBbI1mkl');
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

  void _handleDeepLink(Uri uri) {
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
            Get.to(() => DeeplinkVideoScreen(videoId: '$id',));
            
            debugPrint('Deep link -> video id: $id');
            break;
          case 'short':
            // TODO: Navigate to short/reel detail screen with id
            debugPrint('Deep link -> short id: $id');
            break;
          case 'job':
            // TODO: Navigate to job detail screen with id
            debugPrint('Deep link -> job id: $id');
            break;
          case 'profile':
            // TODO: Navigate to profile screen with user id
            //TODO: we have three profile screen first is normal user profile screen and then other are
            // the profile screen of the users whose post are visible on home, they use two different screen to show
            // there profile Visiting_profile_screen.dart and Header_widget.dart both has sharing funtionaity.
            
            debugPrint('Deep link -> profile userId: $id');
            break;
          default:
            debugPrint('Unknown deep link type: $type');
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
    SizeConfig.init(context);
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
