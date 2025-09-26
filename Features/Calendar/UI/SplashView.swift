//
//  SplashView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/25.
//

import SwiftUI

struct SplashView: View {
    @State private var float = false
    
    var body: some View {
        ZStack {
            MainBackground()

            LottieView(name: "CherryBlossom", 
                       loopMode: .loop)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

//                .frame(width: 200, height: 200)
            
//            Image("wing") // 可改成自訂 feather.png
//                .resizable()
//                .scaledToFit()
//                .frame(width: 120, height: 120)
//                .foregroundColor(.white)
//                .shadow(radius: 6)
//                .rotationEffect(.degrees(float ? 10 : -10))
//                .offset(y: float ? -20 : 20)
//                .opacity(float ? 1.0 : 0.7)
//                .animation(
//                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
//                    value: float
//                )
        }
        .onAppear { float = true }
    }
}

