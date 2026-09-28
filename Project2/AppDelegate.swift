//
//  AppDelegate.swift
//  Project2
//
//  Created by Ritch Barlatier on 9/20/26.
//

import UIKit
import ParseSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var fallbackWindows: [String: UIWindow] = [:]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Parse
        ParseSwift.initialize(
            applicationId: "wE0fZbe2KzNGkVUQ1jkj0e5UWTXTh6O5hWg0CEvj",
            clientKey: "mPcGNTXRPg4t7WdLltXFIFX2oLeqbXLDzo2W2gqe",
            serverURL: URL(string: "https://parseapi.back4app.com")!
        )
        
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        installRootInterfaceIfNeeded()
    }

    private func installRootInterfaceIfNeeded() {
        for case let windowScene as UIWindowScene in UIApplication.shared.connectedScenes {
            let window = windowScene.windows.first ?? UIWindow(windowScene: windowScene)

            guard !(window.rootViewController is UINavigationController) else {
                continue
            }

            let rootViewController: UIViewController
            if User.current != nil {
                rootViewController = FeedViewController()
            } else {
                rootViewController = LoginViewController()
            }

            window.rootViewController = UINavigationController(
                rootViewController: rootViewController
            )
            window.makeKeyAndVisible()
            fallbackWindows[windowScene.session.persistentIdentifier] = window

            if let sceneDelegate = windowScene.delegate as? SceneDelegate {
                sceneDelegate.window = window
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

