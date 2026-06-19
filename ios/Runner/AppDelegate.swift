import UIKit
import Flutter
import FirebaseCore
import GoogleMaps
import PushKit
import AVFoundation
import UserNotifications
import flutter_callkit_incoming
import google_mobile_ads
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyD4dbz7eaxd8tFF3tZFJwA4y6KvwozkpdU")
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // Custom native ad layout for the grocery store list. Must be registered
        // AFTER GeneratedPluginRegistrant (which registers the ads plugin) and
        // match NativeAdWidget.factoryId ("groceryAdFactory") on the Dart side.
        let groceryNativeAdFactory = GroceryNativeAdFactory()
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self,
            factoryId: "groceryAdFactory",
            nativeAdFactory: groceryNativeAdFactory)

        // Feed-post-styled native ad for the home feed. Mirrors the Android
        // `feed_native_ad.xml`; matches NativeAdSlot(factoryId: "feedAdFactory").
        let feedNativeAdFactory = FeedNativeAdFactory()
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self,
            factoryId: "feedAdFactory",
            nativeAdFactory: feedNativeAdFactory)

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
    // taps on https://beapp.in/... open Safari even though Associated Domains
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
        // CRITICAL for the ringtone: do NOT let the plugin activate an
        // AVAudioSession while the call is ringing. configureAudioSession()
        // runs setActive(true) with .playAndRecord *before* reportNewIncomingCall,
        // which steals the audio route from CallKit and SILENCES the ringtone
        // (this is why no ringtone — custom or default — ever played in kill mode).
        // The session is instead activated by CallKit's didActivate after the user
        // answers, and flutter_webrtc sets its own .playAndRecord category when
        // media starts (AudioUtils.ensureAudioSessionWithRecording), so in-call
        // audio is unaffected.
        callKitData.audioSessionActive = false
        callKitData.configureAudioSession = false
        // "system_ringtone_default" => the patched flutter_callkit_incoming leaves
        // CXProviderConfiguration.ringtoneSound = nil, so CallKit plays the user's
        // chosen iOS default ringtone (kill-mode VoIP path). Must match IOSParams in
        // lib/features/chat/auth/controller/call_controller.dart.
        callKitData.ringtonePath = "system_ringtone_default"

        // iOS 13+ requires the VoIP push handler to report a new incoming call
        // to CallKit BEFORE calling `completion()`. Use the completion-handler
        // variant so `completion()` runs only after `reportNewIncomingCall` has
        // actually registered the call. Firing `completion()` early (as the
        // non-completion overload did) makes iOS treat the push as mishandled —
        // it terminates the app and, after repeated violations, STOPS delivering
        // VoIP pushes, which shows up as "kill-mode calls don't ring".
        //
        // Guard: if the plugin singleton isn't ready yet, we still must report a
        // call (otherwise iOS penalises the app), so report a placeholder via
        // CallKit-less fallback path is not possible here — at minimum always
        // call completion() so the system isn't left hanging.
        if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
            plugin.showCallkitIncoming(callKitData, fromPushKit: true) {
                completion()
            }
        } else {
            print("[VoIP] CallKit plugin not initialised — cannot report call")
            completion()
        }
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

// MARK: - Grocery Native Ad Factory

