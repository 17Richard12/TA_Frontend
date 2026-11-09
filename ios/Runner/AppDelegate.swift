import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let envKey = ProcessInfo.processInfo.environment["MAPS_API_KEY"], !envKey.isEmpty {
      GMSServices.provideAPIKey(envKey)
    } else if let plistKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, !plistKey.isEmpty {
      GMSServices.provideAPIKey(plistKey)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
