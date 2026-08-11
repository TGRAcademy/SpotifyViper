//
//  SpotifyManager.swift
//  SpotifyViper
//
//  All the Moya code lives here. The Interactor asks the manager for data and
//  hears back through a delegate — it never sees a provider or a response.
//

import Foundation
import Moya

protocol Networkable {
    associatedtype T: TargetType
    var provider: MoyaProvider<T> { get }
}

protocol SpotifyManagerProtocol {
    var searchDelegate: SpotifySearchProtocol? { get set }
    func searchTracks(query: String, limit: Int)
    func cancelSearch()
}

class SpotifyManager: Networkable, SpotifyManagerProtocol {

    var provider: MoyaProvider<SpotifyServices>
    weak var searchDelegate: SpotifySearchProtocol?

    private let tokenProvider: SpotifyTokenProvider
    /// The request currently in flight, kept so a new keystroke can cancel it.
    private var inFlightRequest: Moya.Cancellable?

    init(tokenProvider: SpotifyTokenProvider = .shared) {
        self.tokenProvider = tokenProvider
        self.provider = MoyaProvider<SpotifyServices>(
            plugins: [SpotifyAuthPlugin(tokenProvider: tokenProvider)]
        )
    }

    func searchTracks(query: String, limit: Int) {
        cancelSearch()

        tokenProvider.token { [weak self] result in
            switch result {
            case .success:
                self?.performSearch(query: query, limit: limit, isRetry: false)
            case .failure(let error):
                self?.searchDelegate?.didFailedSearchTracks(query: query, error: error)
            }
        }
    }

    func cancelSearch() {
        inFlightRequest?.cancel()
        inFlightRequest = nil
    }

    // MARK: - Private

    private func performSearch(query: String, limit: Int, isRetry: Bool) {
        inFlightRequest = provider.request(.searchTracks(query: query, limit: limit),
                                           callbackQueue: .main) { [weak self] (result) in
            guard let self = self else { return }
            self.inFlightRequest = nil

            switch result {
            case .success(let response):
                // A 401 here means the cached token expired mid-flight. Throw it
                // away and try exactly once more — never loop.
                if response.statusCode == 401, !isRetry {
                    self.tokenProvider.invalidate()
                    self.retryAfterTokenRefresh(query: query, limit: limit)
                    return
                }

                do {
                    let filtered = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    let tracks = try decoder.decode(Tracks.self, from: filtered.data)
                    self.searchDelegate?.didSuccessSearchTracks(query: query, response: tracks)
                } catch let error {
                    self.searchDelegate?.didFailedSearchTracks(query: query,
                                                               error: SpotifyError(moyaError: error))
                }

            case .failure(let error):
                // A cancelled request is not a failure the user should ever see.
                if case .underlying(let underlying, _) = error,
                   (underlying as NSError).code == NSURLErrorCancelled {
                    return
                }
                self.searchDelegate?.didFailedSearchTracks(query: query,
                                                           error: SpotifyError(moyaError: error))
            }
        }
    }

    private func retryAfterTokenRefresh(query: String, limit: Int) {
        tokenProvider.token { [weak self] result in
            switch result {
            case .success:
                self?.performSearch(query: query, limit: limit, isRetry: true)
            case .failure(let error):
                self?.searchDelegate?.didFailedSearchTracks(query: query, error: error)
            }
        }
    }
}

protocol SpotifySearchProtocol: AnyObject {
    func didSuccessSearchTracks(query: String, response: Tracks)
    func didFailedSearchTracks(query: String, error: SpotifyError)
}
