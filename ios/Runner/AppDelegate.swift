import UIKit
import Flutter
import FirebaseCore
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDdU2Ji6dCQ4Hq0TbLHILxMsdR-M27Ie2g")
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
      // Register NativeAdFactory
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
