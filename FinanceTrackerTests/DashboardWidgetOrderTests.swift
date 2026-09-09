import Testing

@Suite("Dashboard widget order")
@MainActor
struct DashboardWidgetOrderTests {
    @Test
    func repairsSavedOrderWithoutLosingUserPositions() {
        let saved = ["recentExpenses", "removedWidget", "needs", "recentExpenses", "savings"]
        let resolved = DashboardWidgetID.resolvedOrder(saved, defaultOrder: DashboardWidgetID.defaultOrder(isPad: false))
        #expect(resolved == [.recentExpenses, .needs, .savings, .monthlyOverview,
                             .wants, .expenseCalendar, .mostSpentTags, .upcomingRecurring])
        #expect(Set(resolved) == Set(DashboardWidgetID.allCases))
    }

    @Test(arguments: [false, true])
    func missingOrObsoletePreferencesUseDeviceDefault(isPad: Bool) {
        #expect(DashboardWidgetID.resolvedOrder([], defaultOrder: DashboardWidgetID.defaultOrder(isPad: isPad)) == DashboardWidgetID.defaultOrder(isPad: isPad))
        #expect(DashboardWidgetID.resolvedOrder(["obsolete"], defaultOrder: DashboardWidgetID.defaultOrder(isPad: isPad)) == DashboardWidgetID.defaultOrder(isPad: isPad))
    }
}
