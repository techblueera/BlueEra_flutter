import 'dart:async';
import 'dart:convert';
import 'dart:developer';
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
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_handler/share_handler.dart';
import 'core/constants/getx_utils.dart';
import 'core/services/home_cache_service.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/services/notifications/ride_notification_data_model.dart';
import 'features/chat/auth/controller/call_controller.dart';
import 'features/chat/view/call_screen/audio_calling_handler.dart';
import 'features/chat/view/call_screen/call_activity_main.dart' as call_entry;
import 'features/chat/view/call_screen/widget/ongoing_call_overlay.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'features/personal/personal_profile/controller/languge_list_controller.dart';

final AudioPlayer audioPlayer = AudioPlayer();

/// Shared media received when app was launched via share intent
SharedMedia? pendingSharedMedia;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  ///INIT FIREBASE NOTIFICATION...
  await firebaseInitializeApp();

  final operation = (message.data['operation'] ?? '').toString().toLowerCase();

  // Handle incoming call in background - show native call UI
  if (operation == 'incoming_call') {
    final data = message.data;
    final callerName = data['senderName'] ?? 'Unknown';
    final callerImage = data['senderProfileImage'] ?? '';
    Map<String, dynamic> payload = jsonDecode(data['payload']);
    Map<String, dynamic> callerData = jsonDecode(data['callerData']);
    log("payload 71)  ${data}");
    final callType = payload['call_type'];
    showFlutterCallNotification(
      desiginations: () {
        final accountType = callerData['account_type']?.toString() ?? '';

        if (accountType == 'BUSINESS') {
          var biz = callerData['businessData'];

          if (biz is String) {
            biz = jsonDecode(biz);
          }

          if (biz is Map<String, dynamic>) {
            // First try category_of_business
            final cat = biz['category_of_business'];
            if (cat != null && cat.toString().isNotEmpty) {
              return cat.toString();
            }

            // Then try sub_category_of_business.name
            final subCat = biz['sub_category_of_business'];
            if (subCat is Map<String, dynamic>) {
              final name = subCat['name'];
              if (name != null && name.toString().isNotEmpty) {
                return name.toString(); // ✅ ONLY NAME
              }
            }
          }

          return 'Incoming Call';
        }

        final designation = callerData['designation']?.toString() ?? '';
        return designation.isEmpty ? 'Incoming Call' : designation.toLowerCase();
      }(),
      callSessionId: payload["call_id"],
      callerName: callerName,
      callerImage: callerData['profile_image'].isNotEmpty ? callerData['profile_image'] : null,
      callType: callType,
      extra: {
        'senderId': data['senderId'] ?? '',
        'conversationId': data['conversationId'] ?? '',
        'callType': callType,
        'callerName': callerName,
        'callerImage': callerImage,
        'callId':payload["call_id"],
        'roomId':payload["room_id"],
        'operation': 'incoming_call',
      },
    );
    // final controller=Get.put(CallController());

    return; // Don't play sound or show notification for calls
  }

  if (message.notification != null) {
    await AppNotificationHandler().playCustomSound(message);
  }

  if (operation == 'ride_order_received') {
    NotificationData rideNotification = NotificationData.fromJson(message.data);
    AppNotificationHandler().callShow(
        orderId: '${rideNotification.metadata?.orderId}',
        lng: double.parse(rideNotification.deliveryLong.toString()),
        lat: double.parse(rideNotification.deliveryLat.toString()));
    return;
  }

  // For ALL other notifications in background: use the generic data-only renderer.
  // Backend sends data-only FCM messages, so we render them ourselves with
  // action buttons, BigPictureStyle, grouping, etc.
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
  );

  // Small delay to ensure Firebase's auto-shown notification is posted first
  await Future.delayed(const Duration(milliseconds: 500));

  // Cancel ALL notifications (including Firebase's auto-shown ones).
  await plugin.cancelAll();

  // Use the generic showFromData renderer which reads all backend fields:
  // channelId, channelName, channelImportance, style, imageUrl, groupKey, actions, etc.
  AppNotificationHandler.flutterLocalNotificationsPlugin = plugin;
  await AppNotificationHandler().showFromData(message.data);
}

getDeviceInfo() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    // Get the major OS version number (e.g., "14", "15")
    deviceOsVersionGlobal = androidInfo.version.release;
    print('Android Release Version: $deviceOsVersionGlobal');
  } else if (Platform.isIOS) {
    IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
    // Get the major OS version number (e.g., "14", "15")
    deviceOsVersionGlobal= iosDeviceInfo.systemVersion;

    print('iosDeviceInfo Release Version: $deviceOsVersionGlobal');
  }
}

