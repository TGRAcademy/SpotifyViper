//
//  AppDelegate.swift
//  SpotifyViper
//

import UIKit
#if DEBUG
import netfox
#endif

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Debug builds only — netfox swizzles URLSessionConfiguration, so it sees
        // Moya's traffic too. Shake the device (⌃⌘Z in the simulator) to open the
        // request log. Never ship this: it records every request and response.
        #if DEBUG
        NFX.sharedInstance().start()
        #endif
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
