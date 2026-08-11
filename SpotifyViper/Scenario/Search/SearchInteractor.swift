//
//  SearchInteractor.swift
//  SpotifyViper
//
//  Business logic only. It asks the manager for data and does not know a View
//  exists — it reports back through `SearchInteractorToPresenter`.
//

import Foundation

class SearchInteractor: SearchPresenterToInteractor {

    weak var presenter: SearchInteractorToPresenter?
    var manager: SpotifyManagerProtocol?

    // Spotify rejects anything above 10 for an app in Development mode
    // ("Invalid limit", HTTP 400), and defaults to 5 when omitted. An app with
    // extended quota can raise this.
    private let resultLimit = 10

    init(with manager: SpotifyManagerProtocol = SpotifyManager()) {
        self.manager = manager
        self.manager?.searchDelegate = self
    }

    func searchTracks(query: String) {
        manager?.searchTracks(query: query, limit: resultLimit)
    }

    func cancelSearch() {
        manager?.cancelSearch()
    }
}

extension SearchInteractor: SpotifySearchProtocol {

    func didSuccessSearchTracks(query: String, response: Tracks) {
        presenter?.didSuccessSearchTracks(query: query, tracks: response.tracks?.items ?? [])
    }

    func didFailedSearchTracks(query: String, error: SpotifyError) {
        presenter?.didFailedSearchTracks(query: query, error: error)
    }
}
