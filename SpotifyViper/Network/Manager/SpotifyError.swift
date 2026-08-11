//
//  SpotifyError.swift
//  SpotifyViper
//
//  Moya hands back transport failures and HTTP status codes as the same
//  `MoyaError`. This flattens them into the handful of cases the UI actually
//  distinguishes — which is what page 1's "state 5" needs.
//

import Foundation
import Moya

enum SpotifyError: Error, Equatable {
    case missingCredentials
    case invalidCredentials
    case unauthorized
    case rateLimited
    case offline
    case decoding
    case server(status: Int)
    case unknown

    init(moyaError: Error) {
        guard let moyaError = moyaError as? MoyaError else {
            self = .unknown
            return
        }

        switch moyaError {
        case let .statusCode(response):
            self = SpotifyError(statusCode: response.statusCode)

        case let .underlying(underlying, _):
            let nsError = underlying as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorTimedOut,
                     NSURLErrorCannotConnectToHost:
                    self = .offline
                default:
                    self = .unknown
                }
            } else {
                self = .unknown
            }

        case .jsonMapping, .objectMapping, .stringMapping, .imageMapping:
            self = .decoding

        default:
            self = .unknown
        }
    }

    init(statusCode: Int) {
        switch statusCode {
        case 401, 403:
            self = .unauthorized
        case 429:
            self = .rateLimited
        default:
            self = .server(status: statusCode)
        }
    }

    /// The sentence shown in the error state. Presenter-facing, not View-facing —
    /// the View never builds copy of its own.
    var displayMessage: String {
        switch self {
        case .missingCredentials:
            return "Add your Spotify Client ID and Secret in Info.plist."
        case .invalidCredentials:
            return "Spotify rejected those credentials. Check the Client ID and Secret."
        case .unauthorized:
            return "Spotify rejected the request. Check the Client ID and Secret."
        case .rateLimited:
            return "Too many requests. Wait a moment and try again."
        case .offline:
            return "The internet connection appears to be offline."
        case .decoding:
            return "Spotify sent something unexpected."
        case let .server(status):
            return "Spotify returned an error (\(status))."
        case .unknown:
            return "Something went wrong. Try again."
        }
    }
}
