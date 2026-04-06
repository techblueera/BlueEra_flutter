import UIKit
import Flutter
import FirebaseCore
import GoogleMaps
import PushKit
import AVFoundation
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

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
        let callId = data["callId"] as? String ?? data["notificationId"] as? String ?? UUID().uuidString
        let callerName = data["senderName"] as? String ?? "Unknown"
        let callerImage = data["senderProfileImage"] as? String ?? ""
        let callType = data["callType"] as? String ?? "audio_call"
        let isVideo = callType == "video_call"

        // Build extra data for flutter_callkit_incoming
        let extra: [String: Any] = [
            "senderId": data["senderId"] as? String ?? "",
            "conversationId": data["conversationId"] as? String ?? "",
            "callType": callType,
            "callerName": callerName,
            "callerImage": callerImage,
            "callId": data["callId"] as? String ?? data["call_id"] as? String ?? "",
            "roomId": data["roomId"] as? String ?? data["room_id"] as? String ?? "",
            "operation": "incoming_call"
        ]

        // Show native CallKit incoming call screen
        let callKitData = flutter_callkit_incoming.Data(
            id: callId,
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
}
