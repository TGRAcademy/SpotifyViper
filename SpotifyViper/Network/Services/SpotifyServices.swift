//
//  SpotifyServices.swift
//  SpotifyViper
//
//  Every endpoint the app talks to, described once as a Moya TargetType.
//

import Foundation
import Moya

enum SpotifyServices {
    /// Client Credentials flow — exchanges the app's ID/secret for a bearer token.
    case token
    /// GET /v1/search?q=…&type=track&limit=20
    case searchTracks(query: String, limit: Int)
}

extension SpotifyServices: TargetType {

    var baseURL: URL {
        switch self {
        case .token:
            guard let url = URL(string: Constant.accountsUrl) else {
                fatalError("baseURL could not be configured.")
            }
            return url
        case .searchTracks:
            guard let url = URL(string: Constant.baseUrl) else {
                fatalError("baseURL could not be configured.")
            }
            return url
        }
    }

    var path: String {
        switch self {
        case .token:
            return "api/token"
        case .searchTracks:
            return "v1/search"
        }
    }

    var method: Moya.Method {
        switch self {
        case .token:
            return .post
        case .searchTracks:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .token:
            return .requestParameters(parameters: ["grant_type": "client_credentials"],
                                      encoding: URLEncoding.httpBody)
        case .searchTracks(query: let query, limit: let limit):
            return .requestParameters(parameters: ["q": query, "type": "track", "limit": limit],
                                      encoding: URLEncoding.queryString)
        }
    }

    var sampleData: Data {
        return Data()
    }

    var headers: [String: String]? {
        switch self {
        case .token:
            return ["Authorization": Constant.basicAuthorizationHeader,
                    "Content-type": "application/x-www-form-urlencoded"]
        case .searchTracks:
            // The bearer token is stamped on by SpotifyAuthPlugin, which is the
            // only place that knows whether the cached one is still valid.
            return ["Content-type": "application/json"]
        }
    }

    /// `true` for the calls that must carry `Authorization: Bearer <token>`.
    var requiresBearerToken: Bool {
        switch self {
        case .token:
            return false
        case .searchTracks:
            return true
        }
    }
}
