import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/app_lifecycle_handler.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/services/app_version_checker_service.dart';
import 'package:BlueEra/core/services/firebase_crshanalitics_service.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/theme/themes.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/app_maintannace/app_maintenance_controller.dart';
import 'package:BlueEra/features/app_maintannace/maintenance_screen.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/onboarding/view/splash_screen.dart';
import 'package:BlueEra/widgets/global_message_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/services/home_cache_service.dart';
import 'core/services/notifications/ride_notification_data_model.dart';
import 'features/personal/personal_profile/controller/languge_list_controller.dart';


final AudioPlayer audioPlayer = AudioPlayer();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  ///INIT FIREBASE NOTIFICATION...

  await firebaseInitializeApp();
  if (message.notification != null) {
    await AppNotificationHandler().playCustomSound(message);
  }

  if(message.data["operation"]=='RIDE_ORDER_RECEIVED'){
    NotificationData rideNotification=NotificationData.fromJson(message.data);
    AppNotificationHandler().callShow(orderId: '${rideNotification.metadata?.orderId}',lng: double.parse(rideNotification.deliveryLong.toString()),lat: double.parse(rideNotification.deliveryLat.toString()) );
  }

}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ///SET YOUR API CALLING ENV.
  await projectKeys(environmentType: AppConstants.prod);
  await firebaseInitializeApp();

  // HttpOverrides.global = MyHttpOverrides();
  /// Hive Database
  await Hive.initFlutter();
  final localizationService = LocalizationService();
  await localizationService.init();
  if (Platform.isIOS) {
    clearSecureStorageIfFreshInstall();
  }
  Get.put(AuthController());

  ///GET LOGIN USER DATA...
  await getUserLoginStatus();
  await getUserLoginData();
  await getChannelData();
  await getServiceProviderStatusUtils();
  await getEarnServiceCreatedStatusUtils();

  unFocus();
  Get.put(NavigationHelperController());
  Get.put(GlobalMessageService());
  PackageInfo? packageInfo = await PackageInfo.fromPlatform();
  appVersion = packageInfo.version;

  ///INIT FIREBASE NOTIFICATION...
  await AppNotificationHandler().firebaseNotificationSetup();

  ///APP ORIENTATIONS....
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  /// Initialize Home Feed Cache Service
  await HiveServices.init();

  /// Initialize Home Cache Service
  await HomeCacheService.init();

  /// initializeMappls Map
  await initializeMappls();

  // await OnesignalService().initialize();


  await localizationService.preloadCachedLanguages();

  // Load saved language code (default: 'en')
  final box = Hive.box('translations');
  final savedLangCode = box.get('selectedLanguage', defaultValue: 'en');

  // Load that language’s translations if not already loaded
  // await localizationService.refreshTranslations(savedLangCode);

  await localizationService.loadTranslations(savedLangCode);

  // Register translations with GetX
  Get.addTranslations(localizationService.keys);

  // Set saved locale before app starts
  final locale = Locale(savedLangCode);

  final handler = AppLifecycleHandler();
  WidgetsBinding.instance.addObserver(handler);

  // 🔄 Check if app version changed
  await checkAppVersionAndResetIfNeeded();
  if(kDebugMode)
  {
    await resetLanguageLocalization();

  }
  // await Hive.openBox('translations');
  //
  // // Load saved language from Hive or fallback to English
  // final box = Hive.box('translations');
  // final langCode = box.get('selectedLanguage') ?? 'en';

  // await LocalizationService().loadTranslations(langCode);
  // // Open boxes for language and localization
  await Hive.openBox('languageBox');
  await Hive.openBox('localizationBox');
  Get.put(AppMaintenanceController());

  Get.put(LanguageListController());
  if (kReleaseMode) {
    // firebaseCrashServiceInit();
    runZonedGuarded<Future<void>>(() async {
      WidgetsFlutterBinding.ensureInitialized();

      // Forward Flutter framework errors to Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Forward uncaught async or platform errors
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      runApp(MyApp(
        initialLocale: locale,
      ));
    }, (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    });
  } else {
    runApp(MyApp(
      initialLocale: locale,
    ));
  }
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
  final Locale initialLocale;

  // final LocalizationService localizationService;
  const MyApp({super.key, required this.initialLocale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  final appController = Get.find<AppMaintenanceController>();

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
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppThemes.light,
      initialRoute: null,
      onGenerateRoute: RouteHelper.generateRoute,
      navigatorObservers: [RouteHelper.routeObserver],
      translations: LocalizationService(),
      locale: widget.initialLocale,
      fallbackLocale: const Locale('en'),
      builder: (context, child) {
        return Stack(
          children: [
            // Safe null handling:
            if (child != null) child,
            const GlobalMessage(),
          ],
        );
      },
      home: Obx(() {

        // Still loading (null or loading flag)
        if (appController.isLoading.value || appController.isInMaintenance.value == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // App under maintenance
        if (appController.isInMaintenance.value == true) {
          return const MaintenanceScreen();
        }

        // Normal operation → Go to your normal entry point
        return const SplashScreen(); // or SplashScreen / whatever your entry route is
      }),
    );
  }
}
