# SpotifyViper

A Spotify search screen built with **VIPER**, UIKit and `.xib` files.
Type a query, see matching tracks, tap one to open it in Spotify.

Stack: **UIKit · XIB · VIPER · Moya · Kingfisher · netfox**, all through Swift
Package Manager.

---

## 1. Get your Spotify credentials

The app talks to the Spotify Web API, which needs a Client ID and a Client
Secret. They are free.

1. Sign in at <https://developer.spotify.com/dashboard> with any Spotify account.
2. **Create app.** Any name and description will do. For Redirect URI put
   `http://127.0.0.1:3000` — this app never uses it. Tick **Web API**.
3. Open the app → **Settings** → copy the **Client ID** and **Client secret**.

## 2. Put them in Info.plist

Open `SpotifyViper/Info.plist` and fill in the two empty strings at the top:

```xml
<key>CLIENT_ID</key>
<string>paste_your_client_id_here</string>
<key>CLIENT_SECRET</key>
<string>paste_your_client_secret_here</string>
```

`Constants.swift` reads them from the bundle, so no key is ever written in the
middle of the code that uses it:

```swift
public static var clientId: String {
    return Bundle.main.infoDictionary?["CLIENT_ID"] as? String ?? ""
}
```

Leave them empty and the app still runs — it shows *"Add your Spotify Client ID
and Secret in Info.plist."* instead of crashing.

> **Note:** anything in `Info.plist` ships inside the app bundle and can be
> extracted from it. That is fine for a learning project, but a real app keeps
> its secret on a server it controls.

## 3. What XcodeGen is, and why this project uses it

An `.xcodeproj` is not really a folder — it is a large generated file
(`project.pbxproj`) that lists every source file, build setting and dependency.
Because Xcode rewrites it constantly, two people editing the same project
produce merge conflicts that are close to unreadable.

