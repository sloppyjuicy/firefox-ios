// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import UIKit

struct FakespotHighlightsCardViewModel {
    let cardA11yId: String = AccessibilityIdentifiers.Shopping.HighlightsCard.card
    let title: String = .Shopping.HighlightsCardTitle
    let titleA11yId: String = AccessibilityIdentifiers.Shopping.HighlightsCard.title
    let moreButtonTitle: String = .Shopping.HighlightsCardMoreButtonTitle
    let moreButtonA11yId: String = AccessibilityIdentifiers.Shopping.HighlightsCard.moreButton
    let lessButtonTitle: String = .Shopping.HighlightsCardLessButtonTitle
    let lessButtonA11yId: String = AccessibilityIdentifiers.Shopping.HighlightsCard.lessButton

    var expandState: CollapsibleCardView.ExpandButtonState = .collapsed
    var onExpandStateChanged: ((CollapsibleCardView.ExpandButtonState) -> Void)?

    let highlights: [FakespotHighlightGroup]

    var longestTextFromReviews: String? {
        highlights.first?.reviews.max()
    }

    var highlightGroupViewModels: [FakespotHighlightGroupViewModel] {
        var highlightGroups: [FakespotHighlightGroupViewModel] = []

        highlights.forEach { group in
            highlightGroups.append(FakespotHighlightGroupViewModel(highlightGroup: group))
        }
        return highlightGroups
    }

    var shouldShowMoreButton: Bool {
        guard let firstItem = highlights.first else { return false }

        return highlights.count > 1 || firstItem.reviews.count > 1
    }

    var shouldShowFadeInPreview: Bool {
        shouldShowMoreButton
    }

    var isOneHighlightGroupWithTwoReviews: Bool {
        guard let firstItem = highlights.first else { return false }
        return highlights.count == 1 && firstItem.reviews.count == 2
    }
}

