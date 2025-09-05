//
//  MultiMenstrualApp.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI

@main
struct MultiMenstrualApp: App {

    let persistence = PersistenceController.shared
    
    init() {
        let fontName = "jf-openhuninn-2.1"   // 你的 PostScript name

        // 做動態字級對應的 UIFont
        let inlineBase = UIFont(name: fontName, size: 17)!
        let largeBase  = UIFont(name: fontName, size: 34)!  // 大標題預設 34pt
        let inlineFont = UIFontMetrics(forTextStyle: .headline).scaledFont(for: inlineBase)
        let largeFont  = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: largeBase)

        let ap = UINavigationBarAppearance()
        ap.configureWithTransparentBackground() // 或 configureWithDefaultBackground()

        ap.titleTextAttributes      = [.font: inlineFont]
        ap.largeTitleTextAttributes = [.font: largeFont]

        // 套到所有狀態
        UINavigationBar.appearance().standardAppearance   = ap
        UINavigationBar.appearance().scrollEdgeAppearance = ap
        UINavigationBar.appearance().compactAppearance    = ap
        UINavigationBar.appearance().compactScrollEdgeAppearance = ap
    }

    var body: some Scene {
        WindowGroup {
            MultiProfilesView(ctx: persistence.container.viewContext)
                .environment(\.managedObjectContext, 
                              persistence.container.viewContext)
        }
    }
}
