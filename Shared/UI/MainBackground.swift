//
//  MainBackground.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/1.
//

import SwiftUI

/// 漸層背景，柔和溫暖的粉紫 → 蜜桃 → 奶油
struct MainBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "#DCCBF6"), // 淡紫
                Color(hex: "#F7C7DA"), // 粉紅
                Color(hex: "#FFD7B3"), // 蜜桃
                Color(hex: "#FFF1D9")  // 奶油
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