/// Listen for messages from the floating overlay window (hangup / expand actions)
void _setupOverlayListener() {
  if (!Platform.isAndroid) return;
  FlutterOverlayWindow.overlayListener.listen((data) {
    if (data is Map) {
      final action = data['action'];
      if (!Get.isRegistered<CallController>()) return;
      final callController = Get.find<CallController>();

      if (action == 'hangup') {
        callController.endCall();
      } else if (action == 'expand') {
        // Bring app to foreground and navigate to active call screen
        if (Get.currentRoute != '/CallRoomScreen') {
          Get.toNamed('/CallRoomScreen');
        }
      }
    }
  });
}

/// Entry point for Android CallActivity (separate Flutter engine).
/// Must be in main.dart so the engine can resolve it from the default library.
@pragma('vm:entry-point')
void callMain() => call_entry.callMainImpl();

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  /// Check for shared media early (before heavy init) for instant share screen
  try {
    pendingSharedMedia = await ShareHandlerPlatform.instance.getInitialSharedMedia();
  } catch (_) {}

  ///SET YOUR API CALLING ENV.
  await projectKeys(environmentType: AppConstants.prod);

  if (kDebugMode) {
    debugPrintKeys();
  }

  await firebaseInitializeApp();
  await getDeviceInfo();
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

  /// Register CallController early so it's available for push notification handlers
  /// (incoming call notifications can arrive before user navigates to chat)
  if (!Get.isRegistered<CallController>()) {
    Get.put(CallController(), permanent: true);
  }

  /// Listen for messages from the floating overlay (hangup / expand)
  _setupOverlayListener();

  /// Check if app was launched by accepting an incoming call from killed state.
  /// Must run BEFORE runApp() so launchedForCall is true at first build.
  try {

    final activeCalls = await FlutterCallkitIncoming.activeCalls();
    if (activeCalls is List && activeCalls.isNotEmpty) {
      final extra = Map<String, dynamic>.from(activeCalls[0]['extra'] as Map? ?? {});
      final operation = (extra['operation'] ?? '').toString();
      final accepted = activeCalls[0]['accepted'] == true;
      if (operation == 'incoming_call' && accepted) {
        final callController = getOrPut(() => CallController());
        // Initialize call state from notification extras (sets remoteUserId, callType, etc.)
        callController.initStateFromCallKitExtra(extra);
        // Mark as handled so CallKit listener doesn't fire acceptCall again
        CallController.setKilledStateAcceptHandled();
        // Mark as cold-start call so UI shows CallRoomScreen and navigates
        // to home when call ends
        CallController.markColdStartCall();
        bool isVideoCalling=extra['callType']=='video_call';
        callController.acceptCall(callIdParams: extra['callId'], roomIdParams: extra['roomId'],isVideoCall: isVideoCalling);
         // FlutterCallkitIncoming.endCall(activeCalls[0]['id']);
      }

    }

  } catch (_) {}
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
  if (kDebugMode) {
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

void debugPrintKeys() {
  print('--- API KEYS DEBUG ---');
  print('Selected Base URL: $baseUrl');
  print('Razorpay Key: $razorpayKey');
  print('Chat Socket URL: $chatSocketUrl');
  print('Live Track Socket: $liveTrackSocket');
  print('Google Map Key: $googleMapKey');
  print('Gemini API Key: $geminiApiKey');
  print('Firebase Project ID: $projectFireBaseId');
  print(Platform.isAndroid
      ? 'Android App ID: $firebaseAppId'
      : 'iOS App ID: $firebaseAppId');
  print(Platform.isAndroid
      ? 'Android Firebase Key: $firebaseApiKey'
      : 'iOS Firebase Key: $firebaseApiKey'
  );
  print('Messaging Sender ID: $messagingSenderId');
  print('----------------------');
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android Black
        statusBarBrightness: Brightness.light, // iOS Black
        systemNavigationBarColor: Colors.white,   // Bottom nav bar color
        systemNavigationBarIconBrightness: Brightness.dark, // Bottom nav icons
      ),
      child: GetMaterialApp(
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
              // WhatsApp-style ongoing call overlay — shown above app bar
              const OngoingCallOverlay(),
            ],
          );
        },
        home: Obx(() {
          print("CallController.launchedForCall.value ${CallController.launchedForCall.value}");
          // Call accepted from killed state — show ONLY the call screen
          if (CallController.launchedForCall.value) {
            return const CallRoomScreen();
          }

          // Still loading (null or loading flag)
          if (appController.isLoading.value ||
              appController.isInMaintenance.value == null) {
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
      ),
    );
  }
}
