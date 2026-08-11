//
//  SpotifyTokenProvider.swift
//  SpotifyViper
//
//  Owns the Client Credentials token: caches it, refreshes it 60 s early, and
//  de-duplicates concurrent refreshes so nine keystrokes never mean nine token
//  requests.
//

import Foundation
import Moya

final class SpotifyTokenProvider {

    static let shared = SpotifyTokenProvider()

    private let provider = MoyaProvider<SpotifyServices>()
    private let lock = NSLock()

    private var cachedToken: String?
    private var expiresAt: Date = .distantPast
    private var waiters: [(Result<String, SpotifyError>) -> Void] = []
    private var isRefreshing = false

    /// The token as the plugin sees it — synchronous, no fetching.
    var currentToken: String? {
        lock.lock()
        defer { lock.unlock() }
        return cachedToken
    }

    /// Hands back a valid token, fetching one only when the cache is cold or stale.
    func token(completion: @escaping (Result<String, SpotifyError>) -> Void) {
        guard Constant.areCredentialsConfigured else {
            completion(.failure(.missingCredentials))
            return
        }

        lock.lock()
        if let token = cachedToken, Date() < expiresAt.addingTimeInterval(-60) {
            lock.unlock()
            completion(.success(token))
            return
        }

        waiters.append(completion)
        guard !isRefreshing else {
            lock.unlock()
            return
        }
        isRefreshing = true
        lock.unlock()

        provider.request(.token) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(response):
                do {
                    let filtered = try response.filterSuccessfulStatusCodes()
                    let payload = try JSONDecoder().decode(TokenResponse.self, from: filtered.data)
                    self.finishRefresh(with: .success(payload))
                } catch {
                    self.finishRefresh(with: .failure(SpotifyError(moyaError: error)))
                }
            case let .failure(error):
                self.finishRefresh(with: .failure(SpotifyError(moyaError: error)))
            }
        }
    }

    /// Drops the cached token so the next call fetches a fresh one — used after a 401.
    func invalidate() {
        lock.lock()
        cachedToken = nil
        expiresAt = .distantPast
        lock.unlock()
    }

    private func finishRefresh(with result: Result<TokenResponse, SpotifyError>) {
        lock.lock()
        isRefreshing = false

        let outcome: Result<String, SpotifyError>
        switch result {
        case let .success(payload):
            cachedToken = payload.accessToken
            expiresAt = Date().addingTimeInterval(TimeInterval(payload.expiresIn))
            outcome = .success(payload.accessToken)
        case let .failure(error):
            cachedToken = nil
            expiresAt = .distantPast
            outcome = .failure(error == .unauthorized ? .invalidCredentials : error)
        }

        let pending = waiters
        waiters.removeAll()
        lock.unlock()

        pending.forEach { $0(outcome) }
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let expiresIn: Int

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
        }
    }
}
