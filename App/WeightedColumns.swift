import SwiftUI

nonisolated struct ColumnWeight: LayoutValueKey {
    static let defaultValue: CGFloat = 1
}

struct WeightedColumns: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let height =
            zip(subviews, columnWidths(totalWidth: width, subviews: subviews))
            .map { subview, columnWidth in
                subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: proposal.height)).height
            }
            .max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for (subview, columnWidth) in zip(subviews, columnWidths(totalWidth: bounds.width, subviews: subviews)) {
            subview.place(
                at: CGPoint(x: x, y: bounds.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: columnWidth, height: bounds.height)
            )
            x += columnWidth
        }
    }

    private func columnWidths(totalWidth: CGFloat, subviews: Subviews) -> [CGFloat] {
        let weights = subviews.map { $0[ColumnWeight.self] }
        let totalWeight = weights.reduce(0, +)
        guard totalWeight > 0 else {
            return weights.map { _ in 0 }
        }
        return weights.map { totalWidth * $0 / totalWeight }
    }
}
