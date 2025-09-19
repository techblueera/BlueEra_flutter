import UIKit
import Flutter
import google_mobile_ads
import FirebaseCore



@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
      // Register NativeAdFactory
        let factory = NativeAdFactoryExample()
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
          self,
          factoryId: "listTile",
          nativeAdFactory: factory
        )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
