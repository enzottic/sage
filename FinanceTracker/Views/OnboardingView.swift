//
//  OnboardingView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/21/25.
//

import SwiftUI
import WidgetKit
import SwiftData
import SageKit

struct OnboardingView: View {
    @Environment(AppConfiguration.self) var config
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("hasOpenedAppOnce") var hasOpenedAppOnce: Bool = false

    @State private var currentStep: OnboardingStep = .welcome
    @State private var monthlyIncome: Double?
    @State private var needsPercent: Double = 50
    @State private var wantsPercent: Double = 30
    @State private var cloudSyncEnabled: Bool = false
    @State private var tagTemplates: [ExpenseTag] = ExpenseTag.suggestedTags
    @State private var selectedTagNames: Set<String> = []
    
    let mainSpacing: CGFloat = 24
    let titleBottomSpacing: CGFloat = 20
    let titleSubtitleSpacing: CGFloat = 14

    enum OnboardingStep: CaseIterable, Hashable {
        case welcome
        case budget
        case allocation
        case sync
        case tags
        case complete
    }

    var savingsPercent: Double {
        let calculated = 100 - needsPercent - wantsPercent
        return round(max(0, calculated))
    }

    init(step: OnboardingStep = .welcome) {
        _currentStep = State(initialValue: step)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sageBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $currentStep) {
                        welcomePage
                            .tag(OnboardingStep.welcome)

                        budgetPage
                            .tag(OnboardingStep.budget)

                        allocationPage
                            .tag(OnboardingStep.allocation)

                        syncPage
                            .tag(OnboardingStep.sync)

                        tagsPage
                            .tag(OnboardingStep.tags)

                        completePage
                            .tag(OnboardingStep.complete)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .scrollDisabled(true)
                    .animation(reduceMotion ? nil : .easeInOut, value: currentStep)
                }
            }

        }
    }

    // MARK: - Welcome Page

    var welcomePage: some View {
        VStack(alignment: .leading) {

            Spacer()

            Image("LaunchIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 160)
                .accessibilityHidden(true)
                .padding([.bottom], 40)


            Text("Welcome to Sage")
                .accessibilityIdentifier("onboarding-welcome-title")
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .padding([.bottom], 3)

            Text("A simple, personal expense tracking app")
                .accessibilityIdentifier("onboarding-welcome-subtitle")
                .font(.title2.bold())
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                    currentStep = .budget
                }
            } label: {
                Text("Get Started")
                    .onboardingButton()
            }
            .accessibilityIdentifier("onboarding-get-started-button")
        }
        .padding(35)
        .background(Color.sageBackground)
    }

    // MARK: - Budget Page

    var budgetPage: some View {
        VStack(spacing: mainSpacing) {
            Spacer()
            VStack {
                Text("How much do you make a month?")
                    .font(.largeTitle.bold())
                    .fontDesign(.rounded)
                    .padding([.bottom], titleBottomSpacing)

                CentsFirstCurrencyField(
                    amount: $monthlyIncome,
                    accessibilityIdentifier: "onboarding-income-field",
                    keyboardDoneAccessibilityIdentifier: "onboarding-keyboard-done-button",
                    textAlignment: .center
                )
                .fontDesign(.rounded)

                Text("\(Locale.current.currency?.identifier ?? "USD")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 15) {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .welcome
                    }
                } label: {
                    Text("Back")
                        .onboardingButton(
                            foregroundColor: .primary,
                            backgroundColor: .cardBackground
                        )
                }

                Button {
                    if let monthlyIncome, monthlyIncome > 0 {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                            currentStep = .allocation
                        }
                    }
                } label: {
                    Text("Continue")
                        .onboardingButton(
                            backgroundColor: monthlyIncome ?? 0 > 0 ? .sage : .gray
                        )
                }
                .accessibilityIdentifier("onboarding-budget-continue-button")
                .disabled((monthlyIncome ?? 0) <= 0)
            }
        }
        .padding(20)
    }

    // MARK: - Allocation Page

    var allocationPage: some View {
        VStack(spacing: mainSpacing) {
            Spacer()

            Text("How do you want to allocate your budget?")
                .font(.largeTitle.bold())
                .padding([.bottom], titleBottomSpacing)

            VStack(spacing: 25) {

                AllocationSlider(
                    title: "Needs",
                    color: .need,
                    icon: "house.fill",
                    percentage: $needsPercent
                )

                AllocationSlider(
                    title: "Wants",
                    color: .want,
                    icon: "cart.fill",
                    percentage: $wantsPercent
                )

                HStack {
                    Image(systemName: "banknote.fill")
                        .foregroundStyle(.teal)
                        .frame(width: 30)

                    Text("Savings")
                        .font(.headline)

                    Spacer()

                    Text(savingsPercent / 100, format: .percent.precision(.fractionLength(0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.teal)
                }
            }
            .padding(.horizontal, 40)
            
            Text("50/30/20 is great for most people, but feel free to customize the allocation to fit your goals.")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if needsPercent + wantsPercent > 100 {
                Text("Total percentage cannot exceed \(100, format: .percent)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            HStack(spacing: 15) {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .budget
                    }
                } label: {
                    Text("Back")
                        .onboardingButton(
                            foregroundColor: .primary,
                            backgroundColor: .cardBackground
                        )
                }

                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .sync
                    }
                } label: {
                    Text("Continue")
                        .onboardingButton(
                            backgroundColor: needsPercent + wantsPercent <= 100 ? .sage : .gray
                        )
                }
                .accessibilityIdentifier("onboarding-allocation-continue-button")
                .disabled(needsPercent + wantsPercent > 100)
            }
            .padding()
        }

        .onChange(of: needsPercent) { oldValue, newValue in
            // Ensure total doesn't exceed 100%
            if needsPercent + wantsPercent > 100 {
                let newWants = max(0, 100 - needsPercent)
                wantsPercent = round(newWants / 5) * 5
            }
        }
        .onChange(of: wantsPercent) { oldValue, newValue in
            // Ensure total doesn't exceed 100%
            if needsPercent + wantsPercent > 100 {
                let newNeeds = max(0, 100 - wantsPercent)
                needsPercent = round(newNeeds / 5) * 5
            }
        }
    }

    // MARK: - Sync Page

    var syncPage: some View {
        VStack(spacing: mainSpacing) {
            Spacer()

            VStack(spacing: titleSubtitleSpacing) {
                Text("Want to enable Sync?")
                    .font(.largeTitle.bold())
                    .fontDesign(.rounded)

                Text("You can choose to optionally sync your expenses between all your devices")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            Toggle(isOn: $cloudSyncEnabled) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
                        .foregroundStyle(.sage)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable iCloud Sync")
                            .font(.headline)
                    }
                }
            }
            .cardBackground()
            
            Text("Sync is handled via iCloud. Your data is never collected nor shared.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer()

            HStack(spacing: 15) {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .allocation
                    }
                } label: {
                    Text("Back")
                        .onboardingButton(
                            foregroundColor: .primary,
                            backgroundColor: .cardBackground
                        )
                }

                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .tags
                    }
                } label: {
                    Text("Continue")
                        .onboardingButton()
                }
                .accessibilityIdentifier("onboarding-sync-continue-button")
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Tags Page

    var tagsPage: some View {
        VStack(spacing: mainSpacing) {
            Spacer()

            VStack(spacing: titleSubtitleSpacing) {
                Text("How about some tags?")
                    .font(.largeTitle.bold())
                    .fontDesign(.rounded)

                Text("Tags help you categorize expenses further. Pick the ones you'd like to start with. You can always add or remove them later.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            HStack {
                Button("Select All") {
                    selectedTagNames = Set(tagTemplates.map(\.name))
                }
                .font(.subheadline)
                .foregroundStyle(.sage)

                Spacer()

                Button("Select None") {
                    selectedTagNames = []
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)

            TagFlowGrid(tags: tagTemplates, selectedTagNames: $selectedTagNames)
                .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 15) {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .sync
                    }
                } label: {
                    Text("Back")
                        .onboardingButton(
                            foregroundColor: .primary,
                            backgroundColor: .cardBackground
                        )
                }

                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .complete
                    }
                } label: {
                    Text("Continue")
                        .onboardingButton()
                }
                .accessibilityIdentifier("onboarding-tags-continue-button")
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Complete Page

    var completePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.green)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Here's your budget breakdown")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 15) {
                BudgetSummaryRow(
                    title: "Monthly Budget",
                    amount: monthlyIncome ?? 0,
                    color: .primary,
                    isTotal: true
                )

                Divider()
                    .padding(.vertical, 5)

                BudgetSummaryRow(
                    title: "Wants (\(Int(wantsPercent))%)",
                    amount: (monthlyIncome ?? 0) * (wantsPercent / 100),
                    color: .want,
                    icon: "cart.fill"
                )

                BudgetSummaryRow(
                    title: "Needs (\(Int(needsPercent))%)",
                    amount: (monthlyIncome ?? 0) * (needsPercent / 100),
                    color: .need,
                    icon: "house.fill"
                )

                BudgetSummaryRow(
                    title: "Savings (\(Int(savingsPercent))%)",
                    amount: (monthlyIncome ?? 0) * (savingsPercent / 100),
                    color: .teal,
                    icon: "banknote.fill"
                )
            }
            .padding(25)
            .background(.cardBackground)
            .cornerRadius(20)
            .padding(.horizontal, 40)

            Spacer()

            HStack(spacing: 15) {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .tags
                    }
                } label: {
                    Text("Back")
                        .onboardingButton(
                            foregroundColor: .primary,
                            backgroundColor: .cardBackground
                        )
                }

                Button {
                    completeOnboarding()
                } label: {
                    Text("Start Tracking")
                        .onboardingButton()
                }
                .accessibilityIdentifier("onboarding-start-tracking-button")
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helper Functions

    func completeOnboarding() {
        config.totalMonthlyIncome = Int(monthlyIncome ?? 0)
        config.needsPercent = needsPercent / 100
        config.wantsPercent = wantsPercent / 100
        config.savingsPercent = savingsPercent / 100
        config.isCloudSyncEnabled = cloudSyncEnabled
        config.markSetupComplete()

        // Fresh install — the current release's highlights are all new to this user already.
        WhatsNewStore.markCurrentVersionSeen()

        // Insert only the tags the user selected
        for tag in tagTemplates where selectedTagNames.contains(tag.name) {
            modelContext.insert(tag)
        }
        try? modelContext.save()

        WidgetCenter.shared.reloadAllTimelines()

        withAnimation(reduceMotion ? nil : .default) {
            hasOpenedAppOnce = true
        }
    }

}

