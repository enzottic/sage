import SwiftUI

struct WatchBudgetBar: View {
    let total: Double
    let budget: Double
    let categories: [WatchCategorySnapshot]

    var body: some View {
        GeometryReader { geometry in
            let positiveTotal = categories.reduce(0) { $0 + max(0, $1.totalSpent) }
            let fraction = budget > 0 ? min(max(total / budget, 0), 1) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(.secondary.opacity(0.22))
                HStack(spacing: 1) {
                    ForEach(categories.filter { $0.totalSpent > 0 }) { category in
                        Rectangle()
                            .fill(category.color.color)
                            .frame(width: max(0, geometry.size.width * fraction * category.totalSpent / max(positiveTotal, 1) - 1))
                    }
                }
                .clipShape(Capsule())
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}

struct WatchBudgetRemaining: View {
    let spent: Double
    let budget: Double
    let currencyCode: String
    var isSavings = false

    var body: some View {
        if budget <= 0 {
            Text(isSavings ? "No savings target" : "No budget set")
        } else if isSavings {
            if spent >= budget {
                Text("Target reached")
            } else {
                Text("\((budget - spent).formatted(.currency(code: currencyCode))) to target")
            }
        } else if spent > budget {
            Text("\((spent - budget).formatted(.currency(code: currencyCode))) over budget")
        } else {
            Text("\((budget - spent).formatted(.currency(code: currencyCode))) left")
        }
    }
}
