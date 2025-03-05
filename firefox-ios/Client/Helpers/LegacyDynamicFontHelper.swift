// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared

/// This is the Legacy DynamicFontHelper, please use the `DynamicFontHelper` from `BrowserKit.Common` instead.
class LegacyDynamicFontHelper: NSObject {
    private let iPadFactor: CGFloat = 1.06
    private let iPhoneFactor: CGFloat = 0.88

    static var defaultHelper: LegacyDynamicFontHelper {
        struct Singleton {
            static let instance = LegacyDynamicFontHelper()
        }
        return Singleton.instance
    }

    override init() {
        // swiftlint:disable line_length
        defaultStandardFontSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).pointSize // 14pt -> 17pt -> 23pt
        deviceFontSize = defaultStandardFontSize * (UIDevice.current.userInterfaceIdiom == .pad ? iPadFactor : iPhoneFactor)
        // swiftlint:enable line_length

        super.init()
    }

    /**
     * Starts monitoring the ContentSizeCategory changes
     */
    func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentSizeCategoryDidChange),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /**
     * Device specific
     */
    fileprivate var deviceFontSize: CGFloat

    var DeviceFont: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize, weight: UIFont.Weight.medium)
    }

    /**
     * Standard
     */
    fileprivate var defaultStandardFontSize: CGFloat

    /**
     * Reader mode
     */
    var ReaderStandardFontSize: CGFloat {
        return defaultStandardFontSize - 2
    }
    var ReaderBigFontSize: CGFloat {
        return defaultStandardFontSize + 5
    }

    func refreshFonts() {
        defaultStandardFontSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).pointSize
        deviceFontSize = defaultStandardFontSize * (UIDevice.current.userInterfaceIdiom == .pad ? iPadFactor : iPhoneFactor)
    }

    @objc
    func contentSizeCategoryDidChange(_ notification: Notification) {
        refreshFonts()
        let notification = Notification(name: .DynamicFontChanged, object: nil)
        NotificationCenter.default.post(notification)
    }

    /// Return a font that will dynamically scale up to a certain size
    /// - Parameters:
    ///   - textStyle: The desired textStyle for the font
    ///   - weight: The weight of the font (optional)
    ///   - maxSize: The maximum size the font can scale - Refer to the human interface guidelines
    ///              for more information on sizes for each style (optional)
    ///              https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography/
    /// - Returns: The UIFont with the specified font size, style and weight
    @available(*, deprecated, message: "Use DefaultDynamicFontHelper preferredFont(withTextStyle:size:weight:) instead")
    func preferredFont(
        withTextStyle textStyle: UIFont.TextStyle,
        weight: UIFont.Weight? = nil,
        maxSize: CGFloat? = nil
    ) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

        var font: UIFont
        if let weight = weight {
            font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: weight)
        } else {
            font = UIFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize)
        }

        guard let maxSize = maxSize else {
            return fontMetrics.scaledFont(for: font)
        }

        return fontMetrics.scaledFont(for: font, maximumPointSize: min(fontDescriptor.pointSize, maxSize))
    }
}
