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
        GMSServices.provideAPIKey("AIzaSyD4dbz7eaxd8tFF3tZFJwA4y6KvwozkpdU")
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)
        // Register NativeAdFactory
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
