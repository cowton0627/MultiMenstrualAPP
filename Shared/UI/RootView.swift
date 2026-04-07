//
//  RootView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/25.
//

import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                MultiProfilesView()
            }
        }
        .onAppear {
            startSplash()
        }
//        .onChange(of: scenePhase) { newPhase in
//            if newPhase == .active {
//                startSplash()
//            }
//        }
    }
    
    private func startSplash() {
        showSplash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut) { showSplash = false }
        }
    }
}