class FakespotHighlightsCardView: UIView, ThemeApplicable {
    private struct UX {
        static let buttonCornerRadius: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonVerticalInset: CGFloat = 12
        static let contentHorizontalSpace: CGFloat = 8
        static let contentTopSpace: CGFloat = 8
        static let contentStackSpacing: CGFloat = 8
        static let highlightSpacing: CGFloat = 16
        static let highlightStackBottomSpace: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let groupImageSize: CGFloat = 24
    }

    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var contentView: UIView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.header)
    }

    private lazy var contentStackView: UIStackView = .build { view in
        view.axis = .vertical
        view.spacing = UX.contentStackSpacing
    }

    private lazy var highlightStackView: UIStackView = .build { view in
        view.axis = .vertical
        view.spacing = UX.highlightSpacing
    }

    private lazy var moreButton: SecondaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.showMoreAction), for: .touchUpInside)
    }

    private lazy var dividerView: UIView = .build()
    private var contentStackBottomConstraint: NSLayoutConstraint?

    private var highlightGroups: [FakespotHighlightGroupView] = []
    private var highlightPreviewGroups: [FakespotHighlightGroupView] = []
    private var viewModel: FakespotHighlightsCardViewModel?
    private var isShowingPreview = true

    private var safeAreaEdgeInsets: UIEdgeInsets {
        guard let keyWindow = UIWindow.keyWindow else { return UIEdgeInsets() }
        return keyWindow.safeAreaInsets
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ viewModel: FakespotHighlightsCardViewModel) {
        self.viewModel = viewModel
        let cardModel = ShadowCardViewModel(view: contentView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)

        viewModel.highlightGroupViewModels.forEach { viewModel in
            let highlightGroup: FakespotHighlightGroupView = .build()
            highlightGroup.configure(viewModel: viewModel)
            highlightGroups.append(highlightGroup)
        }
        if let firstItem = highlightGroups.first {
            highlightPreviewGroups = [firstItem]
        }
        updateHighlights()

        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yId

        let moreButtonViewModel = SecondaryRoundedButtonViewModel(
            title: viewModel.moreButtonTitle,
            a11yIdentifier: viewModel.moreButtonA11yId
        )
        moreButton.configure(viewModel: moreButtonViewModel)

        if !viewModel.shouldShowMoreButton {
            // remove divider & button and adjust bottom spacing
            for view in [dividerView, moreButton] {
                contentStackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            contentStackBottomConstraint?.constant = -UX.highlightStackBottomSpace
        }

        isShowingPreview = viewModel.expandState == .collapsed
        updateHighlights()
        updateExpandState()
    }

    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)

        highlightGroups.forEach { $0.applyTheme(theme: theme) }

        titleLabel.textColor = theme.colors.textPrimary
        moreButton.applyTheme(theme: theme)
        dividerView.backgroundColor = theme.colors.borderPrimary
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateHighlightsViewLayoutIfNeeded()
    }

    private func setupLayout() {
        contentStackView.addArrangedSubview(highlightStackView)
        contentStackView.addArrangedSubview(dividerView)
        contentStackView.addArrangedSubview(moreButton)
        contentStackView.setCustomSpacing(UX.highlightStackBottomSpace, after: highlightStackView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentStackView)
        addSubview(cardContainer)

        contentStackBottomConstraint = contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        contentStackBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.contentHorizontalSpace),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.contentTopSpace),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.contentHorizontalSpace),
            titleLabel.bottomAnchor.constraint(equalTo: contentStackView.topAnchor, constant: -UX.highlightSpacing),

            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                      constant: UX.contentHorizontalSpace),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                       constant: -UX.contentHorizontalSpace),
            dividerView.heightAnchor.constraint(equalToConstant: UX.dividerHeight),
        ])
    }

    private func updateHighlightsViewLayoutIfNeeded() {
        guard let viewModel,
                  viewModel.isOneHighlightGroupWithTwoReviews,
              let longestReview = viewModel.longestTextFromReviews,
              let firstItem = highlightGroups.first else { return }

        let highlightLabelWidth = FakespotUtils.widthOfString(
            longestReview,
            usingFont: FXFontStyles.Bold.subheadline.scaledFont()
        )

        // Calculates the width available for the highlights group view within the view's current bounds,
        // considering safe area insets, image height constraints, and horizontal spacing.
        let highlightsGroupViewWidth = (bounds.width - safeAreaEdgeInsets.left * 2) -
                                       (firstItem.imageHeightConstraint?.constant ?? UX.groupImageSize) -
                                       (2 * UX.contentHorizontalSpace)

        let areMoreThanTwoLines = highlightLabelWidth > highlightsGroupViewWidth

        if areMoreThanTwoLines {
            contentStackView.addArrangedSubview(dividerView)
            contentStackView.addArrangedSubview(moreButton)
        } else {
            contentStackView.removeArrangedView(dividerView)
            contentStackView.removeArrangedView(moreButton)
        }
        updateHighlights(areMoreThanTwoLines)
    }

    @objc
    private func showMoreAction() {
        isShowingPreview = !isShowingPreview
        updateHighlights()
        updateExpandState()
        viewModel?.onExpandStateChanged?(isShowingPreview ? .collapsed : .expanded)
    }

    func updateExpandState() {
        guard let viewModel else { return }

        let moreButtonViewModel = SecondaryRoundedButtonViewModel(
            title: isShowingPreview ? viewModel.moreButtonTitle : viewModel.lessButtonTitle,
            a11yIdentifier: isShowingPreview ? viewModel.moreButtonA11yId : viewModel.lessButtonA11yId
        )
        moreButton.configure(viewModel: moreButtonViewModel)

        if !isShowingPreview {
            recordTelemetry()
        }
    }

    private func updateHighlights(_ areMoreThanTwoLines: Bool = true) {
        highlightStackView.removeAllArrangedViews()
        let shouldShowFade = isShowingPreview && areMoreThanTwoLines && viewModel?.shouldShowFadeInPreview ?? false
        let groupsToShow = isShowingPreview ? highlightPreviewGroups : highlightGroups

        for (_, group) in groupsToShow.enumerated() {
            highlightStackView.addArrangedSubview(group)
            group.showPreview(shouldShowFade)
        }
    }

    private func recordTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingRecentReviews)
    }
}
