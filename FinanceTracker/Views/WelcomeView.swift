//
//  WelcomeView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/21/25.
//

import SwiftUI
import WidgetKit

struct WelcomeView: View {
    @Environment(AppConfiguration.self) var config

    @AppStorage("hasOpenedAppOnce") var hasOpenedAppOnce: Bool = false

    @State private var currentStep: OnboardingStep = .welcome
    @State private var monthlyIncome: String = ""
    @State private var needsPercent: Double = 50
    @State private var wantsPercent: Double = 30
    @FocusState private var isInputFocused: Bool

    enum OnboardingStep {
        case welcome
        case budget
        case allocation
        case complete
    }

    var savingsPercent: Double {
        let calculated = 100 - needsPercent - wantsPercent
        return round(max(0, calculated))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ui.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $currentStep) {
                        welcomePage
                            .tag(OnboardingStep.welcome)

                        budgetPage
                            .tag(OnboardingStep.budget)

                        allocationPage
                            .tag(OnboardingStep.allocation)

                        completePage
                            .tag(OnboardingStep.complete)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                }
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isInputFocused = false
                    }
                }
            }
        }
    }

    // MARK: - Welcome Page

    var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "chart.pie.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ui.want, Color.ui.need, Color.ui.saving],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 20)

            VStack(spacing: 12) {
                Text("Welcome to Sage")
                    .font(.system(size: 36, weight: .bold))
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "chart.bar.fill", title: "Track Expenses", description: "Monitor spending across three basic categories:wants, needs, and savings")
                FeatureRow(icon: "percent", title: "Smart Allocation", description: "Set custom budget percentages that work for you")
                FeatureRow(icon: "eye.fill", title: "Visual Insights", description: "See your budget utilization at a glance")
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentStep = .budget
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ui.sage)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Budget Page

    var budgetPage: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.ui.sage)

                Text("Set Your Monthly Budget")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Enter your total monthly spendable income")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 8) {
                TextField("0", text: $monthlyIncome)
                    .keyboardType(.numberPad)
                    .font(.system(size: 48, weight: .bold))
                    .multilineTextAlignment(.center)
                    .focused($isInputFocused)
                    .padding()
                    .background(Color.ui.cardBackground)
                    .cornerRadius(15)

                Text("\(Locale.current.currency?.identifier ?? "USD") per month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)

            Spacer()

            HStack(spacing: 15) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .welcome
                    }
                } label: {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ui.cardBackground)
                        .cornerRadius(15)
                }

                Button {
                    if let income = Int(monthlyIncome), income > 0 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentStep = .allocation
                        }
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Int(monthlyIncome) ?? 0 > 0 ? Color.ui.sage : Color.gray)
                        .cornerRadius(15)
                }
                .disabled((Int(monthlyIncome) ?? 0) <= 0)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Allocation Page

    var allocationPage: some View {
        VStack(spacing: 25) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.ui.sage)

                Text("Budget Allocation")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Customize your wants, needs, and savings percentages")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 25) {
                AllocationSlider(
                    title: "Wants",
                    percentage: $wantsPercent,
                    color: Color.ui.want,
                    icon: "cart.fill"
                )

                AllocationSlider(
                    title: "Needs",
                    percentage: $needsPercent,
                    color: Color.ui.need,
                    icon: "house.fill"
                )

                HStack {
                    Image(systemName: "banknote.fill")
                        .foregroundStyle(.teal)
                        .frame(width: 30)

                    Text("Savings")
                        .font(.headline)

                    Spacer()

                    Text("\(Int(savingsPercent))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.teal)
                }
                .padding()
                .background(Color.ui.cardBackground)
                .cornerRadius(15)
            }
            .padding(.horizontal, 40)

            if needsPercent + wantsPercent > 100 {
                Text("Total percentage cannot exceed 100%")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            HStack(spacing: 15) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .budget
                    }
                } label: {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ui.cardBackground)
                        .cornerRadius(15)
                }

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .complete
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(needsPercent + wantsPercent <= 100 ? Color.ui.sage : Color.gray)
                        .cornerRadius(15)
                }
                .disabled(needsPercent + wantsPercent > 100)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
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

    // MARK: - Complete Page

    var completePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.green)

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Here's your budget breakdown")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 15) {
                BudgetSummaryRow(
                    title: "Monthly Budget",
                    amount: Double(Int(monthlyIncome) ?? 0),
                    color: .primary,
                    isTotal: true
                )

                Divider()
                    .padding(.vertical, 5)

                BudgetSummaryRow(
                    title: "Wants (\(Int(wantsPercent))%)",
                    amount: Double(Int(monthlyIncome) ?? 0) * (wantsPercent / 100),
                    color: Color.ui.want,
                    icon: "cart.fill"
                )

                BudgetSummaryRow(
                    title: "Needs (\(Int(needsPercent))%)",
                    amount: Double(Int(monthlyIncome) ?? 0) * (needsPercent / 100),
                    color: Color.ui.need,
                    icon: "house.fill"
                )

                BudgetSummaryRow(
                    title: "Savings (\(Int(savingsPercent))%)",
                    amount: Double(Int(monthlyIncome) ?? 0) * (savingsPercent / 100),
                    color: .teal,
                    icon: "banknote.fill"
                )
            }
            .padding(25)
            .background(Color.ui.cardBackground)
            .cornerRadius(20)
            .padding(.horizontal, 40)

            Spacer()

            HStack(spacing: 15) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .allocation
                    }
                } label: {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ui.cardBackground)
                        .cornerRadius(15)
                }

                Button {
                    completeOnboarding()
                } label: {
                    Text("Start Tracking")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ui.sage)
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helper Functions

    func completeOnboarding() {
        // Save configuration
        config.totalMonthlyIncome = Int(monthlyIncome) ?? 0
        config.needsPercent = needsPercent / 100
        config.wantsPercent = wantsPercent / 100
        config.savingsPercent = savingsPercent / 100

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()

        // Mark onboarding as complete
        withAnimation {
            hasOpenedAppOnce = true
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.ui.sage)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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

            Spacer()

            Text(amount.currencyString)
                .font(isTotal ? .title2 : .body)
                .fontWeight(isTotal ? .bold : .semibold)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    @Previewable @State var appConfig = AppConfiguration()
    WelcomeView()
        .environment(appConfig)
}
