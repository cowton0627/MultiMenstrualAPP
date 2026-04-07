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
        let inline = UIFont(name: fontName, size: 17)!
        let large  = UIFont(name: fontName, size: 34)!
        let inlineFont = UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline)
        let largeFont  = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large)

        let ap = UINavigationBarAppearance()
        ap.configureWithTransparentBackground() 
        // 或 configureWithDefaultBackground()

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
            RootView()
                .environment(\.managedObjectContext,
                              persistence.container.viewContext)
//            MultiProfilesView()
//                .environment(\.managedObjectContext,
//                              persistence.container.viewContext)
//            MultiProfilesView(context: persistence.container.viewContext)
        }
    }
}
