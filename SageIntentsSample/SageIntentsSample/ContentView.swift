import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Siri phrases") {
                    PhraseRow("Add an expense to Sage Intent Sample", icon: "plus.circle")
                    PhraseRow("How much have I spent this month in Sage Intent Sample", icon: "chart.bar")
                    PhraseRow("How much budget do I have left this month in Sage Intent Sample", icon: "creditcard")
                    PhraseRow("Find my expenses in Sage Intent Sample", icon: "magnifyingglass")
                }

                Section("Sample setup") {
                    Label("Four App Intents in an embedded framework", systemImage: "shippingbox")
                    Label("AppIntentsPackage exposed by the host app", systemImage: "app.badge")
                    Label("SwiftData dependency registered at launch", systemImage: "cylinder")
                }
            }
            .navigationTitle("Sage Intent Sample")
        }
    }
}

private struct PhraseRow: View {
    let phrase: String
    let icon: String

    init(_ phrase: String, icon: String) {
        self.phrase = phrase
        self.icon = icon
    }

    var body: some View {
        Label(phrase, systemImage: icon)
            .textSelection(.enabled)
    }
}

