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
import 'core/services/address_cache_service.dart';
import 'core/services/home_cache_service.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'features/chat/auth/controller/call_controller.dart';
import 'features/chat/view/call_screen/audio_calling_handler.dart';
import 'features/chat/view/call_screen/call_activity_main.dart' as call_entry;
import 'features/chat/view/call_screen/widget/call_floating_overlay.dart';
import 'features/chat/view/call_screen/rider_call/ride_navigation_floating_overlay.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'features/personal/personal_profile/controller/languge_list_controller.dart';

final AudioPlayer audioPlayer = AudioPlayer();

/// Shared media received when app was launched via share intent
SharedMedia? pendingSharedMedia;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  ///INIT FIREBASE NOTIFICATION...

  await firebaseInitializeApp();

  // NOTE: Do NOT call getInitialMsg(), onMsgOpen(), or _onTapNotificationFromStatusBar() here.
  // This handler runs in a separate isolate with no UI engine — GetX navigation
  // (Get.to, Get.toNamed) will crash with "contextless navigation" error.
  // Navigation on notification tap is handled by flutter_local_notifications'
  // getNotificationAppLaunchDetails() in firebaseNotificationSetup().

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

    // Detect fare-call metadata from payload
    final metadata = payload['metadata'];
    final isFareCall = metadata != null && metadata['orderType'] == 'fare-call';

    showFlutterCallNotification(
      desiginations: isFareCall
          ? 'Ride Request'
          : () {
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
              return designation.isEmpty
                  ? 'Incoming Call'
                  : designation.toLowerCase();
            }(),
      callSessionId: payload["call_id"],
      callerName: isFareCall
          ? (callerName.isNotEmpty ? callerName : 'Ride Request')
          : callerName,
      callerImage: callerData['profile_image'].isNotEmpty
          ? callerData['profile_image']
          : null,
      callType: callType,
      extra: {
        'senderId': data['senderId'] ?? '',
        'conversationId': data['conversationId'] ?? '',
        'callType': callType,
        'callerName': callerName,
        'callerImage': callerImage,
        'callId': payload["call_id"],
        'roomId': payload["room_id"],
        'operation': 'incoming_call',
        if (isFareCall) 'isFareCall': 'true',
        if (isFareCall) 'fareCallOrderId': metadata['orderId'] ?? '',
        if (isFareCall)
          'fareCallRideDetails': jsonEncode(metadata['rideDetails'] ?? {}),
      },
    );
    // final controller=Get.put(CallController());

    return; // Don't play sound or show notification for calls
  }

  if (message.notification != null) {
    await AppNotificationHandler().playCustomSound(message);
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
    onDidReceiveBackgroundNotificationResponse:
        onBackgroundNotificationResponse,
  );

  // Small delay to ensure Firebase's auto-shown notification is posted first
  await Future.delayed(const Duration(milliseconds: 200));

  // Cancel ALL notifications (including Firebase's auto-shown ones).
  await plugin.cancelAll();

  // Use the generic showFromData renderer which reads all backend fields:
  // channelId, channelName, channelImportance, style, imageUrl, groupKey, actions, etc.
  AppNotificationHandler.flutterLocalNotificationsPlugin = plugin;
  await AppNotificationHandler().showFromData(message.data);
}

// _onTapNotificationFromStatusBar, _openChatWithUser, _handlePostNavigation
// were removed from main.dart — they used GetX navigation which crashes in the
// background isolate. The same logic lives in AppNotificationHandler._onTapNotificationFromStatusBar
// (app_notification.dart) and is triggered via flutter_local_notifications'
// getNotificationAppLaunchDetails() when the app launches from a notification tap.

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
    deviceOsVersionGlobal = iosDeviceInfo.systemVersion;

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

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 1 -- Critical path: only what's needed for the first frame
// ═══════════════════════════════════════════════════════════════════════════

  /// Env config + Firebase + Hive in parallel
  await Future.wait<void>([
    projectKeys(environmentType: AppConstants.prod),
    firebaseInitializeApp(),
    Hive.initFlutter(),
  ]);

  if (kDebugMode) debugPrintKeys();

  if (Platform.isIOS) {
    clearSecureStorageIfFreshInstall();
  }

  /// Localization (needs Hive, so runs after Hive.initFlutter)
  final localizationService = LocalizationService();
  await localizationService.init();

  final box = Hive.box('translations');
  final savedLangCode = box.get('selectedLanguage', defaultValue: 'en');
  await localizationService.loadTranslations(savedLangCode);
  Get.addTranslations(localizationService.keys);
  final locale = Locale(savedLangCode);

  /// Auth + user data (needed to decide which screen to show)
  Get.put(AuthController());
  await getUserLoginStatus();
  await getUserLoginData();

  /// Controllers needed at first frame
  unFocus();
  Get.put(NavigationHelperController());
  Get.put(GlobalMessageService());
  Get.put(AppMaintenanceController());

  /// CallController -- must be before runApp for cold-start call handling
  if (!Get.isRegistered<CallController>()) {
    Get.put(CallController(), permanent: true);
  }

  /// Check if app was launched by accepting an incoming call from killed state
  try {
    final activeCalls = await FlutterCallkitIncoming.activeCalls();
    if (activeCalls is List && activeCalls.isNotEmpty) {
      final extra =
          Map<String, dynamic>.from(activeCalls[0]['extra'] as Map? ?? {});
      final operation = (extra['operation'] ?? '').toString();
      final accepted = activeCalls[0]['accepted'] == true;
      if (operation == 'incoming_call' && accepted) {
        final callController = getOrPut(() => CallController());
        callController.initStateFromCallKitExtra(extra);
        CallController.setKilledStateAcceptHandled();
        CallController.markColdStartCall();
        bool isVideoCalling = extra['callType'] == 'video_call';
        callController.acceptCall(
          callIdParams: extra['callId'],
          roomIdParams: extra['roomId'],
          isVideoCall: isVideoCalling,
        );
      }
    }
  } catch (_) {}

  /// App orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  /// Lifecycle observer
  WidgetsBinding.instance.addObserver(AppLifecycleHandler());

