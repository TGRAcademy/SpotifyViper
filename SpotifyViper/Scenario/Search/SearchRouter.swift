//
//  SearchRouter.swift
//  SpotifyViper
//
//  Navigation out of this scene, and nothing else. Assembly of the module lives
//  in ScreenConfigurator.
//

import UIKit

class SearchRouter: SearchPresenterToRouter {

    func navigateToSpotify(url: URL, from view: SearchPresenterToView?) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
