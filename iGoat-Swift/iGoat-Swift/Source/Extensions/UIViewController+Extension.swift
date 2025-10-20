import UIKit

extension UIViewController {
    class func loadFromNib<T: UIViewController>() -> T {
        return T(nibName: String(describing: self), bundle: nil)
    }
    
    private class func keyRootViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?.rootViewController
        } else {
            return UIApplication.shared.keyWindow?.rootViewController ?? UIApplication.shared.windows.first?.rootViewController
        }
    }

    class func topVisibleViewController(of viewController: UIViewController? = nil) -> UIViewController {
        var viewController = viewController
        if viewController == nil {
            viewController = keyRootViewController() ?? UIApplication.shared.windows.first?.rootViewController
        }

        if let navigationController = viewController as? UINavigationController,
            navigationController.viewControllers.count != 0 {
            return topVisibleViewController(of: navigationController.viewControllers.last)
        }

        else if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return topVisibleViewController(of: selectedViewController)
        }

        else if let presentedController = viewController?.presentedViewController {
            return topVisibleViewController(of: presentedController)
        }

        // As a last resort, return a new UIViewController to avoid force-unwrapping nil
        return viewController ?? UIViewController()
    }
}
