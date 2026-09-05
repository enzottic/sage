import Foundation

public enum AmountInput {
    public static func text(for amount: Double, locale: Locale = .current) -> String {
        amount.formatted(.number.locale(locale).grouping(.never).precision(.fractionLength(0...16)))
    }

    public static func parse(_ text: String, locale: Locale = .current) -> Double? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: locale.groupingSeparator ?? ",", with: "")
            .replacingOccurrences(of: locale.decimalSeparator ?? ".", with: ".")
        var digits = ""
        for character in normalized {
            if let value = character.wholeNumberValue, (0...9).contains(value) {
                digits.append(String(value))
            } else if character == "." || character == "-" || character == "+" {
                digits.append(character)
            } else {
                return nil
            }
        }
        guard let amount = Double(digits), amount.isFinite else { return nil }
        return amount
    }
}
