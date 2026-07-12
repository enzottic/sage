//
//  SpendingProjection.swift
//  SageKit
//
//  End-of-period spending projection ("on pace to spend …").
//

import Foundation

/// Projects total spend for the current period.
///
/// Rather than the naive `spentSoFar ÷ fractionElapsed` extrapolation — which
/// explodes early in a period when a large recurring charge posts on day one —
/// this model:
///   1. Treats already-scheduled recurring bills as deterministic (added at their
///      real amount, never multiplied).
///   2. Extrapolates only the *variable* (non-recurring) spend, shrinking the
///      current-period daily rate toward a historical baseline. Early in the
///      period history dominates; late in the period actuals dominate.
///
/// Pure and dependency-free so it can be unit-tested and reused across targets.
public enum SpendingProjection {

    private static let secondsPerDay = 86_400.0

    /// - Parameters:
    ///   - periodExpenses: expenses recorded so far within the current period,
    ///     already filtered to the active category/tag.
    ///   - recurringRules: active recurring rules matching the same filter.
    ///   - interval: the current period's date interval.
    ///   - now: the current moment (defaults to `.now`).
    ///   - historicalVariableTotals: variable (non-recurring) spend totals for
    ///     recent *complete* periods of the same length. Empty → falls back to
    ///     the current period's own pace.
    ///   - calendar: calendar used for recurrence stepping.
    /// - Returns: projected total spend for the full period.
    public static func project(
        periodExpenses: [Expense],
        recurringRules: [RecurringExpenseRule],
        interval: DateInterval,
        now: Date = .now,
        historicalVariableTotals: [Double],
        calendar: Calendar = .current
    ) -> Double {
        let spentSoFar = periodExpenses.total
        guard interval.duration > 0, now >= interval.start else { return spentSoFar }

        let clampedNow = min(now, interval.end)
        let daysTotal = max(1.0, interval.duration / secondsPerDay)
        // Clamp elapsed to [1, daysTotal] so a charge on day one doesn't divide by ~0.
        let daysElapsed = min(daysTotal, max(1.0, clampedNow.timeIntervalSince(interval.start) / secondsPerDay))
        let daysRemaining = max(0.0, daysTotal - daysElapsed)

        // Confidence in the current period's own pace (0 early → 1 at period end).
        let f = daysElapsed / daysTotal

        // Recorded spend split into recurring (already counted) vs variable.
        let recurringSoFar = periodExpenses.filter { $0.recurringExpenseId != nil }.total
        let variableSoFar = max(0, spentSoFar - recurringSoFar)
        let currentVariableDailyRate = variableSoFar / daysElapsed

        let historicalDailyRate: Double
        if historicalVariableTotals.isEmpty {
            historicalDailyRate = currentVariableDailyRate
        } else {
            let average = historicalVariableTotals.reduce(0, +) / Double(historicalVariableTotals.count)
            historicalDailyRate = average / daysTotal
        }

        let blendedVariableRate = f * currentVariableDailyRate + (1 - f) * historicalDailyRate
        let projectedVariableRemainder = blendedVariableRate * daysRemaining

        let futureRecurring = futureRecurringTotal(
            rules: recurringRules,
            after: now,
            through: interval.end,
            calendar: calendar
        )

        return spentSoFar + projectedVariableRemainder + futureRecurring
    }

    /// Sum of recurring-rule occurrences scheduled after `start` and on/before `end`
    /// that have not yet been generated into `Expense` records.
    ///
    /// Steps each rule's cadence from the same anchor the generator uses
    /// (`lastGeneratedDate`, else the day before `startDate`) so the occurrences
    /// counted here match those the generator will later create.
    private static func futureRecurringTotal(
        rules: [RecurringExpenseRule],
        after start: Date,
        through end: Date,
        calendar: Calendar
    ) -> Double {
        guard start < end else { return 0 }
        var total = 0.0

        for rule in rules {
            let ruleEnd = rule.endDate.map { min($0, end) } ?? end
            guard start < ruleEnd else { continue }

            let anchor = rule.lastGeneratedDate
                ?? calendar.date(byAdding: .day, value: -1, to: rule.startDate)
                ?? rule.startDate

            var next = rule.frequency.nextOccurrence(after: anchor, calendar: calendar)
            var iterations = 0
            while let occurrence = next, occurrence <= ruleEnd, iterations < 10_000 {
                if occurrence > start {
                    total += rule.amount
                }
                next = rule.frequency.nextOccurrence(after: occurrence, calendar: calendar)
                iterations += 1
            }
        }

        return total
    }
}
