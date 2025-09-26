//
//  AnotherWarmPastelBackground.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/9.
//

import SwiftUI

public struct CalendarBackground: View {
    public init() {}
    public var body: some View {
        ZStack {
            Color.white
            Circle()
                .fill(Color.purple.opacity(0.06))
//                .frame(width: 600, height: 600)
                .offset(x: 230, y: -280)
            Circle()
                .fill(Color.pink.opacity(0.06))
//                .frame(width: 520, height: 520)
                .offset(x: -220, y: 320)
        }
        .ignoresSafeArea()
    }
}
