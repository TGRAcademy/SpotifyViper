//
//  SearchViewModel.swift
//  SpotifyViper
//
//  What the View is allowed to know about a row: strings, already formatted.
//  It never sees a `Track`, so it can never be tempted to format one.
//

import Foundation

struct TrackViewModel {
    var id: String?
    var title: String?
    var subtitle: String?
    var duration: String?
    var isExplicit: Bool
    var artworkUrl: URL?
    var spotifyUrl: URL?

    init(from response: Track) {
        self.id = response.id
        self.title = response.name
        self.isExplicit = response.explicit ?? false

        let artists = (response.artists ?? []).compactMap { $0.name }.joined(separator: ", ")
        let album = response.album?.name ?? ""
        if artists.isEmpty {
            self.subtitle = album
        } else if album.isEmpty {
            self.subtitle = artists
        } else {
            self.subtitle = "\(artists) · \(album)"
        }

        let totalSeconds = (response.durationMs ?? 0) / 1000
        self.duration = String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)

        // Spotify returns album images largest-first; a 56×56 pt row wants the smallest.
        let images: [AlbumImage] = response.album?.images ?? []
        let smallest: AlbumImage? = images.min { (lhs: AlbumImage, rhs: AlbumImage) -> Bool in
            let lhsWidth: Int = lhs.width ?? Int.max
            let rhsWidth: Int = rhs.width ?? Int.max
            return lhsWidth < rhsWidth
        }

        if let artworkPath: String = smallest?.url {
            self.artworkUrl = URL(string: artworkPath)
        }
        if let spotifyPath: String = response.externalUrls?.spotify {
            self.spotifyUrl = URL(string: spotifyPath)
        }
    }
}

/// The five states from page 1 of the brief, as one closed set.
enum SearchState {
    case empty
    case loading
    case results
    case noMatches(query: String)
    case error(message: String)
}
