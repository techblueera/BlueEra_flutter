import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/controller/app_background_controller.dart';
import 'package:BlueEra/widgets/app_home_background.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/services/ads/interstitial_ad_manager.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/session_guard.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/app_lifecycle_handler.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/services/app_version_checker_service.dart';
import 'package:BlueEra/core/services/firebase_crshanalitics_service.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/pending_message_drainer.dart';
import 'package:BlueEra/core/theme/themes.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/app_maintannace/app_maintenance_controller.dart';
import 'package:BlueEra/features/app_maintannace/maintenance_screen.dart';
import 'package:BlueEra/features/chat/notification_chat/controller/blueera_notification_controller.dart';
import 'package:BlueEra/features/common/notification/service/notification_cache_service.dart';
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
import 'package:permission_handler/permission_handler.dart';
import 'package:share_handler/share_handler.dart';
import 'core/constants/getx_utils.dart';
import 'core/services/address_cache_service.dart';
import 'core/services/home_cache_service.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'features/chat/auth/controller/call_controller.dart';

// `showIncomingCallLocalNotification` lives in app_notification.dart and is
// already imported via the `app_notification.dart` import above.
import 'features/chat/view/call_screen/audio_calling_handler.dart';
import 'features/chat/view/call_screen/call_activity_main.dart' as call_entry;
import 'features/chat/view/call_screen/rider_call/ride_navigation_floating_overlay.dart';
import 'features/chat/view/widget/chat_video_pip_overlay.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'features/personal/personal_profile/controller/languge_list_controller.dart';

final AudioPlayer audioPlayer = AudioPlayer();

/// Shared media received when app was launched via share intent
SharedMedia? pendingSharedMedia;

