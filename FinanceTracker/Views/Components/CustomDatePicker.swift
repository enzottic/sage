//
//  CustomDatePicker.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/16/25.
//
import SwiftUI

struct CustomDatePicker: View {
    @State private var showPicker = true
    @Binding var selectedDate: Date
    
    var body: some View {
        Text(selectedDate.formatted(date: .complete, time: .omitted))
            .foregroundStyle(.secondary)
            .fontWeight(.bold)
            .overlay {
                GeometryReader { geometry in
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .colorMultiply(showPicker ? .clear : .white)
                }
            }
    }
}

#Preview {
    @Previewable @State var date: Date = .now
    CustomDatePicker(selectedDate: $date)
}

