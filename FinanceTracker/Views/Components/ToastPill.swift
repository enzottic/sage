//
//  ToastPill.swift
//  FinanceTracker
//

import SwiftUI

struct ToastPill: View {
    let toast: SageToast

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.kind == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(toast.kind == .success ? Color.green : Color.red)
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .optionalGlassEffect(in: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(toast.kind == .success ? "Success" : "Error"): \(toast.message)")
    }
}
