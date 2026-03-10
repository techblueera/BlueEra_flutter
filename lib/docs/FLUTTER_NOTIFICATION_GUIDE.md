# Flutter Notification Integration Guide

**Backend:** BlueEra Notification Service (data-only FCM)
**Compatibility:** Android 13+ (API 33+), iOS 16+
**Last updated:** 2026-03-10

---

## Architecture

```
Backend (this service)              Flutter App
┌─────────────────────┐        ┌──────────────────────────┐
│ Kafka message       │        │ FirebaseMessaging         │
│   ↓                 │        │   ↓                      │
│ Template engine     │        │ onBackgroundMessage()     │
│   ↓                 │        │   ↓                      │
│ FCM data-only msg   │───────→│ NotificationRenderer     │
│                     │        │   - reads: title, body,   │
│ Controls:           │        │     imageUrl, style,      │
│  - title, body      │        │     channelId, actions    │
│  - image, style     │        │   - builds: local notif   │
│  - channel, group   │        │                          │
│  - action buttons   │        │ Flutter controls:         │
│  - media metadata   │        │  - deep link routing      │
│                     │        │  - button tap → API call  │
│ Zero Flutter changes│        │  - navigation             │
│ for new notif types │        │                          │
└─────────────────────┘        └──────────────────────────┘
```

**Key principle:** Backend decides WHAT to show. Flutter decides WHAT TO DO on tap/action.

---

## Step 1: Dependencies (pubspec.yaml)

```yaml
dependencies:
  firebase_core: ^3.12.1
  firebase_messaging: ^15.2.4
  flutter_local_notifications: ^18.0.1
  http: ^1.3.0

# For image download in BigPictureStyle
dev_dependencies: []
```

Run:
```bash
flutter pub get
```

---

## Step 2: Android Configuration

### android/app/src/main/AndroidManifest.xml

Add inside `<manifest>` (before `<application>`):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.INTERNET" />
```

Add inside `<application>`:

```xml
<!-- Required for data-only FCM in background/killed state -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="default" />

<!-- Keep FCM service alive for data messages -->
<meta-data
    android:name="firebase_messaging_auto_init_enabled"
    android:value="true" />
```

### android/app/build.gradle

Ensure `minSdkVersion` is 21+ and `compileSdkVersion` is 34+:

```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

---

## Step 3: iOS Configuration

### ios/Runner/Info.plist

Add:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>FirebaseMessagingAutoInitEnabled</key>
<true/>
```

### Enable Push Notifications capability

In Xcode: Runner → Signing & Capabilities → + Capability → Push Notifications

---

## Step 4: Notification Service (lib/services/notification_service.dart)

This is the complete, generic renderer. It never needs changes when new notification types are added on the backend.

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

/// Top-level background handler — MUST be top-level function (not class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance.showFromData(message.data);
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  // Callback for notification taps — set this from your app
  void Function(String operation, Map<String, dynamic> payload)? onNotificationTap;
  void Function(String actionId, String operation, Map<String, dynamic> payload)? onActionTap;

  /// Call once from main() before runApp()
  Future<void> init() async {
    // Request permissions (Android 13+ / iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Initialize local notifications plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationResponse,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      showFromData(message.data);
    });

    // Handle notification tap when app was terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage.data);
    }

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageTap(message.data);
    });

    // Log FCM token for debugging
    final token = await _fcm.getToken();
    debugPrint('[FCM] Device token: $token');
  }

  // ─── Build & show notification from backend data payload ───

  Future<void> showFromData(Map<String, dynamic> data) async {
    final title = data['title'] ?? 'BlueEra';
    final body = data['body'] ?? data['message'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    final style = data['style'] ?? 'default';
    final channelId = data['channelId'] ?? 'default';
    final channelName = data['channelName'] ?? 'Notifications';
    final channelImportance = data['channelImportance'] ?? 'default';
    final groupKey = data['groupKey'] ?? '';
    final notificationId = data['notificationId'] ?? '${DateTime.now().millisecondsSinceEpoch}';
    final actionsJson = data['actions'] ?? '[]';

    // Parse action buttons from backend
    List<Map<String, dynamic>> actions = [];
    try {
      actions = List<Map<String, dynamic>>.from(jsonDecode(actionsJson));
    } catch (_) {}

    // Map importance string to Android importance level
    final importance = _mapImportance(channelImportance);

    // Download image for BigPictureStyle if needed
    ByteArrayAndroidBitmap? bigPicture;
    if (style == 'bigPicture' && imageUrl.isNotEmpty) {
      bigPicture = await _downloadImage(imageUrl);
    }

    // Build Android notification details
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: importance == Importance.max || importance == Importance.high
          ? Priority.high
          : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      groupKey: groupKey.isNotEmpty ? groupKey : null,
      styleInformation: _buildStyle(style, body, bigPicture, title),
      actions: actions.take(3).map((a) {
        return AndroidNotificationAction(
          a['id'] ?? '',
          a['text'] ?? '',
          showsUserInterface: true,
        );
      }).toList(),
    );

    // Build iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    // Generate numeric ID from notification ID string
    final numId = notificationId.hashCode.abs() % 2147483647;

    await _local.show(
      numId,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );

    // Show group summary notification on Android (bundles multiple)
    if (groupKey.isNotEmpty && Platform.isAndroid) {
      await _local.show(
        groupKey.hashCode.abs() % 2147483647,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: importance,
            groupKey: groupKey,
            setAsGroupSummary: true,
          ),
        ),
      );
    }
  }

  // ─── Helpers ───

  StyleInformation _buildStyle(
    String style,
    String body,
    ByteArrayAndroidBitmap? bigPicture,
    String title,
  ) {
    switch (style) {
      case 'bigPicture':
        if (bigPicture != null) {
          return BigPictureStyleInformation(
            bigPicture,
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: false,
          );
        }
        return BigTextStyleInformation(body);
      case 'bigText':
        return BigTextStyleInformation(body);
      default:
        return DefaultStyleInformation(true, true);
    }
  }

  Importance _mapImportance(String level) {
    switch (level) {
      case 'max':
        return Importance.max;
      case 'high':
        return Importance.high;
      case 'low':
        return Importance.low;
      case 'min':
        return Importance.min;
      default:
        return Importance.defaultImportance;
    }
  }

  Future<ByteArrayAndroidBitmap?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        return ByteArrayAndroidBitmap(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('[Notification] Failed to download image: $e');
    }
    return null;
  }

  // ─── Tap handling ───

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final data = Map<String, dynamic>.from(jsonDecode(response.payload!));

      // Action button tap
      if (response.actionId.isNotEmpty) {
        onActionTap?.call(
          response.actionId,
          data['operation'] ?? '',
          _parsePayload(data['payload']),
        );
        return;
      }

      // Notification body tap
      _handleMessageTap(data);
    } catch (e) {
      debugPrint('[Notification] Error handling tap: $e');
    }
  }

  void _handleMessageTap(Map<String, dynamic> data) {
    final operation = data['operation'] ?? '';
    final payload = _parsePayload(data['payload']);
    onNotificationTap?.call(operation, payload);
  }

  Map<String, dynamic> _parsePayload(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {}
    }
    return {};
  }
}

/// Background notification response handler — MUST be top-level
@pragma('vm:entry-point')
void _backgroundNotificationResponse(NotificationResponse response) {
  // Background action taps are handled when app resumes via getInitialMessage
}
```

