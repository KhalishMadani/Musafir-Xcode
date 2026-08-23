//
//  MusafirTheme.swift
//  Musafir-Xcode
//
//  Colors and metrics lifted from the Figma layouts in Design/.
//

import SwiftUI

enum MusafirTheme {
    /// Brand purple. Wordmark, markers, card outline in light mode. #AF52DE
    static let accent = Color(red: 175 / 255, green: 82 / 255, blue: 222 / 255)

    /// Prayer-space card fill: pale lavender on light, solid purple on dark.
    /// #F7F4FF / #7157C3
    static let cardFill = dynamic(
        light: UIColor(red: 247 / 255, green: 244 / 255, blue: 255 / 255, alpha: 1),
        dark: UIColor(red: 113 / 255, green: 87 / 255, blue: 195 / 255, alpha: 1)
    )

    /// Card outline: brand purple on light, muted lilac on dark. #AF52DE / #CBB8D5
    static let cardStroke = dynamic(
        light: UIColor(red: 175 / 255, green: 82 / 255, blue: 222 / 255, alpha: 1),
        dark: UIColor(red: 203 / 255, green: 184 / 255, blue: 213 / 255, alpha: 1)
    )

    /// Title and icon on a card. Black on the pale fill, white on the purple fill.
    static let cardLabel = dynamic(light: .black, dark: .white)

    /// Distance line under the card title.
    static let cardSecondaryLabel = dynamic(
        light: UIColor(white: 0.45, alpha: 1),
        dark: UIColor(white: 1, alpha: 0.85)
    )

    // MARK: - Metrics

    static let cardWidth: CGFloat = 193
    static let cardHeight: CGFloat = 57
    static let cardCornerRadius: CGFloat = 13.5
    /// Two cards plus their gutters fill the 402pt screen exactly, so the second
    /// card is clipped at the trailing edge just like the mockup.
    static let cardSpacing: CGFloat = 8
    static let recenterButtonSize: CGFloat = 50

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}