/// Resolve a human-readable caller name for incoming-call notifications.
///
/// Order of preference: the push `senderName`, then the caller profile `name`
/// (sender_profile), then their `username`. Falls back to "Incoming Call" so
/// the notification never displays a raw "Unknown".
String resolveCallerName(
    Map<String, dynamic> data, Map<String, dynamic> callerData) {
  for (final candidate in [
    data['senderName'],
    callerData['name'],
    callerData['username'],
  ]) {
    final name = (candidate ?? '').toString().trim();
    if (name.isNotEmpty && name.toLowerCase() != 'unknown') return name;
  }
  return 'Incoming Call';
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The background handler runs in a separate isolate. Platform channels
  // (FlutterCallkitIncoming, FlutterLocalNotificationsPlugin) require Flutter
  // bindings to be initialized in this isolate — without this, the call UI
  // and notifications silently never appear in background/terminated modes.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await firebaseInitializeApp();
  } catch (e, st) {
    logs('[CALL_DEBUG] bg handler firebaseInitializeApp error: $e\n$st');
  }

  // NOTE: Do NOT call getInitialMsg(), onMsgOpen(), or _onTapNotificationFromStatusBar() here.
  // This handler runs in a separate isolate with no UI engine — GetX navigation
  // (Get.to, Get.toNamed) will crash with "contextless navigation" error.
  // Navigation on notification tap is handled by flutter_local_notifications'
  // getNotificationAppLaunchDetails() in firebaseNotificationSetup().

  final operation = (message.data['operation'] ?? '').toString().toLowerCase();
  logs(
      '[CALL_DEBUG] bg handler received → operation= $operation, data=${message.data}');

  // Single-session: account signed in on another device. We are in a separate
  // isolate with no UI engine — cannot navigate. Clear the stored credential
  // directly so the NEXT app launch lands on the login screen. Guard against
  // the self-login echo (re-login on THIS device displaces its own stale
  // session): only clear when the displaced session is our current one, else
  // we would wipe a valid token right after the user logged in.
  if (operation == 'session_displaced' || operation == 'force_logout') {
    if (await SessionGuard.shouldForceLogout(message.data)) {
      try {
        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.authToken, "");
        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.isUserLogin, "false");
        logs('[SESSION] bg handler: $operation for our session → cleared auth token');
      } catch (e) {
        logs('[SESSION] bg handler: failed to clear token: $e');
      }
    } else {
      logs('[SESSION] bg handler: $operation ignored (not our session / self-login echo)');
    }
    return;
  }

  // Handle incoming call in background - show native call UI
  if (operation == 'incoming_call') {
    try {
      final data = message.data;
      final callerImage = (data['senderProfileImage'] ?? '').toString();

      // Defensive parsing: backend may send payload/callerData as a JSON
      // string OR as an already-decoded Map (depending on FCM path). Either
      // was crashing the bg handler before — and a crash here means no UI
      // and no notification in background/terminated modes.
      final payloadRaw = data['payload'];
      Map<String, dynamic> payload = {};
      if (payloadRaw is String && payloadRaw.isNotEmpty) {
        payload = Map<String, dynamic>.from(jsonDecode(payloadRaw));
      } else if (payloadRaw is Map) {
        payload = Map<String, dynamic>.from(payloadRaw);
      }

      final callerRaw = data['callerData'];
      Map<String, dynamic> callerData = {};
      if (callerRaw is String && callerRaw.isNotEmpty) {
        callerData = Map<String, dynamic>.from(jsonDecode(callerRaw));
      } else if (callerRaw is Map) {
        callerData = Map<String, dynamic>.from(callerRaw);
      }

      // Resolve the caller name from the push first, then fall back to the
      // caller profile name. Only use "Incoming Call" when nothing is known —
      // never show a raw "Unknown".
      final callerName = resolveCallerName(data, callerData);

      final callType = (payload['call_type'] ?? 'audio_call').toString();
      final callId = (payload['call_id'] ?? '').toString();
      final roomId = (payload['room_id'] ?? '').toString();
      if (callId.isEmpty || roomId.isEmpty) {
        return;
      }

      final metadata = payload['metadata'];
      final isFareCall =
          metadata is Map && metadata['orderType'] == 'fare-call';

      String designation = 'Incoming Call';
      final accountType = (callerData['account_type'] ?? '').toString();
      if (accountType == 'BUSINESS') {
        var biz = callerData['businessData'];
        if (biz is String && biz.isNotEmpty) {
          try {
            biz = jsonDecode(biz);
          } catch (_) {}
        }
        if (biz is Map) {
          final cat = biz['category_of_business'];
          if (cat != null && cat.toString().isNotEmpty) {
            designation = cat.toString();
          } else {
            final subCat = biz['sub_category_of_business'];
            if (subCat is Map) {
              final name = subCat['name'];
              if (name != null && name.toString().isNotEmpty) {
                designation = name.toString();
              }
            }
          }
        }
      } else {
        final d = (callerData['designation'] ?? '').toString();
        if (d.isNotEmpty) designation = d.toLowerCase();
      }
      if (isFareCall) designation = 'Ride Request';

      final profileImage = (callerData['profile_image'] ?? '').toString();
      final extras = <String, dynamic>{
        'senderId': (data['senderId'] ?? '').toString(),
        'conversationId': (data['conversationId'] ?? '').toString(),
        'callType': callType,
        'callerName': callerName,
        'callerImage': callerImage,
        'callId': callId,
        'roomId': roomId,
        'operation': 'incoming_call',
        if (isFareCall) 'isFareCall': 'true',
        if (isFareCall)
          'fareCallOrderId': (metadata['orderId'] ?? '').toString(),
        if (isFareCall)
          'fareCallRideDetails': jsonEncode(metadata['rideDetails'] ?? {}),
      };

      // Android: use the stateless local-notification full-screen-intent
      // path. flutter_callkit_incoming has known wedged-state bugs after
      // mixed foreground/background call sequences (manifests as 10–20s
      // auto-dismiss). flutter_local_notifications has no native call list
      // to corrupt — every call posts a fresh notification and it works
      // identically across cold-start, background, and alive states.
      //
      // iOS: keep CallKit — Apple requires it for VoIP background calls.
      if (Platform.isAndroid && !isFareCall) {
        await showIncomingCallLocalNotification(
          callId: callId,
          roomId: roomId,
          callerName: callerName,
          callerImage: profileImage.isNotEmpty ? profileImage : callerImage,
          callType: callType,
          extra: extras,
        );
      }
    } catch (e, st) {
      logs('[CALL_DEBUG] bg handler incoming_call error: $e\n$st');
    }
    return; // Don't play sound or show notification for calls
  }
  if (operation == 'fare_ride_incoming_call') {
    try {
      final data = message.data;
      final callerName = (data['senderName'] ?? 'Unknown').toString();

      // Parse payload to extract ride details
      final payloadRaw = data['payload'];
      Map<String, dynamic> payload = {};
      if (payloadRaw is String && payloadRaw.isNotEmpty) {
        payload = Map<String, dynamic>.from(jsonDecode(payloadRaw));
      } else if (payloadRaw is Map) {
        payload = Map<String, dynamic>.from(payloadRaw);
      }

      final metadata = payload['metadata'];

      // Job-aware wording: the backend sends jobLabel/title per job type
      // (Passenger ride / Grocery pickup / Parcel delivery...). Fall back to
      // the legacy "Ride Request" copy for old payloads without them.
      final jobLabel = (payload['jobLabel'] ?? '').toString();
      final backendTitle = (data['title'] ?? '').toString();
      final notifTitle = backendTitle.isNotEmpty
          ? backendTitle
          : (jobLabel.isNotEmpty ? 'New $jobLabel request' : 'Ride Request');

      // Build notification body from ride details
      String notifBody = jobLabel.isNotEmpty
          ? 'New ${jobLabel.toLowerCase()} request from $callerName'
          : 'New ride request from $callerName';
      if (metadata is Map) {
        final rideDetails = metadata['rideDetails'];
        if (rideDetails is Map) {
          final fare = rideDetails['fare'];
          final pickup = rideDetails['pickup'];
          final pickupAddr = pickup is Map ? (pickup['address'] ?? '') : '';
          if (fare != null) {
            notifBody = 'Fare: ₹$fare';
            if (pickupAddr.toString().isNotEmpty) {
              notifBody += ' • Pickup: $pickupAddr';
            }
          }
        } else {
          final rideFare = metadata['ridefare'];
          if (rideFare != null) notifBody = 'Fare: ₹$rideFare';
        }
      }

      // Show a normal local notification with Decline/View actions —
      // this is a ride request, not a phone call.
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveBackgroundNotificationResponse:
            onBackgroundNotificationResponse,
      );

      final notifId = DateTime.now().millisecondsSinceEpoch % 2147483647;

      // Call-style presentation, mirroring showIncomingCallLocalNotification:
      // ringtone channel + CATEGORY_CALL + insistent repeating ring +
      // full-screen intent — a ride request must RING like an incoming call,
      // not ding like a chat message. NEW channel id ('..._ringtone'): the old
      // 'fare_ride_incoming' channel was created with the default notification
      // sound on existing installs, and Android channel settings are immutable
      // after creation — only a fresh channel picks up the ringtone config.
      // timeoutAfter auto-dismisses so the insistent ring can't go on forever
      // (the request is stale by then anyway — customer reassigns/cancels).
      await plugin.show(
        notifId,
        notifTitle,
        notifBody,
        NotificationDetails(
          android: AndroidNotificationDetails(
            // v2 — a deleted/recreated channel id keeps its OLD settings on
            // Android, so devices whose previous channel lacked the ringtone
            // can only be fixed by a fresh id (pre-created with sound in
            // AppNotificationHandler.init; also auto-created here with the
            // same config for the killed-state FCM isolate).
            'fare_ride_incoming_ringtone_v2',
            'Ride Requests',
            channelDescription: 'Incoming ride request alerts',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.call,
            fullScreenIntent: true,
            // visibility: NotificationVisibility.public,
            ongoing: true,
            autoCancel: false,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('hangouts_call'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            icon: '@drawable/ic_stat',
            color: const Color(0xFF0955FA),
            colorized: true,
            audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
            // FLAG_INSISTENT (4): ringtone repeats until the rider acts
            additionalFlags: Int32List.fromList([4]),
            timeoutAfter: 45000,
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'fare_ride_decline',
                'Decline',
                titleColor: Color(0xFFF44336),
                showsUserInterface: false,
                cancelNotification: true,
              ),
              const AndroidNotificationAction(
                'fare_ride_view',
                'View',
                titleColor: Color(0xFF4CAF50),
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: jsonEncode(data),
      );
    } catch (e, st) {
      logs('[CALL_DEBUG] bg handler incoming_call error: $e\n$st');
    }
    return; // Don't play sound or show notification for calls
  }
/*
  if (operation == 'fare_ride_incoming_call') {
    try {
      final data = message.data;
      final callerName = (data['senderName'] ?? 'Unknown').toString();

      // Parse payload to extract ride details for the notification body
      final payloadRaw = data['payload'];
      Map<String, dynamic> payload = {};
      if (payloadRaw is String && payloadRaw.isNotEmpty) {
        payload = Map<String, dynamic>.from(jsonDecode(payloadRaw));
      } else if (payloadRaw is Map) {
        payload = Map<String, dynamic>.from(payloadRaw);
      }

      final metadata = payload['metadata'];
      String notifBody = 'New ride request from $callerName';
      if (metadata is Map) {
        final rideDetails = metadata['rideDetails'];
        if (rideDetails is Map) {
          final fare = rideDetails['fare'];
          final pickup = rideDetails['pickup'];
          final pickupAddr = pickup is Map ? (pickup['address'] ?? '') : '';
          if (fare != null) {
            notifBody = 'Ride fare: ₹$fare';
            if (pickupAddr.toString().isNotEmpty) {
              notifBody += ' • Pickup: $pickupAddr';
            }
          }
        } else {
          final rideFare = metadata['ridefare'];
          if (rideFare != null) notifBody = 'Ride fare: ₹$rideFare';
        }
      }

      // Show a high-priority local notification with full-screen intent
      // so the rider sees the ride request even from background/terminated.
      // This is NOT a call — it's a ride notification, so we use
      // flutter_local_notifications instead of CallKit.
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveBackgroundNotificationResponse:
            onBackgroundNotificationResponse,
      );

      final notifId = DateTime.now().millisecondsSinceEpoch % 2147483647;

      await plugin.show(
        notifId,
        'Ride Request',
        notifBody,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fare_ride_incoming',
            'Ride Requests',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@drawable/ic_stat',
            fullScreenIntent: true,
            category: AndroidNotificationCategory.call,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: jsonEncode(data),
      );
      log('[CALL_DEBUG] bg handler → fare_ride_incoming_call notification shown');
    } catch (e, st) {
      log('[CALL_DEBUG] bg handler fare_ride_incoming_call error: $e\n$st');
    }
    return;
  }
*/

  // Handle missed_call / call_cancelled — caller hung up before receiver answered.
  // Cancel the ringing incoming-call notification so the phone stops ringing.
  if (operation == 'missed_call' || operation == 'call_cancelled') {
    try {
      final data = message.data;
      final payloadRaw = data['payload'];
      Map<String, dynamic> payload = {};
      if (payloadRaw is String && payloadRaw.isNotEmpty) {
        payload = Map<String, dynamic>.from(jsonDecode(payloadRaw));
      } else if (payloadRaw is Map) {
        payload = Map<String, dynamic>.from(payloadRaw);
      }
      final callId = (payload['call_id'] ?? data['callId'] ?? '').toString();
      if (callId.isNotEmpty) {
        await cancelIncomingCallLocalNotification(callId);
        logs('[CALL_DEBUG] bg handler → cancelled incoming notification for callId=$callId (operation=$operation)');
      }
      // Also dismiss CallKit on iOS
      if (Platform.isIOS && callId.isNotEmpty) {
        try {
          await FlutterCallkitIncoming.endCall(callId);
        } catch (_) {}
      }
    } catch (e, st) {
      log('[CALL_DEBUG] bg handler missed_call error: $e\n$st');
    }
    // call_cancelled = caller aborted before answer → no banner.
    // missed_call = receiver never answered → fall through to the generic
    // data-only renderer below so the "Missed call from X" banner is posted.
    if (operation == 'call_cancelled') return;
    // (no return here for missed_call — continue to renderer below)
  }

  // Auto go-live (background / terminated): the cron opened this rider
  // server-side. We're in the bg isolate — no UI engine, no GetX — so we can't
  // flip the toggle here. Persist the OPEN intent so restoreProviderLiveState()
  // re-asserts live (re-PATCH OPEN + restart the location pinger) on the next
  // launch. Non-returning: falls through to render the "You're live!" banner so
  // the tap opens the app. See docs/backend/RIDER_GO_LIVE_GUIDE.md.
  if (operation == 'auto_golive_opened') {
    try {
      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.serviceProviderStatus, 'OPEN');
      logs('[RiderAutoGoLive] bg handler persisted serviceProviderStatus=OPEN');
    } catch (e) {
      logs('[RiderAutoGoLive] bg handler persist OPEN failed: $e');
    }
  }

  try {
    if (message.notification != null) {
      await AppNotificationHandler().playCustomSound(message);
    }

    // Platform-split to prevent duplicate banners for the same FCM message.
    //
    // iOS: when the FCM push carries a `notification` field, iOS (with
    // FirebaseAppDelegateProxyEnabled=true) auto-shows a system banner from
    // notification.title/body. We CANNOT remove that system-owned banner
    // via flutter_local_notifications' cancelAll — it only cancels local
    // notifications, not APNs system banners. If we also call showFromData
    // here, the user sees TWO notifications (system banner + our custom
    // one). So on iOS we let the system banner be authoritative when the
    // notification field is present, and only fall back to showFromData
    // for data-only pushes (no notification field).
    //
    // Android: Firebase's auto-shown notification uses a separate local
    // notification id that cancelAll() DOES remove, so the existing
    // "cancelAll + showFromData" flow yields a single custom-rendered
    // notification with our styling, actions, group key, etc.
    final hasNotificationField = message.notification != null;
    if (Platform.isIOS && hasNotificationField) {
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
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );

    // Small delay to ensure Firebase's auto-shown notification is posted first
    await Future.delayed(const Duration(milliseconds: 200));

    // Cancel ALL notifications (including Firebase's auto-shown ones).
    // Only safe on Android — iOS system banners survive cancelAll.
    if (Platform.isAndroid) {
      await plugin.cancelAll();
    }

    // Use the generic showFromData renderer which reads all backend fields:
    // channelId, channelName, channelImportance, style, imageUrl, groupKey, actions, etc.
    AppNotificationHandler.flutterLocalNotificationsPlugin = plugin;
    await AppNotificationHandler().showFromData(message.data);
  } catch (e, st) {
    log('[CALL_DEBUG] bg handler generic notification error: $e\n$st');
  }
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

  /// Register the FCM background handler IMMEDIATELY after Firebase init.
  /// If this is delayed to _initDeferred (after runApp), a kill before that
  /// phase runs leaves the native FCM service with no Dart callback handle,
  /// so background/terminated-state pushes (incoming calls) are dropped
  /// without reaching Dart at all. Registering here guarantees the handle
  /// is persisted by the plugin on first launch.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  if (kDebugMode) debugPrintKeys();

  if (Platform.isIOS) {
    // Must await: the function wipes the Keychain on a fresh install;
    // if it's fire-and-forget, getUserLoginStatus/getUserLoginData below
    // can read from the Keychain before the wipe completes, or the wipe
    // can race with a subsequent login save on the same launch.
    await clearSecureStorageIfFreshInstall();
  }

  /// Localization, app-background preload, and auth/user data are three
  /// independent pipelines (translations Hive box vs. background-settings
  /// Hive box vs. secure storage) — run them concurrently instead of
  /// serially. Each pipeline keeps its own internal ordering.
  final localizationService = LocalizationService();
  String savedLangCode = 'en';

  /// AuthController must be registered before getUserLoginData() (it sets
  /// imgPath on it). Get.put is synchronous — safe to do up front.
  Get.put(AuthController());

  await Future.wait<void>([
    /// Localization (needs Hive, so runs after Hive.initFlutter)
    () async {
      await localizationService.init();
      final box = Hive.box('translations');
      savedLangCode = box.get('selectedLanguage', defaultValue: 'en');
      await localizationService.loadTranslations(savedLangCode);
      await localizationService.ensureFallbackLoaded();
      Get.addTranslations(localizationService.keys);
    }(),

    /// Reapply the saved app-background colour (if any) before the first frame
    /// so `AppThemes.light` / `AppColors.appBackgroundColor` reflect it from
    /// launch. Hive is already initialised above.
    AppBackgroundController.preload(),

    /// Auth + user data (needed to decide which screen to show)
    () async {
      await Future.wait<void>([
        getUserLoginStatus(),
        getUserLoginData(),
      ]);
    }(),
  ]);

  final locale = Locale(savedLangCode);

  /// Controllers needed at first frame
  unFocus();
  Get.put(NavigationHelperController());
  Get.put(GlobalMessageService());
  Get.put(AppMaintenanceController());

  /// CallController -- must be before runApp for cold-start call handling
  if (!Get.isRegistered<CallController>()) {
    Get.put(CallController(), permanent: true);
  }

  /// Check if app was launched by tapping "Accept" on the Android local
  /// incoming-call notification. There are two ways the Accept tap can
  /// surface to Dart on cold-start:
  ///
  /// 1. **Launch details (primary, terminate state)** —
  ///    `getNotificationAppLaunchDetails()` returns the
  ///    `NotificationResponse` that launched the app, including the action
  ///    button's `actionId` and the notification payload. For an Accept
  ///    action with `showsUserInterface: true`, this is the path Android
  ///    actually uses on terminated state (the bg-isolate handler does NOT
  ///    fire for showsUserInterface: true).
  ///
  /// 2. **Stashed flag (fallback)** — for cases where the bg isolate did
  ///    fire (some Android OEMs / Flutter versions), we keep the secure-
  ///    storage flag as a backup signal.
  ///
  /// Always clear the stashed extras + flag so a stale value can't replay
  /// and so firebaseNotificationSetup()'s tap router can't accidentally
  /// open chat for an incoming-call payload.
  /// All five cold-start call signals below are independent platform-channel
  /// reads; fetch them in parallel (one round-trip of wall-clock instead of
  /// five sequential ones). The pending-extras read-and-clear happens exactly
  /// once here — the two consumer blocks share the single value with the same
  /// consume-order semantics as the old sequential reads.
  Map<String, dynamic>? nativeAction;
  String? acceptedCallId;
  Map<String, dynamic>? pendingCallExtras;
  NotificationAppLaunchDetails? launchDetails;
  dynamic activeCalls;
  await Future.wait<void>([
    readAndClearPendingNativeCallAction().then((v) => nativeAction = v),
    readAndClearPendingIncomingCallAccept().then((v) => acceptedCallId = v),
    readAndClearPendingIncomingCallExtras().then((v) => pendingCallExtras = v),
    () async {
      try {
        launchDetails = await FlutterLocalNotificationsPlugin()
            .getNotificationAppLaunchDetails();
      } catch (e) {
        debugPrint(
            '[COLD_START_CALL] getNotificationAppLaunchDetails error: $e');
      }
    }(),
    () async {
      try {
        activeCalls = await FlutterCallkitIncoming.activeCalls();
      } catch (e, st) {
        debugPrint('[COLD_START_CALL] activeCalls check threw: $e\n$st');
      }
    }(),
  ]);

  // Check for native call notification action (filled-button notification)
  try {
    if (nativeAction != null) {
      final action = nativeAction!['action']?.toString() ?? '';
      final callId = nativeAction!['callId']?.toString() ?? '';
      final roomId = nativeAction!['roomId']?.toString() ?? '';
      final callType = nativeAction!['callType']?.toString() ?? '';
      final isVideo = callType == 'video_call';
      // Consume the shared extras — mirrors the old code, where this block's
      // read-and-clear left nothing for the fallback block below.
      final pending = pendingCallExtras;
      pendingCallExtras = null;

      if (action == 'accept' && callId.isNotEmpty) {
        final callController = getOrPut(() => CallController());
        if (pending != null) callController.initStateFromCallKitExtra(pending);
        CallController.setKilledStateAcceptHandled();
        CallController.markColdStartCall();
        callController.acceptCall(
          callIdParams: callId,
          roomIdParams: roomId,
          isVideoCall: isVideo,
        );
      } else if (action == 'decline' && callId.isNotEmpty) {
        final callController = getOrPut(() => CallController());
        if (pending != null) callController.initStateFromCallKitExtra(pending);
        callController.declineCall();
      }
    }
  } catch (e) {
    debugPrint('[COLD_START_CALL] native pending action check error: $e');
  }

  try {
    final Map<String, dynamic>? pending = pendingCallExtras;

    // Path 1: read the launch details. If the user tapped the Accept action
    // button on the cold-start notification, use its payload directly — the
    // payload already carries callId / roomId / callType / etc.
    Map<String, dynamic>? launchPayload;
    String launchActionId = '';
    try {
      launchActionId = launchDetails?.notificationResponse?.actionId ?? '';
      final raw = launchDetails?.notificationResponse?.payload;
      if (raw != null && raw.isNotEmpty) {
        launchPayload = Map<String, dynamic>.from(jsonDecode(raw));
      }
    } catch (e) {
      debugPrint('[COLD_START_CALL] launch details parse error: $e');
    }

    // Only auto-accept on cold start when the launch was triggered by the
    // explicit Accept action button. A body tap on the call notification
    // also carries `operation == 'incoming_call'` in the payload, but that
    // means the user wants to SEE the IncomingCallScreen (handled by
    // firebaseNotificationSetup), not auto-join the call.
    final launchPayloadIsAccept =
        launchActionId.startsWith('incoming_call_accept_');

    Map<String, dynamic>? acceptExtras;
    if (launchPayloadIsAccept && launchPayload != null) {
      acceptExtras = launchPayload;
    } else if (acceptedCallId != null &&
        acceptedCallId!.isNotEmpty &&
        pending != null &&
        (pending['callId'] ?? '').toString() == acceptedCallId) {
      acceptExtras = pending;
    }

    if (acceptExtras != null &&
        (acceptExtras['callId'] ?? '').toString().isNotEmpty) {
      final callId = (acceptExtras['callId'] ?? '').toString();
      final roomId = (acceptExtras['roomId'] ?? '').toString();
      final isVideo = (acceptExtras['callType'] ?? '') == 'video_call';
      final callController = getOrPut(() => CallController());
      callController.initStateFromCallKitExtra(acceptExtras);
      CallController.setKilledStateAcceptHandled();
      CallController.markColdStartCall();
      callController
          .acceptCall(
            callIdParams: callId,
            roomIdParams: roomId,
            isVideoCall: isVideo,
          )
          .then((ok) => debugPrint(
              '[COLD_START_CALL] local-notif acceptCall returned: $ok'))
          .catchError((e, st) => debugPrint(
              '[COLD_START_CALL] local-notif acceptCall threw: $e\n$st'));
    }
  } catch (e, st) {
    debugPrint('[COLD_START_CALL] local-notif pending check threw: $e\n$st');
  }

  /// Check if app was launched by accepting an incoming call from killed state
  try {
    if (activeCalls is List && activeCalls.isNotEmpty) {
      final first = activeCalls[0];
      final extra = Map<String, dynamic>.from(first['extra'] as Map? ?? {});
      final operation = (extra['operation'] ?? '').toString();
      final accepted = first['accepted'] == true;
      if (operation == 'incoming_call' && accepted) {
        final callController = getOrPut(() => CallController());
        callController.initStateFromCallKitExtra(extra);
        CallController.setKilledStateAcceptHandled();
        CallController.markColdStartCall();
        bool isVideoCalling = extra['callType'] == 'video_call';
        // Fire-and-forget is intentional — runApp must not block. Log the outcome
        // so we can see whether the API accept and CallActivity launch succeed.
        callController
            .acceptCall(
          callIdParams: extra['callId'],
          roomIdParams: extra['roomId'],
          isVideoCall: isVideoCalling,
        )
            .then((ok) {
          debugPrint('[COLD_START_CALL] acceptCall returned: $ok');
        }).catchError((e, st) {
          debugPrint('[COLD_START_CALL] acceptCall threw: $e\n$st');
        });
      } else {
        debugPrint(
            '[COLD_START_CALL] skipping acceptCall — operation=$operation, accepted=$accepted');
      }
    } else {
      debugPrint(
          '[COLD_START_CALL] no active calls at launch — user likely tapped notification body, not Accept action');
    }
  } catch (e, st) {
    debugPrint('[COLD_START_CALL] activeCalls check threw: $e\n$st');
  }

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

// Catches sync errors from the Flutter framework.
// Network-image load failures (e.g. S3 403/404 on deleted/expired business
// logos) are an expected runtime condition, not a bug. Raw NetworkImage /
// DecorationImage / CircleAvatar have no errorBuilder, so each failure dumps a
// full stack trace on every rebuild and floods the console. Drop those here;
// forward every other error to the previous handler (Crashlytics in release,
// the console in debug).
  final FlutterExceptionHandler? defaultOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isNetworkImageError(details)) return;
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } else {
      defaultOnError?.call(details);
    }
  };
  if (kReleaseMode) {
// Catches async errors that aren't handled by Flutter itself
    PlatformDispatcher.instance.onError = (error, stack) {
      if (error is NetworkImageLoadException) return true;
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
// This hides both the status bar and the navigation bar
//   SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

// IMPORTANT: do NOT wrap runApp in runZonedGuarded.
// runZonedGuarded creates a new Zone, and GetX translations registered
// in the root zone via Get.addTranslations(...) are not visible to the
// GetMaterialApp built inside that guarded zone — breaking localization
// in release mode. FlutterError.onError + PlatformDispatcher.instance.onError
// already cover all uncaught errors, so runZonedGuarded is unnecessary.
  runApp(MyApp(initialLocale: locale));
  _initDeferred(localizationService);
}

/// True for expected network-image load failures (broken/expired/forbidden URLs
/// such as S3 403s on missing business logos). These are reported by the
/// painting layer's "image resource service" and are not actionable bugs, so we
/// suppress their console/Crashlytics noise instead of logging a stack trace on
/// every rebuild.
bool _isNetworkImageError(FlutterErrorDetails details) {
  return details.exception is NetworkImageLoadException ||
      details.library == 'image resource service';
}

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 2 -- Deferred: heavy work that doesn't affect the first frame
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _initDeferred(LocalizationService localizationService) async {
  /// Detect a notification launch FIRST (cheap platform-channel call) so we can
  /// decide whether to defer the heavy background batch. Sets the flag the
  /// splash screen reads AND `AppNotificationHandler.pendingDeepLink`.
  /// Publish the in-flight future so SplashScreen can await it instead of
  /// racing it — its 200ms timer used to be able to fire before this check
  /// finished and misroute a notification launch to home.
  /// See docs/backend/notification_fast_open_design.md (Phase 3).
  final launchCheck = AppNotificationHandler.checkNotificationLaunch();
  AppNotificationHandler.notificationLaunchCheckFuture = launchCheck;
  await launchCheck;

  /// When the app is opened by tapping a notification, the target screen
  /// (chat / post / ride …) should render without competing against a full
  /// home boot. We postpone the heavy, first-frame-irrelevant batch
  /// (location, ads SDK, device info, channel data, service-provider status)
  /// until just after the deep-link target has been pushed. On a normal launch
  /// nothing changes — the batch runs inline exactly as before.
  final bool deferForDeepLink =
      AppNotificationHandler.pendingDeepLink != null;

  if (!deferForDeepLink) {
    /// Kick off the location fetch as early as possible on cold start so
    /// lat/lng are populated before the default Discover tab fires its
    /// location-based APIs. Fire-and-forget — must not block the first frame.
    /// The Android 13+ notification permission request is CHAINED after it:
    /// firing both at once makes the two system dialogs race (Android shows
    /// one and silently drops the other).
    unawaited(LocationService.fetchLocation().whenComplete(
        () => unawaited(_requestNotificationPermissionIfNeeded())));

    /// Initialise the Google AdMob SDK + preload the first
    /// interstitial. Fire-and-forget — ads must never block startup; the
    /// end-of-call hook shows whatever is ready by then (and preloads the next).
    unawaited(InterstitialAdManager.instance.initialize());
  }

  /// Essential batch -- Hive/localization boxes + package info that the first
  /// frame and the deep-link target screen depend on. The deferrable network
  /// calls (device info / channel data / service-provider status) only join
  /// this batch on a normal launch; on a deep-link open they move to
  /// [_initBackgroundBatch] below.
  await Future.wait<void>([
    if (!deferForDeepLink) getDeviceInfo(),
    if (!deferForDeepLink) getChannelData(),
    if (!deferForDeepLink) getServiceProviderStatusUtils(),
    HiveServices.init(),
    HomeCacheService.init(),
    AddressCacheService.init(),
    PackageInfo.fromPlatform().then((info) => appVersion = info.version),
    Hive.openBox('languageBox').then((_) {}),
    Hive.openBox('localizationBox').then((_) {}),
  ]);

  /// In-app "BlueEra" notification thread store. Registered before the
  /// notification handler so incoming broadcast/system pushes are captured
  /// into it, and hydrated from Hive here so past notifications show on launch.
  Get.put(BlueEraNotificationController(), permanent: true);

  /// Notification-hub local cache. Registered before the notification handler
  /// so incoming pushes are mirrored into it, and hydrated from Hive here so the
  /// hub list shows instantly (no API wait) when opened this session.
  Get.put(NotificationCacheService(), permanent: true);

  /// Notification setup (depends on Firebase, which is already initialized).
  /// Stays in the essential path so the cold-start deep-link routing fires.
  AppNotificationHandler().firebaseNotificationSetup();

  /// Start the pending-message drainer. Watches connectivity and retries any
  /// chat messages that were saved locally with sendStatus: "pending" — this
  /// covers messages queued while offline and messages left over from a
  /// previous session that was killed before they could be sent.
  unawaited(PendingMessageDrainer.instance.start());

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

  /// Re-apply the saved language's cached translations to GetX after deferred
  /// init so they survive GetMaterialApp initialization inside
  /// runZonedGuarded. Cache-only (no forceRefresh) — the language API is NOT
  /// hit here, in debug or release.
  ///
  /// NOTE: debug builds used to call `resetLanguageLocalization()` here, which
  /// wiped the entire `translations` box (cached strings + the once-per-login
  /// refresh gate) on EVERY launch. That forced a fresh `.../languages/{code}`
  /// download on every debug start. We now use the same cache-first re-apply
  /// in both modes so the API is only hit once after login.
  final savedLang =
      LocalizationService.box.get('selectedLanguage', defaultValue: 'en');
  await localizationService.loadTranslations(savedLang);
  await localizationService.ensureFallbackLoaded();
  Get.clearTranslations();
  Get.addTranslations(localizationService.keys);
  Get.updateLocale(Locale(savedLang));

  /// One-time post-login language refresh. Fires exactly once per login
  /// lifecycle (the gate flag lives in the `translations` box, which is wiped
  /// on logout), and only while logged in. Every other launch serves
  /// translations purely from local cache, so the language API is no longer
  /// called on every app start. Fire-and-forget — must not block startup.
  unawaited(getOrPut(() => LanguageControllerNew()).refreshAfterLoginOnce());

  /// On a notification open, run the deferred heavy batch only after the
  /// first frame has settled (and a short grace period) so it never competes
  /// with rendering the deep-link target. Everything still runs — just later.
  if (deferForDeepLink) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1200), _initBackgroundBatch);
    });
  }
}

