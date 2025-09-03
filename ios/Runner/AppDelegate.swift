import UIKit
import Flutter
import google_mobile_ads


@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
