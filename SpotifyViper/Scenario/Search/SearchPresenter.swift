//
//  SearchPresenter.swift
//  SpotifyViper
//
//  Debounce, state and formatting. Deliberately imports Foundation only — if
//  this file ever needs UIKit, something has been put in the wrong layer.
//

import Foundation

class SearchPresenter: SearchViewToPresenter {

    weak var view: SearchPresenterToView?
    var interactor: SearchPresenterToInteractor?
    var router: SearchPresenterToRouter?
    var tracksViewModel: [TrackViewModel]?

    /// "daft punk" is nine keystrokes; only the last one should survive to fire.
    private let debounceInterval: TimeInterval = 0.4
    private var pendingSearch: DispatchWorkItem?
    /// The query the user last typed. Responses for anything else are stale.
    private var latestQuery: String = ""

    func viewDidLoad() {
        view?.showState(.empty)
    }

    func getTracks() -> [TrackViewModel]? {
        return tracksViewModel
    }

    func searchTextDidChange(_ text: String) {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        latestQuery = query
        pendingSearch?.cancel()

        guard !query.isEmpty else {
            interactor?.cancelSearch()
            tracksViewModel = []
            view?.reloadTableView()
            view?.showState(.empty)
            return
        }

        let work = DispatchWorkItem { [weak self] in
            self?.runSearch(query: query)
        }
        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }

    func searchButtonClicked(with text: String) {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        // The user asked for it now — skip the remaining debounce.
        pendingSearch?.cancel()
        latestQuery = query
        runSearch(query: query)
    }

    func didSelectTrack(at index: Int) {
        guard let tracks = tracksViewModel, tracks.indices.contains(index),
              let url = tracks[index].spotifyUrl else { return }
        router?.navigateToSpotify(url: url, from: view)
    }

    private func runSearch(query: String) {
        view?.showState(.loading)
        interactor?.searchTracks(query: query)
    }
}

extension SearchPresenter: SearchInteractorToPresenter {

    func didSuccessSearchTracks(query: String, tracks: [Track]) {
        // Responses can arrive out of order: "da" can land after "daft punk".
        // Anything that isn't the query in the search bar is dropped.
        guard query == latestQuery else { return }

        tracksViewModel = tracks.map { TrackViewModel(from: $0) }
        view?.reloadTableView()

        if tracks.isEmpty {
            view?.showState(.noMatches(query: query))
        } else {
            view?.showState(.results)
        }
    }

    func didFailedSearchTracks(query: String, error: SpotifyError) {
        guard query == latestQuery else { return }

        tracksViewModel = []
        view?.reloadTableView()
        view?.showState(.error(message: error.displayMessage))
    }
}
