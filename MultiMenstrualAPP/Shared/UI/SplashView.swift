//
//  SplashView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            MainBackground()

            LottieView(name: "CherryBlossom", loopMode: .loop)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
