//
//  WhatsNewSheet.swift
//  FinanceTracker
//

import SwiftUI
import SageKit

struct WhatsNewSheet: View {
    let release: WhatsNewRelease

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 36) {
                    header

                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(release.features) { feature in
                            FeatureRow(
                                icon: feature.icon,
                                title: feature.title,
                                description: feature.description,
                                tint: feature.tint
                            )
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 48)
                .padding(.bottom, 24)
            }

            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.sage)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color.sageBackground)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("What's New")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)

            Text("Version \(release.version)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            WhatsNewSheet(release: WhatsNewCatalog.releases[0])
        }
}
