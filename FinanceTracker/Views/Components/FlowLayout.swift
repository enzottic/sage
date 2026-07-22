//
//  FlowLayout.swift
//  FinanceTracker
//

import SwiftUI

/// Lays subviews out left to right, wrapping to a new row whenever the next subview would
/// overflow the proposed width. Used for chip-style content whose count isn't known up front.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    /// How each row is positioned within the available width. `.center` suits standalone
    /// chip clouds; `.leading` lines rows up with surrounding form content.
    var alignment: HorizontalAlignment = .center

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { row in row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(0, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            let rowWidth = row.map { $0.sizeThatFits(.unspecified).width }.reduce(0) { $0 + $1 + spacing } - spacing
            var x = alignment == .leading ? bounds.minX : bounds.minX + (bounds.width - rowWidth) / 2
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, !rows[rows.endIndex - 1].isEmpty {
                rows.append([subview])
                rowWidth = size.width + spacing
            } else {
                rows[rows.endIndex - 1].append(subview)
                rowWidth += size.width + spacing
            }
        }
        return rows
    }
}