/// Android 13+ (API 33) requires runtime POST_NOTIFICATIONS consent, but the
/// app never requested it at startup — pushes (including incoming-call
/// alerts) stayed dead until the user happened to visit a screen that asked.
/// Requested once per launch, AFTER the location flow completes, so the two
/// system dialogs never race. iOS consent is handled in
/// firebaseNotificationSetup() via FirebaseMessaging.requestPermission.
/// A permanently-denied state is left alone — no settings nag on boot.
Future<void> _requestNotificationPermissionIfNeeded() async {
  if (!Platform.isAndroid) return;
  try {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  } catch (e) {
    logs('notification permission request failed: $e');
  }
}

/// Heavy, first-frame-irrelevant startup work. On a normal launch this runs
/// inline inside [_initDeferred]; on a notification open it is postponed via a
/// post-frame callback so the deep-link target renders first.
Future<void> _initBackgroundBatch() async {
  unawaited(LocationService.fetchLocation().whenComplete(
      () => unawaited(_requestNotificationPermissionIfNeeded())));
  unawaited(InterstitialAdManager.instance.initialize());
  await Future.wait<void>([
    getDeviceInfo(),
    getChannelData(),
    getServiceProviderStatusUtils(),
  ]);
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
      // Edge-to-edge is enforced on Android 15+ (target SDK 35+) and is the
      // Flutter 3.29+ default on every version, so the system bars are always
      // transparent with our content drawn behind them. Android 15 IGNORES an
      // opaque `systemNavigationBarColor`, so we set it transparent here to
      // reflect real behavior and keep the look consistent on older versions.
      // `systemNavigationBarContrastEnforced: false` stops the OS from adding a
      // translucent scrim; dark icons keep them legible over light content.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        // Android Black
        statusBarBrightness: Brightness.light,
        // iOS Black
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
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
// App-wide background: the active banner image painted behind EVERY screen.
// Scaffolds go transparent while a banner is active (AppColors.scaffoldBackgroundColor),
// so this shows through app-wide; in colour mode scaffolds stay opaque and this is hidden.
              const AppHomeBackground(),
// Safe null handling:
              if (child != null) child,
              const GlobalMessage(),
// WhatsApp-style call bar at top -- shown when navigating away from call screen
//               const OngoingCallOverlay(),
// Floating mini-map for ride navigation
              const RideNavigationFloatingOverlay(),
// Floating PiP mini-player for video links tapped in chat
              const ChatVideoPipOverlay(),
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

// Still waiting on the very first maintenance check -- show a calm
// branded loader instead of letting SplashScreen flash before we
// potentially swap it for MaintenanceScreen.
          if (appController.isInMaintenance.value == null ||
              appController.isLoading.value) {
            return Scaffold(
              backgroundColor: const Color(0xFFF4F8FF),
              body: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
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
