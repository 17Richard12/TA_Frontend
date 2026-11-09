import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let envKey = ProcessInfo.processInfo.environment["MAPS_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let rawPlistKey = (Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let plistKey = (rawPlistKey.hasPrefix("$(") || rawPlistKey.isEmpty) ? "" : rawPlistKey
    let resolvedKey = !envKey.isEmpty ? envKey : plistKey

    if !resolvedKey.isEmpty {
      GMSServices.provideAPIKey(resolvedKey)
    } else {
      NSLog("[LungsAssistant] ERROR: Google Maps iOS SDK key (MAPS_API_KEY) is not configured. Set MAPS_API_KEY in ios/Flutter/MapsSecrets.xcconfig or via environment variables.")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
