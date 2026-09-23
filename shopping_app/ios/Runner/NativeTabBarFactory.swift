import Flutter
import UIKit

class NativeTabBarFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NativeTabBarPlatformView(frame: frame, viewId: viewId, messenger: messenger, args: args)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

final class NativeTabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
    private let container = UIView()
    private let tabBar = UITabBar()
    private let channel: FlutterMethodChannel

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        channel = FlutterMethodChannel(
            name: "shopping_app/native-tab-bar_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        container.frame = frame
        container.backgroundColor = .clear
        container.overrideUserInterfaceStyle = .light

        tabBar.overrideUserInterfaceStyle = .light
        tabBar.tintColor = UIColor(red: 27/255, green: 55/255, blue: 80/255, alpha: 1)
        tabBar.delegate = self
        tabBar.items = [
            makeItem("Shop", "storefront", "storefront.fill", 0),
            makeItem("Explore", "safari", "safari.fill", 1),
            makeItem("Cart", "cart", "cart.fill", 2),
            makeItem("Account", "person", "person.fill", 3),
        ]
        tabBar.frame = container.bounds
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(tabBar)

        let dict = args as? [String: Any]
        select((dict?["selectedIndex"] as? NSNumber)?.intValue ?? 0)
        setCartCount((dict?["cartCount"] as? NSNumber)?.intValue ?? 0)

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            let a = call.arguments as? [String: Any]
            switch call.method {
            case "setTab":
                if let i = (a?["index"] as? NSNumber)?.intValue { self.select(i); result(nil) }
                else { result(FlutterError(code: "INVALID_ARGS", message: "index missing", details: nil)) }
            case "updateCartCount":
                if let c = (a?["count"] as? NSNumber)?.intValue { self.setCartCount(c); result(nil) }
                else { result(FlutterError(code: "INVALID_ARGS", message: "count missing", details: nil)) }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func makeItem(_ title: String, _ symbol: String, _ filled: String, _ tag: Int) -> UITabBarItem {
        let item = UITabBarItem(
            title: title,
            image: UIImage(systemName: symbol),
            selectedImage: UIImage(systemName: filled)
        )
        item.tag = tag
        return item
    }

    private func select(_ index: Int) {
        guard let items = tabBar.items, items.indices.contains(index) else { return }
        tabBar.selectedItem = items[index]
    }

    private func setCartCount(_ count: Int) {
        tabBar.items?[2].badgeValue = count > 0 ? "\(count)" : nil
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        channel.invokeMethod("onTabSelected", arguments: ["index": item.tag])
    }

    func view() -> UIView { container }
}