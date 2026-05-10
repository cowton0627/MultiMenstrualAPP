//
//  MainBackground.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/1.
//

import SwiftUI

enum AppTheme {
    static let accent = Color(hex: "#D8647C")
    static let prediction = Color.orange

    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)
            : UIColor(red: 1.00, green: 0.97, blue: 0.95, alpha: 1)
    })

    static let elevatedBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.12, blue: 0.13, alpha: 1)
            : UIColor.white
    })

    static let fieldBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.17, blue: 0.18, alpha: 1)
            : UIColor(white: 1, alpha: 0.72)
    })

    static let subtleStroke = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.10)
            : UIColor(white: 1, alpha: 0.52)
    })

    static let softShadow = Color.black.opacity(0.06)

    static let cardCornerRadius: CGFloat = 8
}

extension View {
    /// Standard card surface: regularMaterial fill, 8-pt corner, subtle stroke.
    func cardSurface() -> some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius,
                                     style: .continuous)
        return background(.regularMaterial, in: shape)
            .overlay(shape.stroke(AppTheme.subtleStroke, lineWidth: 1))
    }

    /// Card surface with the soft drop shadow used on top-level rows.
    func elevatedCardSurface() -> some View {
        cardSurface()
            .shadow(color: AppTheme.softShadow, radius: 14, x: 0, y: 8)
    }
}

/// App-wide soft background with a warmer system feel.
struct MainBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.background

            LinearGradient(
                colors: [
                    colorScheme == .dark ? Color(hex: "#2A1D22") : Color(hex: "#FFF8F5"),
                    colorScheme == .dark ? Color(hex: "#1B2020") : Color(hex: "#FFE8DF"),
                    colorScheme == .dark ? Color(hex: "#111516") : Color(hex: "#F4F8F4")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(colorScheme == .dark ? 0.78 : 0.9)

            LinearGradient(
                colors: [
                    (colorScheme == .dark ? Color.black : Color.white).opacity(0.72),
                    Color.clear,
                    (colorScheme == .dark ? Color(hex: "#182623") : Color(hex: "#D9EFE6")).opacity(0.38)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
