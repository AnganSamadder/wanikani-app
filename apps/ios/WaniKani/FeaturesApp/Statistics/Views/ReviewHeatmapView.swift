import SwiftUI

struct ReviewHeatmapView: View {
    let counts: [Date: Int]

    @State private var selectedDay: Date? = nil
    @State private var selectedCount: Int = 0
    @State private var showingPopover = false

    private let calendar = Calendar.current
    private let columns = 52
    private let rows = 7
    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 2

    // Build a 52-week grid ending today
    private var weeks: [[Date?]] {
        let today = calendar.startOfDay(for: Date())
        // Find the Sunday on or before (52 weeks ago)
        let weeksAgo = calendar.date(byAdding: .weekOfYear, value: -(columns - 1), to: today)!
        let startOfFirstWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weeksAgo))!

        var result: [[Date?]] = []
        var current = startOfFirstWeek

        for _ in 0..<columns {
            var week: [Date?] = []
            for _ in 0..<rows {
                if current <= today {
                    week.append(current)
                } else {
                    week.append(nil)
                }
                current = calendar.date(byAdding: .day, value: 1, to: current)!
            }
            result.append(week)
        }
        return result
    }

    private func colorForCount(_ count: Int) -> Color {
        switch count {
        case 0:
            return Color(.systemGray5)
        case 1...3:
            return Color.purple.opacity(0.25)
        case 4...9:
            return Color.purple.opacity(0.45)
        case 10...29:
            return Color.purple.opacity(0.70)
        default:
            return Color.purple.opacity(0.95)
        }
    }

    // Month labels: compute from weeks array
    private var monthLabels: [(index: Int, label: String)] {
        var labels: [(Int, String)] = []
        var lastMonth = -1
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        for (weekIdx, week) in weeks.enumerated() {
            if let firstDay = week.first(where: { $0 != nil }), let date = firstDay {
                let month = calendar.component(.month, from: date)
                if month != lastMonth {
                    labels.append((weekIdx, formatter.string(from: date)))
                    lastMonth = month
                }
            }
        }
        return labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Month labels
            ZStack(alignment: .topLeading) {
                Color.clear.frame(height: 16)
                ForEach(monthLabels, id: \.index) { item in
                    Text(item.label)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .offset(x: CGFloat(item.index) * (cellSize + cellSpacing))
                }
            }

            // Grid
            HStack(alignment: .top, spacing: cellSpacing) {
                ForEach(0..<columns, id: \.self) { col in
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<rows, id: \.self) { row in
                            if let date = weeks[col][row] {
                                let count = counts[date] ?? 0
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colorForCount(count))
                                    .frame(width: cellSize, height: cellSize)
                                    .onTapGesture {
                                        selectedDay = date
                                        selectedCount = count
                                        showingPopover = true
                                    }
                            } else {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.clear)
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        }
        .popover(isPresented: $showingPopover) {
            if let day = selectedDay {
                VStack(spacing: 4) {
                    Text(day, style: .date)
                        .font(.subheadline.weight(.semibold))
                    Text("\(selectedCount) review\(selectedCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .presentationCompactAdaptation(.popover)
            }
        }
    }
}
