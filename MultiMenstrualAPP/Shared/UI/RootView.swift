//
//  RootView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/25.
//

import SwiftUI

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        withAnimation(.easeInOut) { showSplash = false }
                    }
            } else {
                AppRootView()
            }
        }
    }
}
