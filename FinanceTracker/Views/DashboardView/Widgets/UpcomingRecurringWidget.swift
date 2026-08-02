//
//  UpcomingRecurringWidget.swift
//  FinanceTracker
//
//  Created by Codex on 7/31/26.
//

import SwiftUI
import SwiftData
import SageKit

struct UpcomingRecurringWidget: View {
    private struct UpcomingRule: Identifiable {
        let rule: RecurringExpenseRule
        let date: Date

        var id: UUID { rule.id }
    }

    @Query private var recurringRules: [RecurringExpenseRule]

    private let calendar = Calendar.current

    private var upcomingRules: [UpcomingRule] {
        recurringRules
            .compactMap { rule in
                guard let date = nextOccurrence(for: rule) else { return nil }
                return UpcomingRule(rule: rule, date: date)
            }
            .sorted { $0.date < $1.date }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        if !upcomingRules.isEmpty {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(upcomingRules) { upcoming in
                            UpcomingRecurringCard(rule: upcoming.rule, nextDate: upcoming.date)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } header: {
                Text("Upcoming Expenses")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
    }

    private func nextOccurrence(for rule: RecurringExpenseRule) -> Date? {
        let next: Date?

        if let lastGeneratedDate = rule.lastGeneratedDate {
            next = rule.frequency.nextOccurrence(after: lastGeneratedDate, calendar: calendar)
        } else {
            next = firstOccurrence(onOrAfter: .now, for: rule)
        }

        guard let next, rule.endDate.map({ next <= $0 }) ?? true else { return nil }
        return next
    }

    private func firstOccurrence(onOrAfter date: Date, for rule: RecurringExpenseRule) -> Date? {
        var occurrence = rule.startDate

        while occurrence < date {
            guard let followingOccurrence = rule.frequency.nextOccurrence(after: occurrence, calendar: calendar) else {
                return nil
            }
            occurrence = followingOccurrence
        }

        return occurrence
    }
}

private struct UpcomingRecurringCard: View {
    let rule: RecurringExpenseRule
    let nextDate: Date

    private var daysAway: Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: nextDate).day ?? 0)
    }

    private var isImminent: Bool { daysAway <= 3 }

    private var tagEmoji: String? {
        rule.tags?.first?.emoji ?? rule.tag?.emoji
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let tagEmoji {
                    Text(tagEmoji)
                        .font(.title2)
                }

                Spacer()

                Text(daysAway == 0 ? "today" : daysAway == 1 ? "1 day" : "\(daysAway)d")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isImminent ? .white : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isImminent ? Color.orange : Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(rule.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(rule.amount.currencyStringWithFraction)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding(14)
        .frame(width: 150)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    List {
        UpcomingRecurringWidget()
    }
    .environmentInjection()
}
