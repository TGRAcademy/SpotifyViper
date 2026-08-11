//
//  SearchProtocol.swift
//  SpotifyViper
//
//  Every contract between the layers of this scene, in one file. If a layer
//  needs something from another layer, it is written here or it does not happen.
//

import Foundation

protocol SearchPresenterToView: AnyObject {
    var presenter: SearchViewToPresenter? { get set }
    func reloadTableView()
    func showState(_ state: SearchState)
}

protocol SearchViewToPresenter: AnyObject {
    var view: SearchPresenterToView? { get set }
    var interactor: SearchPresenterToInteractor? { get set }
    var router: SearchPresenterToRouter? { get set }
    func viewDidLoad()
    func searchTextDidChange(_ text: String)
    func searchButtonClicked(with text: String)
    func didSelectTrack(at index: Int)
    func getTracks() -> [TrackViewModel]?
}

protocol SearchPresenterToInteractor: AnyObject {
    var presenter: SearchInteractorToPresenter? { get set }
    func searchTracks(query: String)
    func cancelSearch()
}

protocol SearchInteractorToPresenter: AnyObject {
    func didSuccessSearchTracks(query: String, tracks: [Track])
    func didFailedSearchTracks(query: String, error: SpotifyError)
}

protocol SearchPresenterToRouter: AnyObject {
    func navigateToSpotify(url: URL, from view: SearchPresenterToView?)
}
