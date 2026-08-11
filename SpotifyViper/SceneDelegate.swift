//
//  SceneDelegate.swift
//  SpotifyViper
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // The Configurator assembles the scene; the scene delegate only decides
        // where it is shown.
        let searchViewController = ScreenConfigurator.shared.createSearchScreen()
        let navigationController = UINavigationController(rootViewController: searchViewController)
        navigationController.navigationBar.isHidden = true

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.overrideUserInterfaceStyle = .dark
        window.makeKeyAndVisible()
        self.window = window
    }
}
