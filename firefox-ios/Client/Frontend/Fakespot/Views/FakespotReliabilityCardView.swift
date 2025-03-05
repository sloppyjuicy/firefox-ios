// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import UIKit

struct FakespotReliabilityCardViewModel {
    let cardA11yId: String = AccessibilityIdentifiers.Shopping.ReliabilityCard.card
    let title: String = .Shopping.ReliabilityCardTitle
    let titleA11yId: String = AccessibilityIdentifiers.Shopping.ReliabilityCard.title
    let grade: ReliabilityGrade
    let gradeLetterA11yId: String = AccessibilityIdentifiers.Shopping.ReliabilityCard.ratingLetter
    let gradeDescriptionA11yId: String = AccessibilityIdentifiers.Shopping.ReliabilityCard.ratingDescription
}

class FakespotReliabilityCardView: UIView, ThemeApplicable {
    private struct UX {
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 4
        static let letterVerticalPadding: CGFloat = 4
        static let letterHorizontalPadding: CGFloat = 7
        static let descriptionVerticalPadding: CGFloat = 6
        static let descriptionHorizontalPadding: CGFloat = 8
        static let descriptionBackgroundAlpha: CGFloat = 0.15
    }

    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var contentView: UIView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.header)
    }

    private lazy var reliabilityScoreView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.layer.borderWidth = 1
        view.clipsToBounds = true
    }

    private lazy var reliabilityLetterView: UIView = .build()
    private lazy var reliabilityDescriptionView: UIView = .build()

    private lazy var reliabilityLetterLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.footnote.scaledFont()
    }

    private lazy var reliabilityDescriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
    }

    private var viewModel: FakespotReliabilityCardViewModel?

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ viewModel: FakespotReliabilityCardViewModel) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yId

        reliabilityLetterLabel.text = viewModel.grade.rawValue
        reliabilityLetterLabel.accessibilityLabel = String(format: .Shopping.ReliabilityScoreGradeA11yLabel,
                                                           viewModel.grade.rawValue)
        reliabilityLetterLabel.accessibilityIdentifier = viewModel.gradeLetterA11yId
        reliabilityDescriptionLabel.text = viewModel.grade.description
        reliabilityDescriptionLabel.accessibilityIdentifier = viewModel.gradeDescriptionA11yId

        let cardModel = ShadowCardViewModel(view: contentView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
    }

    // MARK: Theming System
    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
        reliabilityScoreView.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        reliabilityScoreView.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15).cgColor
        reliabilityLetterLabel.textColor = theme.colors.textOnLight
        reliabilityDescriptionLabel.textColor = theme.colors.textOnLight

        if let viewModel {
            reliabilityLetterView.layer.backgroundColor = viewModel.grade.color(theme: theme).cgColor
            reliabilityDescriptionView.layer.backgroundColor = viewModel.grade.colorSubdued(theme: theme).cgColor
        }
    }

    // MARK: Layout Setup
    private func setupLayout() {
        addSubview(cardContainer)

        reliabilityLetterView.addSubview(reliabilityLetterLabel)
        reliabilityDescriptionView.addSubview(reliabilityDescriptionLabel)
        reliabilityScoreView.addSubview(reliabilityLetterView)
        reliabilityScoreView.addSubview(reliabilityDescriptionView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(reliabilityScoreView)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.horizontalPadding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: UX.verticalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.horizontalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: reliabilityScoreView.topAnchor,
                                               constant: -UX.verticalPadding),

            reliabilityScoreView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                          constant: UX.horizontalPadding),
            reliabilityScoreView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor,
                                                           constant: -UX.horizontalPadding),
            reliabilityScoreView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                         constant: -UX.verticalPadding),

            reliabilityLetterView.leadingAnchor.constraint(equalTo: reliabilityScoreView.leadingAnchor),
            reliabilityLetterView.topAnchor.constraint(equalTo: reliabilityScoreView.topAnchor),
            reliabilityLetterView.trailingAnchor.constraint(equalTo: reliabilityDescriptionView.leadingAnchor),
            reliabilityLetterView.bottomAnchor.constraint(equalTo: reliabilityScoreView.bottomAnchor),

            reliabilityDescriptionView.topAnchor.constraint(equalTo: reliabilityScoreView.topAnchor),
            reliabilityDescriptionView.trailingAnchor.constraint(equalTo: reliabilityScoreView.trailingAnchor),
            reliabilityDescriptionView.bottomAnchor.constraint(equalTo: reliabilityScoreView.bottomAnchor),

            reliabilityLetterLabel.leadingAnchor.constraint(equalTo: reliabilityLetterView.leadingAnchor,
                                                            constant: UX.letterHorizontalPadding),
            reliabilityLetterLabel.topAnchor.constraint(equalTo: reliabilityLetterView.topAnchor,
                                                        constant: UX.letterVerticalPadding),
            reliabilityLetterLabel.trailingAnchor.constraint(equalTo: reliabilityLetterView.trailingAnchor,
                                                             constant: -UX.letterHorizontalPadding),
            reliabilityLetterLabel.bottomAnchor.constraint(equalTo: reliabilityLetterView.bottomAnchor,
                                                           constant: -UX.letterVerticalPadding),

            reliabilityDescriptionLabel.leadingAnchor.constraint(equalTo: reliabilityDescriptionView.leadingAnchor,
                                                                 constant: UX.descriptionHorizontalPadding),
            reliabilityDescriptionLabel.topAnchor.constraint(equalTo: reliabilityDescriptionView.topAnchor,
                                                             constant: UX.descriptionVerticalPadding),
            reliabilityDescriptionLabel.trailingAnchor.constraint(equalTo: reliabilityDescriptionView.trailingAnchor,
                                                                  constant: -UX.descriptionHorizontalPadding),
            reliabilityDescriptionLabel.bottomAnchor.constraint(equalTo: reliabilityDescriptionView.bottomAnchor,
                                                                constant: -UX.descriptionVerticalPadding),
        ])
    }
}