---

## Step 5: Initialize in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.init();

  runApp(const MyApp());
}
```

---

## Step 6: Set up tap handlers (in your root widget or navigation service)

```dart
@override
void initState() {
  super.initState();

  // Notification body tap → navigate
  NotificationService.instance.onNotificationTap = (operation, payload) {
    _handleNavigation(operation, payload);
  };

  // Action button tap → call API or navigate
  NotificationService.instance.onActionTap = (actionId, operation, payload) {
    _handleAction(actionId, operation, payload);
  };
}

void _handleNavigation(String operation, Map<String, dynamic> payload) {
  // Flutter controls all routing — add new routes as needed
  if (operation.contains('message') || operation == 'tagged_in_message') {
    final conversationId = payload['conversation_id'] ?? payload['conversationId'] ?? '';
    Navigator.pushNamed(context, '/chat', arguments: {'conversationId': conversationId});
  } else if (operation.contains('post') || operation == 'tagged_on_post') {
    final postId = payload['post_id'] ?? payload['postId'] ?? '';
    Navigator.pushNamed(context, '/post', arguments: {'postId': postId});
  } else if (operation.contains('reel')) {
    final reelId = payload['reel_id'] ?? payload['reelId'] ?? '';
    Navigator.pushNamed(context, '/reel', arguments: {'reelId': reelId});
  } else if (operation.contains('ride_') || operation.startsWith('RIDE_')) {
    final orderId = payload['orderId'] ?? '';
    Navigator.pushNamed(context, '/ride', arguments: {'orderId': orderId});
  } else if (operation.contains('connection')) {
    final senderId = payload['senderId'] ?? '';
    Navigator.pushNamed(context, '/profile', arguments: {'userId': senderId});
  } else if (operation.contains('channel_')) {
    final channelId = payload['channelId'] ?? '';
    Navigator.pushNamed(context, '/channel', arguments: {'channelId': channelId});
  } else if (operation.contains('interview') || operation.contains('application') || operation.contains('job')) {
    final jobId = payload['jobId'] ?? '';
    Navigator.pushNamed(context, '/job', arguments: {'jobId': jobId});
  } else if (operation == 'incoming_call') {
    Navigator.pushNamed(context, '/call', arguments: payload);
  } else {
    Navigator.pushNamed(context, '/notifications');
  }
}

