//
//  AppearancePicker.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/15/25.
//
import SwiftUI
import SageKit

struct AppearanceSettingsSection: View {
    @Environment(AppConfiguration.self) private var config

    func appearanceFill(_ appearance: Appearance) -> UIColor {
        switch appearance {
        case .light:
            return UIColor(.sageBackground).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        case .dark:
            return UIColor(.sageBackground).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        case .system: return .darkGray
        }
    }

    var body: some View {
        @Bindable var config = config
        List {
            Section {
                ForEach(Appearance.allCases, id: \.self) { appearance in
                    Button {
                        config.selectedAppearance = appearance
                    } label: {
                        HStack {
                            ZStack(alignment: .center) {
                                Rectangle()
                                    .fill(Color(uiColor: appearanceFill(appearance)))
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(10)

                                Text("Aa")
                                    .font(.title3)
                                    .foregroundStyle(appearance == .light ? .black : .white)
                            }

                            VStack(alignment: .leading) {
                                Text(appearance.rawValue).tag(appearance)
                                    .font(.title2)
                                Text(
                                    appearance == .system ? "Use the default system appearance"
                                    : "Always use a \(appearance.rawValue.lowercased()) appearance"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if config.selectedAppearance == appearance {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            } header: {
                Text("App Theme")
            }

            Section {
                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                    HStack {
                        Circle()
                            .fill(category.color(in: config.categoryColors))
                            .frame(width: 14, height: 14)
                        Text(category.rawValue)
                        Spacer()
                        switch category {
                        case .needs:
                            ColorPicker("", selection: $config.needsColor, supportsOpacity: false)
                                .labelsHidden()
                        case .wants:
                            ColorPicker("", selection: $config.wantsColor, supportsOpacity: false)
                                .labelsHidden()
                        case .savings:
                            ColorPicker("", selection: $config.savingsColor, supportsOpacity: false)
                                .labelsHidden()
                        }
                    }
                }
            } header: {
                Text("Category Colors")
            }

            Section {
                Button("Reset Category Colors") {
                    withAnimation {
                        config.resetCategoryColors()
                    }
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @Previewable @State var appConfig = AppConfiguration()
    AppearanceSettingsSection()
        .environment(appConfig)
        .preferredColorScheme(appConfig.selectedAppearance.colorScheme)
}