// ═══════════════════════════════════════════════════════════════════════════
// LAUNCH APP -- first frame renders immediately
// ═══════════════════════════════════════════════════════════════════════════

  if (kReleaseMode) {
// Catches sync errors from the Flutter framework
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
// Catches async errors that aren't handled by Flutter itself
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

// IMPORTANT: do NOT wrap runApp in runZonedGuarded.
// runZonedGuarded creates a new Zone, and GetX translations registered
// in the root zone via Get.addTranslations(...) are not visible to the
// GetMaterialApp built inside that guarded zone — breaking localization
// in release mode. FlutterError.onError + PlatformDispatcher.instance.onError
// already cover all uncaught errors, so runZonedGuarded is unnecessary.
  runApp(MyApp(initialLocale: locale));
  _initDeferred(localizationService);
}

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 2 -- Deferred: heavy work that doesn't affect the first frame
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _initDeferred(LocalizationService localizationService) async {
  /// Fire-and-forget parallel batch -- none of these block the UI
  await Future.wait<void>([
    getDeviceInfo(),
    getChannelData(),
    getServiceProviderStatusUtils(),
    getEarnServiceCreatedStatusUtils(),
    HiveServices.init(),
    HomeCacheService.init(),
    AddressCacheService.init(),
    PackageInfo.fromPlatform().then((info) => appVersion = info.version),
    Hive.openBox('languageBox').then((_) {}),
    Hive.openBox('localizationBox').then((_) {}),
  ]);

  /// Check early if app was launched from a notification tap (sets flag for splash screen)
  await AppNotificationHandler.checkNotificationLaunch();

  /// Notification setup (depends on Firebase, which is already initialized)
  AppNotificationHandler().firebaseNotificationSetup();

  /// Share handler -- check if app was launched via share intent
  try {
    pendingSharedMedia =
        await ShareHandlerPlatform.instance.getInitialSharedMedia();
  } catch (_) {}

  /// Overlay listener for floating call window
  _setupOverlayListener();

  /// Language & version checks
  Get.put(LanguageListController());
  await localizationService.preloadCachedLanguages();
  await checkAppVersionAndResetIfNeeded();
  if (kDebugMode) {
    await resetLanguageLocalization();
  } else {
// In release mode, re-apply translations to GetX after deferred init
// to ensure they survive GetMaterialApp initialization inside runZonedGuarded
    final savedLang =
        LocalizationService.box.get('selectedLanguage', defaultValue: 'en');
    await localizationService.loadTranslations(savedLang);
    Get.clearTranslations();
    Get.addTranslations(localizationService.keys);
    Get.updateLocale(Locale(savedLang));
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
      : 'iOS Firebase Key: $firebaseApiKey');
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
        statusBarIconBrightness: Brightness.dark,
        // Android Black
        statusBarBrightness: Brightness.light,
        // iOS Black
        systemNavigationBarColor: Colors.white,
        // Bottom nav bar color
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
// Draggable floating call overlay -- shown when back from call screens
              const CallFloatingOverlay(),
// Floating mini-map for ride navigation
              const RideNavigationFloatingOverlay(),
            ],
          );
        },
        home: Obx(() {
          print(
              "CallController.launchedForCall.value ${CallController.launchedForCall.value}");
// Call accepted from killed state -- show ONLY the call screen
          if (CallController.launchedForCall.value) {
            return const CallActivityRoomScreen();
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