/// Builds the custom native ad view for the grocery store list. Mirrors the
/// Android `grocery_native_ad.xml` look: soft teal card, rounded 12 corners, an
/// icon + headline header, a media view and a call-to-action button. The view
/// fills the height the Flutter AdWidget provides (the measured store-card
/// height) so the ad matches a card exactly.
class GroceryNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: NativeAd,
                        customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
        let adView = NativeAdView()
        adView.backgroundColor = .white
        adView.layer.cornerRadius = 12
        adView.layer.borderWidth = 1
        adView.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
        adView.clipsToBounds = true

        // Icon
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 10
        iconView.layer.borderWidth = 1
        iconView.layer.borderColor = UIColor(red: 0.81, green: 0.93, blue: 0.95, alpha: 1.0).cgColor
        iconView.backgroundColor = .white

        // Headline
        let headlineView = UILabel()
        headlineView.font = .boldSystemFont(ofSize: 16)
        headlineView.textColor = UIColor(white: 0.1, alpha: 1.0)
        headlineView.numberOfLines = 1

        // Advertiser
        let advertiserView = UILabel()
        advertiserView.font = .systemFont(ofSize: 12)
        advertiserView.textColor = UIColor(white: 0.48, alpha: 1.0)
        advertiserView.numberOfLines = 1

        // "Ad" badge
        let adBadge = UILabel()
        adBadge.text = " Ad "
        adBadge.font = .boldSystemFont(ofSize: 10)
        adBadge.textColor = .white
        adBadge.backgroundColor = UIColor(red: 0.07, green: 0.86, blue: 0.96, alpha: 1.0)
        adBadge.layer.cornerRadius = 4
        adBadge.clipsToBounds = true
        adBadge.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [headlineView, advertiserView])
        textStack.axis = .vertical
        textStack.spacing = 2

        let headerStack = UIStackView(arrangedSubviews: [iconView, textStack, adBadge])
        headerStack.axis = .horizontal
        headerStack.spacing = 10
        headerStack.alignment = .center

        // Body
        let bodyView = UILabel()
        bodyView.font = .systemFont(ofSize: 13)
        bodyView.textColor = UIColor(white: 0.35, alpha: 1.0)
        bodyView.numberOfLines = 2

        // Media
        let mediaView = MediaView()
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 8
        mediaView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mediaView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        // Keep the media large enough for video (AdMob warns below ~120pt).
        mediaView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true

        // Call to action
        let ctaView = UIButton(type: .system)
        ctaView.titleLabel?.font = .boldSystemFont(ofSize: 14)
        ctaView.setTitleColor(.white, for: .normal)
        ctaView.backgroundColor = UIColor(red: 0.07, green: 0.86, blue: 0.96, alpha: 1.0)
        ctaView.layer.cornerRadius = 8
        // NativeAdView handles the tap — the button must not swallow it.
        ctaView.isUserInteractionEnabled = false
        ctaView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let mainStack = UIStackView(arrangedSubviews: [headerStack, bodyView, mediaView, ctaView])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        adView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: adView.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
        ])

        // Register the asset views with the NativeAdView, then populate them.
        adView.headlineView = headlineView
        adView.iconView = iconView
        adView.advertiserView = advertiserView
        adView.bodyView = bodyView
        adView.mediaView = mediaView
        adView.callToActionView = ctaView

        headlineView.text = nativeAd.headline
        advertiserView.text = nativeAd.advertiser
        advertiserView.isHidden = nativeAd.advertiser == nil
        bodyView.text = nativeAd.body
        bodyView.isHidden = nativeAd.body == nil
        iconView.image = nativeAd.icon?.image
        iconView.isHidden = nativeAd.icon == nil
        ctaView.setTitle(nativeAd.callToAction, for: .normal)
        ctaView.isHidden = nativeAd.callToAction == nil
        mediaView.mediaContent = nativeAd.mediaContent

        // Associate the ad — wires impression/click tracking.
        adView.nativeAd = nativeAd
        return adView
    }
}

// MARK: - Feed Native Ad Factory