// MARK: - Supporting Views

struct TagFlowGrid: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let tags: [ExpenseTag]
    @Binding var selectedTagNames: Set<String>

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.name) { tag in
                tagChip(tag)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func tagChip(_ tag: ExpenseTag) -> some View {
        let isSelected = selectedTagNames.contains(tag.name)
        Button {
            if isSelected {
                selectedTagNames.remove(tag.name)
            } else {
                selectedTagNames.insert(tag.name)
            }
        } label: {
            HStack(spacing: 6) {
                TagGlyphView(tag: tag)
                    .font(.subheadline)
                Text(tag.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(tag.uiColor).opacity(0.15) : Color(.cardBackground).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(isSelected ? Color(tag.uiColor) : Color.secondary.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .foregroundStyle(isSelected ? Color(tag.uiColor) : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .animation(reduceMotion ? nil : .spring(duration: 0.2), value: isSelected)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var tint: Color = .sage

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct BudgetSummaryRow: View {
    let title: String
    let amount: Double
    let color: Color
    var icon: String? = nil
    var isTotal: Bool = false

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(isTotal ? .title3 : .body)
                .fontWeight(isTotal ? .bold : .regular)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Text(amount.currencyString)
                .font(isTotal ? .title2 : .body)
                .fontWeight(isTotal ? .bold : .semibold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .accessibilityElement(children: .combine)
    }
}

struct OnboardingButtonModifier: ViewModifier {
    let foregroundColor: Color
    let backgroundColor: Color

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor)
            .cornerRadius(15)
    }
}

struct CardBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.cardBackground)
            .cornerRadius(15)
            .padding(.horizontal, 40)
    }
}

extension View {
    func onboardingButton(
        foregroundColor: Color = .white,
        backgroundColor: Color = .sage
    ) -> some View {
        modifier(
            OnboardingButtonModifier(
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor
            )
        )
    }
    
    func cardBackground() -> some View {
        modifier(CardBackgroundModifier())
    }
}

struct WelcomeViewPreviews: PreviewProvider {
    static var previews: some View {
        ForEach(OnboardingView.OnboardingStep.allCases, id: \.self) { step in
            OnboardingView(step: step)
                .environmentInjection()
                .previewDisplayName(String(describing: step))
        }
    }
}
