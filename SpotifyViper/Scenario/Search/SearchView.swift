//
//  SearchView.swift
//  SpotifyViper
//
//  Outlets, delegates and rendering. It pulls its rows from the Presenter and
//  never formats data — SearchView.xib is loaded automatically because it is
//  named after this class.
//

import UIKit

class SearchView: UIViewController, SearchPresenterToView {

    var presenter: SearchViewToPresenter?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tracksTableView: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTableView()
        searchBar.delegate = self
        presenter?.viewDidLoad()
    }

    func setupAppearance() {
        view.backgroundColor = AppTheme.background

        titleLabel.text = "Search"
        titleLabel.textColor = AppTheme.primaryText
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)

        searchBar.placeholder = "Songs, artists, albums"
        searchBar.searchTextField.backgroundColor = AppTheme.surface
        searchBar.searchTextField.textColor = AppTheme.primaryText
        searchBar.tintColor = AppTheme.accent
        searchBar.returnKeyType = .search

        messageLabel.textColor = AppTheme.secondaryText
        messageLabel.font = .systemFont(ofSize: 15)
        activityIndicator.color = AppTheme.secondaryText
    }

    func setupTableView() {
        let uiNib = UINib(nibName: String(describing: SearchCell.self), bundle: nil)
        tracksTableView.delegate = self
        tracksTableView.dataSource = self
        tracksTableView.register(uiNib, forCellReuseIdentifier: String(describing: SearchCell.self))
        tracksTableView.rowHeight = AppTheme.rowHeight
        tracksTableView.backgroundColor = AppTheme.background
        tracksTableView.separatorColor = AppTheme.separator
        tracksTableView.separatorInset = UIEdgeInsets(top: 0, left: 84, bottom: 0, right: 0)
        tracksTableView.keyboardDismissMode = .onDrag
        tracksTableView.tableFooterView = UIView()
    }

    func reloadTableView() {
        tracksTableView.reloadData()
    }

    func showState(_ state: SearchState) {
        switch state {
        case .empty:
            show(message: "Search Spotify for a song, artist or album.", isLoading: false)
        case .loading:
            show(message: nil, isLoading: true)
        case .results:
            show(message: nil, isLoading: false)
        case .noMatches(query: let query):
            show(message: "No results for “\(query)”.", isLoading: false)
        case .error(message: let message):
            show(message: message, isLoading: false)
        }
    }

    private func show(message: String?, isLoading: Bool) {
        messageLabel.text = message
        messageLabel.isHidden = message == nil || isLoading

        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}

extension SearchView: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter?.searchTextDidChange(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        presenter?.searchButtonClicked(with: searchBar.text ?? "")
    }
}

extension SearchView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tracks = presenter?.getTracks() else { return .zero }
        return tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: SearchCell.self),
            for: indexPath) as? SearchCell else {
            return UITableViewCell()
        }

        guard let tracks = presenter?.getTracks() else { return cell }
        cell.setupTrack(track: tracks[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter?.didSelectTrack(at: indexPath.row)
    }
}
