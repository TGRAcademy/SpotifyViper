//
//  Constants.swift
//  SpotifyViper
//
//  Endpoints and credentials come from Info.plist, so no URL or key is written
//  in the middle of the code that uses it.
//
//  Create an app at https://developer.spotify.com/dashboard, tick Web API, then
//  put its Client ID and Client secret into CLIENT_ID / CLIENT_SECRET in
//  SpotifyViper/Info.plist.
//

import Foundation

public class Constant {

    public static var baseUrl: String {
        return Bundle.main.infoDictionary?["BASE_URL"] as? String ?? ""
    }

    public static var accountsUrl: String {
        return Bundle.main.infoDictionary?["ACCOUNTS_URL"] as? String ?? ""
    }

    public static var clientId: String {
        return Bundle.main.infoDictionary?["CLIENT_ID"] as? String ?? ""
    }

    public static var clientSecret: String {
        return Bundle.main.infoDictionary?["CLIENT_SECRET"] as? String ?? ""
    }

    public static var areCredentialsConfigured: Bool {
        return !clientId.isEmpty && !clientSecret.isEmpty
    }

    /// The Client Credentials flow sends `Basic base64(id:secret)`.
    public static var basicAuthorizationHeader: String {
        let joined = "\(clientId):\(clientSecret)"
        return "Basic \(Data(joined.utf8).base64EncodedString())"
    }
}
