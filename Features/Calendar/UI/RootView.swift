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
//        .onChange(of: scenePhase) { newPhase in
//            if newPhase == .active {
//                showSplash = true
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                    withAnimation(.easeInOut) {
//                        showSplash = false
//                    }
//                }
//            }
//        }
//        .onChange(of: scenePhase) { newPhase in
//            if newPhase == .active {
//                showSplash = true
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                    withAnimation(.easeInOut) {
//                        showSplash = false
//                    }
//                }
//            }
//        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut) {
                    showSplash = false
                }
            }
        }
    }
}

