//
//  ArcProgressGauge.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/14/26.
//

import SwiftUI

/// A half-circle gauge that fills clockwise from the left end. `content` is laid
/// out in the well under the arc.
struct ArcProgressGauge<Content: View>: View {
    let progress: Double
    var tint: Color = .sage
    /// Stroke thickness as a fraction of the gauge's width, so the arc keeps the
    /// same visual weight as it scales. Clamped by `lineWidthRange`.
    var lineWidthRatio: CGFloat = 0.073
    var lineWidthRange: ClosedRange<CGFloat> = 16...30
    @ViewBuilder var content: () -> Content

    private var clampedProgress: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            let lineWidth = (proxy.size.width * lineWidthRatio)
                .clamped(to: lineWidthRange)

            ZStack(alignment: .bottom) {
                ArcShape(lineWidth: lineWidth)
                    .stroke(tint.opacity(0.18), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                ArcShape(lineWidth: lineWidth)
                    .trim(from: 0, to: clampedProgress)
                    .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .animation(.easeInOut, value: clampedProgress)

                content()
                    .padding(.horizontal, lineWidth)
            }
        }
        .aspectRatio(2, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(clampedProgress, format: .percent.precision(.fractionLength(0))))
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

/// The 180° arc, swept left to right over the top. Inset by half the line width
/// so the stroke stays inside the view's bounds.
private struct ArcShape: Shape {
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let inset = lineWidth / 2
        let radius = max(min(rect.width / 2, rect.height) - inset, 0)
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY - inset),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(360),
            clockwise: false
        )
        return path
    }
}

#Preview {
    VStack(spacing: 32) {
        ArcProgressGauge(progress: 0.44) {
            Text("44%")
                .font(.largeTitle)
                .fontWeight(.bold)
        }

        ArcProgressGauge(progress: 1, tint: .red) {
            Text("Over")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }
    .padding()
}
