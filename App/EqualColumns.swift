import SwiftUI

struct EqualColumns: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let columnWidth = columnWidth(totalWidth: width, subviews: subviews)
        let height =
            subviews
            .map { $0.sizeThatFits(ProposedViewSize(width: columnWidth, height: proposal.height)).height }
            .max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columnWidth = columnWidth(totalWidth: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + CGFloat(index) * columnWidth, y: bounds.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: columnWidth, height: bounds.height)
            )
        }
    }

    private func columnWidth(totalWidth: CGFloat, subviews: Subviews) -> CGFloat {
        subviews.isEmpty ? 0 : totalWidth / CGFloat(subviews.count)
    }
}
