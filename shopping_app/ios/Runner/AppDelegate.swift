import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var isTabBarRegistered = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerNativeTabBarIfNeeded(registry: self)
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerNativeTabBarIfNeeded(registry: engineBridge.pluginRegistry)
  }

  private func registerNativeTabBarIfNeeded(registry: FlutterPluginRegistry) {
    guard !isTabBarRegistered else { return }
    if let registrar = registry.registrar(forPlugin: "NativeTabBarPlugin") {
      let factory = NativeTabBarFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "shopping_app/native-tab-bar")
      isTabBarRegistered = true
    }
  }
}