[XcodeGen](https://github.com/yonaskolb/XcodeGen) turns that around. You describe
the project once in a short YAML file, and XcodeGen generates the `.xcodeproj`
from it. The YAML is the source of truth; the `.xcodeproj` becomes a build
artefact you can delete and regenerate at any time.

What that buys you:

- **No merge conflicts** — you review a 40-line YAML file, not a 900-line pbxproj.
- **Files on disk are the project.** Add a `.swift` file to a folder, regenerate,
  and it is in the build. No dragging into Xcode, no forgetting target membership.
- **The setup is readable.** `project.yml` below is the entire configuration.

### Install it

```sh
brew install xcodegen
```

### Generate the project

From the folder containing `project.yml`:

```sh
xcodegen generate
open SpotifyViper.xcodeproj
```

Run **`xcodegen generate` again after adding, renaming or deleting any file.**
Nothing is lost by doing so — the project is rebuilt from `project.yml` and the
files on disk. Xcode will notice and reload it.

### What `project.yml` says

```yaml
name: SpotifyViper
options:
  deploymentTarget: { iOS: "16.0" }

packages:                          # Swift Package Manager dependencies
  Moya:       { url: ..., from: "15.0.0" }
  Kingfisher: { url: ..., from: "7.10.0" }
  netfox:     { url: ..., from: "1.21.0" }

targets:
  SpotifyViper:
    type: application
    sources: [ path: SpotifyViper ]   # everything in this folder is compiled
    dependencies: [ Moya, Kingfisher, netfox ]
```

Xcode resolves the three packages the first time you build, so the first build
needs a network connection and takes a minute longer than the rest.

## 4. Run it

Open `SpotifyViper.xcodeproj` and run on any iOS 16+ simulator.

---

## What VIPER is

VIPER splits one screen into five objects, each with a single job. The name is
the five of them:

| Layer | Job | May import |
|---|---|---|
| **V**iew | Owns outlets, shows what it is told, forwards taps | UIKit |
| **I**nteractor | Business logic; asks for data | Foundation |
| **P**resenter | The middle: decides, formats, holds screen state | Foundation |
| **E**ntity | Plain data | Foundation |
| **R**outer | Navigation in and out of the screen | UIKit |

The idea behind it is the **Single Responsibility Principle** taken to the level
of a whole screen. In plain UIKit a `UIViewController` ends up owning views,
networking, formatting, state and navigation all at once — the "Massive View
Controller". VIPER gives each of those a named file, so there is never an
argument about where a piece of code goes.

### How one search flows through it

```
user types "daft punk"
        │
        ▼
   SearchView ──────────► SearchPresenter ──────────► SearchInteractor
   (search bar delegate)   debounces 0.4 s,            asks SpotifyManager
                           tracks latest query          for results
        ▲                        ▲                             │
        │                        │                             ▼
        │                        └───────────────────── [Track] entities
        │                                                      
        └──── render(.results) ◄── formats into TrackViewModel
                                    ("3:45", "Daft Punk · Discovery")
```

Two things to notice. The View is handed **finished strings**, never a `Track` —
so it has no way to format data even if it wanted to. And the Presenter imports
Foundation only; the moment it needs UIKit, something has been put in the wrong
layer.

### The protocol wall

Layers never touch each other's types directly. Every conversation goes through a
protocol, and all of them live in one file, `SearchProtocol.swift`:

```swift
protocol SearchViewToPresenter: AnyObject {   // what the View may ask
    func viewDidLoad()
    func searchTextDidChange(_ text: String)
    func getTracks() -> [TrackViewModel]?
}

protocol SearchPresenterToView: AnyObject {   // what the Presenter may say back
    func reloadTableView()
    func showState(_ state: SearchState)
}
```

The naming reads as a direction: `SearchViewToPresenter` is the View talking to
the Presenter. If a layer needs something new from another, it is written here
first, or it does not happen.

This is what makes VIPER testable: a test hands the Presenter a fake object
conforming to `SearchPresenterToView` and asserts on what it receives — no
simulator, no views.

### Who owns whom

```
SearchView ──strong──► SearchPresenter ──strong──► SearchInteractor
     ▲                        │                          │
     └────── weak ────────────┘                          │
                              └──strong──► SearchRouter  │
                                     ▲                   │
                                     └─── weak ──────────┘
```

Ownership points one way — down. Every reference pointing back up
(`presenter.view`, `interactor.presenter`, `router.viewController`) is `weak`.
Make one of them strong and the screen never deallocates.

### Assembly

Something has to build all five and connect them. Here that is
`ScreenConfigurator`, so the Router is left with nothing but navigation:

```swift
func createSearchScreen() -> UIViewController {
    let view = SearchView()
    let presenter = SearchPresenter()
    let interactor = SearchInteractor()
    let router = SearchRouter()

    view.presenter = presenter
    presenter.view = view
    presenter.interactor = interactor
    presenter.router = router
    interactor.presenter = presenter

    return view
}
```

### The honest trade-off

VIPER costs five files and a protocol wall before a screen renders anything, and
a trivial change can touch four of them. It pays that back when a screen is
complex, several people work on it at once, or the logic genuinely needs testing
without a UI. On a single simple screen it is more structure than the problem
requires — and being able to say that is worth more than defending the pattern.

The same screen written in MVVM is in [`../SpotifyMVVM`](../SpotifyMVVM): three
files instead of seven, identical UI, identical network layer. Reading them
side by side is the fastest way to see what the extra structure buys and costs.

---

## Project layout

```
SpotifyViper/
├─ AppDelegate.swift, SceneDelegate.swift
├─ Configurator/     ScreenConfigurator — builds and wires a scene
├─ Constants/        Constants (reads Info.plist), AppTheme (colours, metrics)
├─ Extensions/       UIColor+Hex
├─ Entities/         TracksModel — the API response, Codable
├─ Network/
│  ├─ Manager/       SpotifyManager (Moya calls), SpotifyTokenProvider, SpotifyError
│  └─ Services/      SpotifyServices (endpoints), SpotifyAuthPlugin (bearer header)
└─ Scenario/
   └─ Search/
      ├─ SearchProtocol.swift    every layer contract, one file
      ├─ SearchView.swift + .xib
      ├─ SearchPresenter.swift
      ├─ SearchInteractor.swift
      ├─ SearchRouter.swift
      ├─ SearchViewModel/        TrackViewModel, SearchState
      └─ SearchCell/  + .xib     one row
```

## Debugging the network

**netfox** is started in `AppDelegate` under `#if DEBUG`. Shake the device — in
the simulator, **⌃⌘Z** — to open a log of every request, with headers and
response bodies. Useful for watching the token call happen once, and the debounce
collapsing nine keystrokes into a single search.

## Known API limits

- **`limit` is capped at 10.** A Development-mode app gets
  `400 Invalid limit` for anything higher, and defaults to 5 when the parameter
  is omitted — regardless of what the documentation says.
- **No user data.** The Client Credentials flow authenticates the app, not a
  person, so there is no login, no playlists and no saved tracks.
