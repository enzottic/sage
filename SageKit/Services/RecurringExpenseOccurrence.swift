import Foundation

public enum RecurringExpenseOccurrence {
    /// Returns one stable identity for a rule occurrence on all devices.
    /// CloudKit stores dates with millisecond precision, so the scheduled date uses the same scale.
    public static func key(ruleID: UUID, scheduledDate: Date) -> String {
        let milliseconds = Int64((scheduledDate.timeIntervalSince1970 * 1_000).rounded())
        return "v1:\(ruleID.uuidString.lowercased()):\(milliseconds)"
    }
}
