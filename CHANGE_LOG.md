# Change Log - SpotifyViper

What changed on the screen, for the person who has to click through it. The diff is one `git log`
away, so nothing here restates it. Each release is one row: what to re-test, what moved, and why.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow
[Semantic Versioning](https://semver.org/).

## How to read a row

- **Version** — `MAJOR.MINOR.PATCH`. MAJOR when an existing flow is understood differently
  afterwards, MINOR when a flow or screen is added and the old ones still read the same, PATCH for a
  fix inside a flow that already exists.
- **Impacted Features** — the screens or roles to re-test, separated by semicolons.
- **Changes Made** — bullets grouped as `Added`, `Changed`, `Fixed`, `Removed`, `Data`.
- **Date & Time** — local time at release, `YYYY-MM-DD HH:MM`.
- **Author** — the person who decided the change, not whoever typed it.

## Data in this app

Nothing is seeded and nothing survives the app being killed. Every track on screen comes from the
Spotify Web API at the moment you type, and the only thing held between requests is the bearer token,
in memory. So a `Data` bullet here means the request changed (`q`, `type`, `limit`) or the credentials
in `SpotifyViper/Info.plist` did, and picking it up means a rebuild, not a reset. Add a file, rename
one, or delete one and run `xcodegen generate` before building, since `project.yml` is the source of
truth for the Xcode project.

| Version | Impacted Features | Changes Made | Date & Time | Author |
|---|---|---|---|---|
| **1.0.0** | Search screen; Track rows; Tap-through to the Spotify app | **Added**<br>• Search screen on launch, dark Spotify palette: `#121212` behind the list, `#1DB954` on the cursor and cancel button, `#B3B3B3` for secondary text. Search bar reads "Songs, artists, albums".<br>• Typing fires a search 0.4 s after you stop, so "daft punk" costs one request instead of nine. The return key skips the remaining wait and searches now.<br>• A row is artwork, title, "Artist · Album", and duration as `m:ss`, at 72 pt tall with 56 pt artwork. Spotify sends album art largest-first, and the row picks the smallest image rather than downscaling a 640 px one.<br>• Tapping a row leaves the app and opens that track in Spotify, through the `external_urls.spotify` link on the track.<br>• Five states on one screen: a prompt before you have typed anything, a spinner while the request is out, the list, `No results for "<query>"`, and an error sentence.<br>• Each failure gets its own sentence instead of a status code: offline, "Too many requests. Wait a moment and try again." on HTTP 429, "Spotify rejected the request. Check the Client ID and Secret." on 401 or 403, and "Spotify sent something unexpected." when the JSON does not decode.<br>• The screen drops any response whose query is no longer in the search bar, so a slow "da" landing after "daft punk" cannot overwrite the results you are looking at.<br>• Shake the simulator (⌃⌘Z) in a Debug build to open netfox and watch the token call happen once and the debounce collapse nine keystrokes into one search.<br><br>**Data**<br>• A search asks for 10 tracks. Spotify answers `400 Invalid limit` above 10 for an app in Development mode, and quietly returns 5 when the parameter is left off.<br>• Paste your Client ID and secret into `CLIENT_ID` and `CLIENT_SECRET` in `SpotifyViper/Info.plist` before the first run. Left empty, the screen says "Add your Spotify Client ID and Secret in Info.plist." and no request goes out.<br>• The bearer token is cached and refreshed 60 s before it expires, and refreshes that overlap collapse into a single call to `api/token`. | 2026-09-18 00:59 | Rizqi Widianto |
