//
//  SearchCell.swift
//  SpotifyViper
//
//  One row. It receives a `TrackViewModel` of finished strings — it never sees
//  a `Track` and never formats anything.
//

import UIKit
import Kingfisher

class SearchCell: UITableViewCell {

    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var explicitBadge: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = AppTheme.background
        contentView.backgroundColor = AppTheme.background

        let selected = UIView()
        selected.backgroundColor = AppTheme.surface
        selectedBackgroundView = selected

        artworkImageView.layer.cornerRadius = AppTheme.artworkCornerRadius
        artworkImageView.layer.masksToBounds = true
        artworkImageView.backgroundColor = AppTheme.surface

        explicitBadge.layer.cornerRadius = 2
        explicitBadge.layer.masksToBounds = true

        // The duration keeps its natural size; the title is what gives way.
        durationLabel.setContentHuggingPriority(.required, for: .horizontal)
        durationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Cancel the download this cell started before it becomes a different row,
        // otherwise a slow response paints artwork into the wrong track.
        artworkImageView.kf.cancelDownloadTask()
        artworkImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        durationLabel.text = nil
        explicitBadge.isHidden = true
    }

    func setupTrack(track: TrackViewModel) {
        titleLabel.text = track.title
        subtitleLabel.text = track.subtitle
        durationLabel.text = track.duration
        explicitBadge.isHidden = !track.isExplicit

        // Kingfisher keys the request to this image view, so a cell recycled
        // mid-download shows the row it is now, not the row it was.
        artworkImageView.kf.setImage(with: track.artworkUrl)
    }
}
