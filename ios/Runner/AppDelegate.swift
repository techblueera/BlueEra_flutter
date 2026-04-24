import UIKit
import Flutter
import FirebaseCore
import GoogleMaps
import PushKit
import AVFoundation
import UserNotifications
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyD4dbz7eaxd8tFF3tZFJwA4y6KvwozkpdU")
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // Configure AVAudioSession early to prevent error -50 when CallKit queries session properties
        configureAudioSession()

        // Register for VoIP push notifications (required for iOS CallKit)
        let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]

        // Eagerly kick off APNs remote-notification registration every launch.
        // `FirebaseAppDelegateProxyEnabled=YES` already swizzles this, but
        // calling it explicitly is idempotent and guarantees:
        //   1. Re-registration after Apple rotates the APNs device token (a
        //      silent rotation leaves the backend pushing to a dead token,
        //      which is one of the common "terminated state pushes stopped
        //      arriving on iOS" causes).
        //   2. APNs token is ready before the Dart-side `_waitForApnsToken`
        //      polls `FirebaseMessaging.getAPNSToken()`, avoiding the
        //      10s timeout that previously dropped the first-launch token.
        // Notification permission itself is still requested from Dart via
        // `FirebaseMessaging.instance.requestPermission`, so the user is
        // not prompted here — we only tell iOS "we want APNs".
        application.registerForRemoteNotifications()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Universal Links: forward the incoming web URL to the Flutter engine so
    // app_links / go_router / the Navigator can route it. Without this override,
    // taps on https://blueera.ai/... open Safari even though Associated Domains
    // is configured.
    override func application(_ application: UIApplication,
                              continue userActivity: NSUserActivity,
                              restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    // Surface silent APNs registration failures. Without this, a misconfigured
    // provisioning profile / aps-environment mismatch manifests as
    // "terminated-state pushes just don't arrive" with no indication why.
    // Chains to super so Firebase's swizzled handler still runs.
    override func application(_ application: UIApplication,
                              didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APNs] registration failed: \(error.localizedDescription)")
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
            )
        } catch {
            print("Failed to configure AVAudioSession: \(error.localizedDescription)")
        }
    }

    // MARK: - PushKit VoIP Delegate

    /// Called when the device receives a new VoIP push token.
    /// Send this token to your backend so it can send VoIP pushes for incoming calls.
    func pushRegistry(_ registry: PKPushRegistry,
                      didUpdate pushCredentials: PKPushCredentials,
                      for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        print("VoIP Push Token: \(token)")

        // Forward the token to flutter_callkit_incoming plugin
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
    }

    /// Called when a VoIP push notification arrives.
    /// Must report a new incoming call to CallKit immediately (iOS requirement).
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        guard type == .voIP else {
            completion()
            return
        }

        let data = payload.dictionaryPayload
        print("[VoIP] raw payload: \(data)")

        // Backend nests the real call fields (call_id / room_id / call_type / metadata)
        // inside a `payload` field that can arrive as either a JSON string or a dict —
        // same shape the Dart FCM handlers expect (lib/main.dart:95-113 and
        // lib/core/services/app_notification.dart:1437-1449). Decode defensively and
        // prefer nested values, falling back to top-level keys.
        let nestedPayload: [String: Any] = AppDelegate.decodeNested(data["payload"])
        let callerData: [String: Any] = AppDelegate.decodeNested(data["callerData"])

        let businessCallId =
            (nestedPayload["call_id"] as? String).nonEmpty
            ?? (data["callId"] as? String).nonEmpty
            ?? (data["call_id"] as? String).nonEmpty
            ?? ""
        let businessRoomId =
            (nestedPayload["room_id"] as? String).nonEmpty
            ?? (data["roomId"] as? String).nonEmpty
            ?? (data["room_id"] as? String).nonEmpty
            ?? ""
        let conversationId =
            (data["conversationId"] as? String).nonEmpty
            ?? (nestedPayload["conversation_id"] as? String).nonEmpty
            ?? ""
        let senderId =
            (data["senderId"] as? String).nonEmpty
            ?? (nestedPayload["initiated_by"] as? String).nonEmpty
            ?? (callerData["id"] as? String).nonEmpty
            ?? ""
        let callerName =
            (data["senderName"] as? String).nonEmpty
            ?? (callerData["name"] as? String).nonEmpty
            ?? "Unknown"
        let callerImage =
            (data["senderProfileImage"] as? String).nonEmpty
            ?? (callerData["profile_image"] as? String).nonEmpty
            ?? ""
        let callType =
            (nestedPayload["call_type"] as? String).nonEmpty
            ?? (data["callType"] as? String).nonEmpty
            ?? "audio_call"
        let isVideo = callType == "video_call"

        // CallKit session id: prefer the real business call_id so Dart-side
        // setCallConnected / endCall calls (which use extra['callId']) match the
        // entity this handler registered with CallKit.
        let callKitSessionId =
            !businessCallId.isEmpty
                ? businessCallId
                : ((data["notificationId"] as? String).nonEmpty ?? UUID().uuidString)

        // Detect fare-call metadata (mirrors lib/main.dart:119-167)
        var isFareCall = false
        var fareCallOrderId = ""
        var fareCallRideDetailsJson = ""
        if let metadata = nestedPayload["metadata"] as? [String: Any] {
            if (metadata["orderType"] as? String) == "fare-call" {
                isFareCall = true
                fareCallOrderId = (metadata["orderId"] as? String) ?? ""
                if let rideDetails = metadata["rideDetails"],
                   let rideData = try? JSONSerialization.data(withJSONObject: rideDetails, options: []),
                   let rideJson = String(data: rideData, encoding: .utf8) {
                    fareCallRideDetailsJson = rideJson
                }
            }
        }

        // Build extra data for flutter_callkit_incoming — keys must match the
        // canonical shape Dart reads in call_controller.dart:2672 (initStateFromCallKitExtra).
        var extra: [String: Any] = [
            "senderId": senderId,
            "conversationId": conversationId,
            "callType": callType,
            "callerName": callerName,
            "callerImage": callerImage,
            "callId": businessCallId,
            "roomId": businessRoomId,
            "operation": "incoming_call"
        ]
        if isFareCall {
            extra["isFareCall"] = "true"
            extra["fareCallOrderId"] = fareCallOrderId
            extra["fareCallRideDetails"] = fareCallRideDetailsJson
        }

        print("[VoIP] extracted callId=\(businessCallId) roomId=\(businessRoomId) callType=\(callType)")

        // Show native CallKit incoming call screen
        let callKitData = flutter_callkit_incoming.Data(
            id: callKitSessionId,
            nameCaller: callerName,
            handle: "",
            type: isVideo ? 1 : 0
        )
        callKitData.appName = "BlueEra"
        callKitData.avatar = callerImage
        callKitData.duration = 60000
        callKitData.extra = extra as NSDictionary
        callKitData.iconName = "CallKitLogo"
        callKitData.handleType = "generic"
        callKitData.supportsVideo = true
        callKitData.audioSessionMode = "voiceChat"
        callKitData.audioSessionActive = true
        callKitData.ringtonePath = "system_ringtone_default"

        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(
            callKitData,
            fromPushKit: true
        )

        completion()
    }

    /// Called when a VoIP push token is invalidated.
    func pushRegistry(_ registry: PKPushRegistry,
                      didInvalidatePushTokenFor type: PKPushType) {
        print("VoIP Push Token invalidated")
    }

    /// Accepts either a JSON-string or an already-decoded `[String: Any]` and
    /// returns a dictionary. Matches the Dart handler's `payloadRaw is String` /
    /// `payloadRaw is Map` branching in lib/main.dart:95-109.
    fileprivate static func decodeNested(_ raw: Any?) -> [String: Any] {
        if let dict = raw as? [String: Any] { return dict }
        if let str = raw as? String,
           !str.isEmpty,
           let strData = str.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: strData, options: []) as? [String: Any] {
            return parsed
        }
        return [:]
    }
}

private extension Optional where Wrapped == String {
    /// Returns the wrapped string only if non-nil and non-empty — lets callers
    /// chain `??` fallbacks without bleeding through empty strings from the
    /// first source.
    var nonEmpty: String? {
        guard let value = self, !value.isEmpty else { return nil }
        return value
    }
}
