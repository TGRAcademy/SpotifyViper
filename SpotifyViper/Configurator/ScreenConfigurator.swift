//
//  ScreenConfigurator.swift
//  SpotifyViper
//
//  Wires the layers of a scene together. Assembly lives here rather than in the
//  Router, so the Router is left with nothing but navigation.
//

import UIKit

class ScreenConfigurator {
    public static let shared = ScreenConfigurator()

    func createSearchScreen() -> UIViewController {
        let view: UIViewController & SearchPresenterToView = SearchView()
        let presenter: SearchViewToPresenter & SearchInteractorToPresenter = SearchPresenter()
        let interactor: SearchPresenterToInteractor = SearchInteractor()
        let router: SearchPresenterToRouter = SearchRouter()

        // The View owns the Presenter; the Presenter owns the Interactor and
        // Router. Every reference pointing back up the chain is weak.
        view.presenter = presenter
        presenter.view = view
        presenter.router = router
        presenter.interactor = interactor
        interactor.presenter = presenter

        return view
    }
}
