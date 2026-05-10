//
//  ErrorAlert.swift
//  MultiMenstrualAPP
//

import SwiftUI

struct AlertError: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    init(title: String = "操作失敗", message: String) {
        self.title = title
        self.message = message
    }

    init(_ error: Error, title: String = "操作失敗") {
        self.title = title
        self.message = error.localizedDescription
    }
}

extension View {
    /// Bind an `@State var alertError: AlertError?` to surface the error
    /// as a single-button info alert.
    func errorAlert(_ error: Binding<AlertError?>) -> some View {
        alert(
            error.wrappedValue?.title ?? "錯誤",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { _ in
            Button("知道了", role: .cancel) {}
        } message: { value in
            Text(value.message)
        }
    }
}
