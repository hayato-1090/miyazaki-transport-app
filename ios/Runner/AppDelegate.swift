import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps SDK の初期化
    // APIキーは Info.plist の GOOGLE_MAPS_API_KEY エントリから読み込む
    // (ios/Flutter/Debug.xcconfig や Release.xcconfig で設定)
    if let apiKey = Bundle.main.infoDictionary?["GOOGLE_MAPS_API_KEY"] as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