/// Builds the feed-post-styled native ad view for the home feed. Mirrors the
/// Android `feed_native_ad.xml`: a circular author-style avatar + name/subtitle
/// header with a "Sponsored" pill, body text, a full-bleed media view and a
/// primary-blue call-to-action, with a hairline bottom divider so it stacks
/// flush with the surrounding post cards. The view fills the height the Flutter
/// AdWidget provides.
class FeedNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: NativeAd,
                        customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
        let primaryBlue = UIColor(red: 0.0, green: 0.525, blue: 1.0, alpha: 1.0)

        // Rounded white card with a 1px greyE5 border, matching FeedCardWidget.
        // Drawing the corners/border on the native view (not via a Flutter clip)
        // keeps all four corners crisp on the platform view.
        let adView = NativeAdView()
        adView.backgroundColor = .white
        adView.layer.cornerRadius = 20
        adView.layer.borderWidth = 1
        adView.layer.borderColor = UIColor(red: 0.898, green: 0.898, blue: 0.898, alpha: 1.0).cgColor
        adView.clipsToBounds = true

        // Circular author-style avatar.
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 21
        iconView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)

        // Headline reads as the post author name.
        let headlineView = UILabel()
        headlineView.font = .boldSystemFont(ofSize: 15)
        headlineView.textColor = UIColor(white: 0.1, alpha: 1.0)
        headlineView.numberOfLines = 1

        // Advertiser reads as the author subtitle.
        let advertiserView = UILabel()
        advertiserView.font = .systemFont(ofSize: 12)
        advertiserView.textColor = UIColor(white: 0.48, alpha: 1.0)
        advertiserView.numberOfLines = 1

        // "Sponsored" pill (in place of the post overflow menu).
        let sponsoredLabel = UILabel()
        sponsoredLabel.text = " Sponsored "
        sponsoredLabel.font = .boldSystemFont(ofSize: 10)
        sponsoredLabel.textColor = UIColor(white: 0.48, alpha: 1.0)
        sponsoredLabel.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0)
        sponsoredLabel.layer.cornerRadius = 6
        sponsoredLabel.clipsToBounds = true
        sponsoredLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [headlineView, advertiserView])
        textStack.axis = .vertical
        textStack.spacing = 2

        let headerStack = UIStackView(arrangedSubviews: [iconView, textStack, sponsoredLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 10
        headerStack.alignment = .center

        // Body — the post text.
        let bodyView = UILabel()
        bodyView.font = .systemFont(ofSize: 14)
        bodyView.textColor = UIColor(white: 0.1, alpha: 1.0)
        bodyView.numberOfLines = 3

        // Media — full-bleed like a post image.
        let mediaView = MediaView()
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mediaView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        mediaView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true

        // Primary-blue CTA.
        let ctaView = UIButton(type: .system)
        ctaView.titleLabel?.font = .boldSystemFont(ofSize: 14)
        ctaView.setTitleColor(.white, for: .normal)
        ctaView.backgroundColor = primaryBlue
        ctaView.layer.cornerRadius = 10
        ctaView.isUserInteractionEnabled = false
        ctaView.heightAnchor.constraint(equalToConstant: 42).isActive = true

        // Header gets side insets like the post author row; media is full-bleed.
        let headerContainer = UIView()
        headerContainer.addSubview(headerStack)
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 15),
            headerStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -12),
            headerStack.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            headerStack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
        ])

        let bodyContainer = UIView()
        bodyContainer.addSubview(bodyView)
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bodyView.leadingAnchor.constraint(equalTo: bodyContainer.leadingAnchor, constant: 15),
            bodyView.trailingAnchor.constraint(equalTo: bodyContainer.trailingAnchor, constant: -12),
            bodyView.topAnchor.constraint(equalTo: bodyContainer.topAnchor),
            bodyView.bottomAnchor.constraint(equalTo: bodyContainer.bottomAnchor),
        ])

        let ctaContainer = UIView()
        ctaContainer.addSubview(ctaView)
        ctaView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ctaView.leadingAnchor.constraint(equalTo: ctaContainer.leadingAnchor, constant: 12),
            ctaView.trailingAnchor.constraint(equalTo: ctaContainer.trailingAnchor, constant: -12),
            ctaView.topAnchor.constraint(equalTo: ctaContainer.topAnchor),
            ctaView.bottomAnchor.constraint(equalTo: ctaContainer.bottomAnchor),
        ])

        let mainStack = UIStackView(arrangedSubviews: [
            headerContainer, bodyContainer, mediaView, ctaContainer,
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)

        adView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: adView.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 42),
            iconView.heightAnchor.constraint(equalToConstant: 42),
        ])

        // Register the asset views with the NativeAdView, then populate them.
        adView.headlineView = headlineView
        adView.iconView = iconView
        adView.advertiserView = advertiserView
        adView.bodyView = bodyView
        adView.mediaView = mediaView
        adView.callToActionView = ctaView

        headlineView.text = nativeAd.headline
        advertiserView.text = nativeAd.advertiser
        advertiserView.isHidden = nativeAd.advertiser == nil
        bodyView.text = nativeAd.body
        bodyView.isHidden = nativeAd.body == nil
        iconView.image = nativeAd.icon?.image
        iconView.isHidden = nativeAd.icon == nil
        ctaView.setTitle(nativeAd.callToAction, for: .normal)
        ctaView.isHidden = nativeAd.callToAction == nil
        mediaView.mediaContent = nativeAd.mediaContent

        // Associate the ad — wires impression/click tracking.
        adView.nativeAd = nativeAd
        return adView
    }
}