void _handleAction(String actionId, String operation, Map<String, dynamic> payload) {
  // Flutter controls all button logic — call your APIs here
  if (actionId.startsWith('accept_connection_')) {
    final userId = actionId.replaceFirst('accept_connection_', '');
    // YourApiService.acceptConnection(userId);
  } else if (actionId.startsWith('reply_message_')) {
    final conversationId = payload['conversationId'] ?? '';
    Navigator.pushNamed(context, '/chat', arguments: {'conversationId': conversationId});
  } else if (actionId.startsWith('view_chat_')) {
    final conversationId = actionId.replaceFirst('view_chat_', '');
    Navigator.pushNamed(context, '/chat', arguments: {'conversationId': conversationId});
  } else if (actionId.startsWith('track_ride_')) {
    final orderId = actionId.replaceFirst('track_ride_', '');
    Navigator.pushNamed(context, '/ride/track', arguments: {'orderId': orderId});
  } else if (actionId.startsWith('view_post_')) {
    final postId = actionId.replaceFirst('view_post_', '');
    Navigator.pushNamed(context, '/post', arguments: {'postId': postId});
  }
  // Add more action handlers as needed — these are Flutter-side decisions
}
```

---

## Data Payload Reference

Every FCM message from the backend contains these fields in `message.data`:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `title` | string | Notification title | `"Tech @ Shantanu"` |
| `body` | string | Notification body | `"📷 Photo"` |
| `imageUrl` | string | Image for BigPictureStyle (empty = no image) | `"https://s3...jpg"` |
| `style` | string | `default` \| `bigPicture` \| `bigText` | `"bigPicture"` |
| `channelId` | string | Android notification channel ID | `"messages"` |
| `channelName` | string | Human-readable channel name | `"Messages"` |
| `channelImportance` | string | `max` \| `high` \| `default` \| `low` | `"high"` |
| `groupKey` | string | Android notification grouping key | `"sent_message"` |
| `actions` | JSON string | Array of `{id, text}` action buttons | `"[{\"id\":\"reply_...\",\"text\":\"Reply\"}]"` |
| `operation` | string | Notification type (for routing) | `"sent_message"` |
| `notificationId` | string | Unique notification ID | `"1773130261801"` |
| `timestamp` | string | ISO timestamp | `"2026-03-10T08:11:01Z"` |
| `senderId` | string | Sender user ID | `"68baeac7..."` |
| `senderName` | string | Sender display name | `"Shantanu Dubey"` |
| `senderProfileImage` | string | Sender avatar URL | `"https://s3...png"` |
| `mediaUrl` | string | Rich media URL (image/video/audio/file) | `"https://s3...jpg"` |
| `mediaType` | string | `image` \| `video` \| `audio` \| `file` \| empty | `"image"` |
| `mediaThumbnail` | string | Thumbnail URL for video/audio | `"https://s3...jpg"` |
| `mediaDuration` | string | Duration for audio/video (seconds) | `"45"` |
| `mediaFileName` | string | Original file name | `"document.pdf"` |
| `payload` | JSON string | Full original data from producer | `"{\"conversationId\":\"...\"}"` |

---

## Backend Notification Channels

The backend auto-assigns channels. Flutter auto-creates them on first use:

| Channel ID | Name | Importance | Operations |
|-----------|------|------------|------------|
| `messages` | Messages | high | sent_message, message_reminder, tagged_in_message |
| `incoming_calls` | Incoming Calls | max | incoming_call |
| `missed_calls` | Missed Calls | high | missed_call |
| `rides` | Ride Updates | high | ride_*, RIDE_* |
| `announcements` | Announcements | default | admin_* |
| `channels` | Channels | default | channel_*, follower_* |
| `default` | Notifications | default | everything else |

---

## Adding New Notification Types

**Backend only** — zero Flutter changes needed:

1. Add operation key to `public/notification-templates.json` (push) and/or `public/in-app-notifications.json` (in-app)
2. Producer service sends Kafka message with the new `operation` name
3. Backend automatically resolves: title, body, image, channel, style, buttons
4. Flutter renderer displays it using existing generic logic

**Flutter changes only needed when:**
- Adding a new deep link route (Step 6 `_handleNavigation`)
- Adding a new action button API call (Step 6 `_handleAction`)
- Adding a new notification channel (backend already handles this — Flutter auto-creates)

---

## Troubleshooting

### No notifications showing
- Check FCM token is registered: look for `[FCM] Device token:` in Flutter logs
- Verify `POST_NOTIFICATIONS` permission granted (Android 13+)
- Check `firebase_messaging_auto_init_enabled` in AndroidManifest.xml

### Duplicate notifications
- The backend sends data-only messages (no `notification` block)
- If you see duplicates, check that no other code calls `_local.show()` for FCM messages
- Remove any legacy `onMessage` handlers that create local notifications

### Image not showing in expanded notification
- Backend sets `style: "bigPicture"` and `imageUrl` automatically when media is detected
- The renderer downloads the image and uses `BigPictureStyleInformation`
- If download fails (timeout/network), falls back to `BigTextStyleInformation`

### Background messages not received (iOS)
- Ensure `UIBackgroundModes` includes `remote-notification` in Info.plist
- APNs certificate must be configured in Firebase Console
- `content-available: 1` is set by the backend

### Background messages not received (Android)
- Data-only messages ARE delivered to background handler on Android 13+
- Ensure `firebaseMessagingBackgroundHandler` is a top-level function
- Ensure `@pragma('vm:entry-point')` annotation is present
