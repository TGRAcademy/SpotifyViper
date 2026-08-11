//
//  SpotifyAuthPlugin.swift
//  SpotifyViper
//
//  A Moya plugin stamps every outgoing request. This one adds the bearer token
//  to the targets that need it, so no call site has to remember to.
//

import Foundation
import Moya

struct SpotifyAuthPlugin: PluginType {

    let tokenProvider: SpotifyTokenProvider

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard
            let service = target as? SpotifyServices,
            service.requiresBearerToken,
            let token = tokenProvider.currentToken
        else {
            return request
        }

        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
