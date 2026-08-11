//
//  TracksModel.swift
//  SpotifyViper
//
//  Only the JSON the screen actually shows is modelled. Entities are plain
//  data — no UIKit, no networking, no formatting decisions.
//

import Foundation

struct Tracks: Codable {
    var tracks: TrackPage?
}

struct TrackPage: Codable {
    var items: [Track]?
}

struct Track: Codable {
    var id: String?
    var name: String?
    var durationMs: Int?
    var explicit: Bool?
    var artists: [Artist]?
    var album: Album?
    var externalUrls: ExternalUrls?

    enum CodingKeys: String, CodingKey {
        case id, name, explicit, artists, album
        case durationMs = "duration_ms"
        case externalUrls = "external_urls"
    }
}

struct Artist: Codable {
    var name: String?
}

struct Album: Codable {
    var name: String?
    var images: [AlbumImage]?
}

struct AlbumImage: Codable {
    var url: String?
    var width: Int?
    var height: Int?
}

struct ExternalUrls: Codable {
    var spotify: String?
}
