import FoldableGrid
import SwiftUI

/// `FoldableRow`: rows of equal cells — a month of days, and a week of bars. On an iPhone Duo held
/// like a book, each row parts at the crease: the days before it share one half and the rest the
/// other, so no date and no bar is folded in half, and every row parts at the same place so the
/// columns stay lined up.
struct CalendarScreen: View {
    @State private var selected = Calendar.current.component(.day, from: .now)

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    month
                    week
                }
                .padding()
            }
            .navigationTitle(title)
        }
    }

    private var title: String {
        Date.now.formatted(
            .dateTime
                .month(.wide)
                .year()
        )
    }

    // MARK: - The month

    private var month: some View {
        VStack(spacing: 6) {
            FoldableRow(spacing: 4) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                FoldableRow(spacing: 4) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        DayCell(
                            day: day,
                            isSelected: day == selected
                        ) {
                            if let day {
                                selected = day
                            }
                        }
                    }
                }
            }
        }
    }

    /// The weekday initials, starting on the locale's first day of the week.
    private var weekdays: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        return (0..<7)
            .map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
    }

    /// This month's days in weeks of seven, nil where a week runs into the month before or after.
    private var weeks: [[Int?]] {
        guard
            let interval = calendar.dateInterval(of: .month, for: .now),
            let days = calendar.range(of: .day, in: .month, for: .now)
        else { return [] }
        let first = calendar.component(.weekday, from: interval.start)
        let leading = (first - calendar.firstWeekday + 7) % 7
        let blanks: [Int?] = Array(repeating: nil, count: leading)
        let cells = blanks + days.map { Optional($0) }
        let trailing = (7 - cells.count % 7) % 7
        let padded = cells + Array(repeating: nil, count: trailing)
        return stride(from: 0, to: padded.count, by: 7)
            .map { Array(padded[$0..<$0 + 7]) }
    }

    // MARK: - The week

    private var week: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STEPS THIS WEEK")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            FoldableRow(alignment: .bottom, spacing: 8) {
                ForEach(
                    Array(steps.enumerated()),
                    id: \.offset
                ) { index, count in
                    Bar(
                        label: weekdays[index],
                        value: count,
                        peak: steps.max() ?? 1
                    )
                }
            }
            .frame(height: 160)
        }
    }

    private let steps = [6_200, 8_900, 4_300, 11_200, 7_600, 12_800, 3_900]
}

private struct DayCell: View {
    let day: Int?
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            Text(day.map(String.init) ?? "")
                .font(.body.monospacedDigit())
                .frame(
                    maxWidth: .infinity,
                    minHeight: 44
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    isSelected ? Color.accentColor : Color.clear,
                    in: RoundedRectangle(cornerRadius: 10)
                )
        }
        .buttonStyle(.plain)
        .disabled(day == nil)
    }
}

private struct Bar: View {
    let label: String
    let value: Int
    let peak: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(value.formatted(.number.notation(.compactName)))
                .font(.caption2)
                .foregroundStyle(.secondary)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.gradient)
                .frame(height: 110 * CGFloat(value) / CGFloat(max(peak, 1)))
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Calendar") {
    CalendarScreen()
}
