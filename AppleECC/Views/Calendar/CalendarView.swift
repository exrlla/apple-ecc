//
//  CalendarView.swift
//  AppleECC
//

import SwiftUI
import SwiftData

struct CalendarView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sighting.capturedAt, order: .reverse) private var allSightings: [Sighting]

    @State private var displayedMonth: Date = Date()
    @State private var selectedDay: Date?
    @State private var showDayDetail = false

    private let calendar = Calendar.current
    private let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                monthHeader
                calendarGrid
                streakCard
            }
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showDayDetail) {
            if let day = selectedDay {
                DaySightingsSheet(day: day, sightings: sightings(on: day))
            }
        }
    }

    // MARK: - Month header

    private var monthHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.primary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button(monthName(month)) { setMonth(month) }
                        }
                    } label: {
                        pillLabel(monthName(currentMonthComponent))
                    }

                    Menu {
                        ForEach(yearRange, id: \.self) { year in
                            Button(String(year)) { setYear(year) }
                        }
                    } label: {
                        pillLabel(String(currentYearComponent))
                    }
                }

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 24)

            weekdayRow
        }
    }

    private func pillLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    private var weekdayRow: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Grid

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 14) {
            ForEach(Array(gridDates.enumerated()), id: \.offset) { _, entry in
                if let date = entry {
                    dayCell(for: date)
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    private func dayCell(for date: Date) -> some View {
        let hasSighting = !sightings(on: date).isEmpty
        let inCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        let isStreakDay = hasSighting && activeStreakDates.contains(calendar.startOfDay(for: date))

        return Button {
            guard hasSighting else { return }
            selectedDay = date
            showDayDetail = true
        } label: {
            ZStack {
                if hasSighting {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "5AB1BB").opacity(isStreakDay ? 1.0 : 0.6))
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isStreakDay ? Color.black : Color.clear, lineWidth: 2)
                        )
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                } else {
                    Text(dayNumber(date))
                        .font(.subheadline)
                        .foregroundStyle(inCurrentMonth ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary.opacity(0.4)))
                }
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
        .disabled(!hasSighting)
    }

    // MARK: - Streak card

    private var streakCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "5AB1BB"))
                    .frame(width: 56, height: 56)
                Image(systemName: "drop.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
            }

            Text("\(currentStreak)")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text("Waterdrop Streak")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Data helpers

    private func sightings(on date: Date) -> [Sighting] {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return allSightings.filter { $0.capturedAt >= start && $0.capturedAt < end }
    }

    /// Consecutive days (walking backward from today) that have at least one
    /// sighting, stopping at the first gap. Defines the highlighted streak.
    private var activeStreakDates: Set<Date> {
        var streakDays: Set<Date> = []
        var cursor = calendar.startOfDay(for: Date())

        // If today has nothing yet, the streak is still alive through yesterday.
        if sightings(on: cursor).isEmpty {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                return []
            }
            cursor = yesterday
        }

        while !sightings(on: cursor).isEmpty {
            streakDays.insert(cursor)
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streakDays
    }

    private var currentStreak: Int {
        activeStreakDates.count
    }

    // MARK: - Month math

    private var currentMonthComponent: Int {
        calendar.component(.month, from: displayedMonth)
    }

    private var currentYearComponent: Int {
        calendar.component(.year, from: displayedMonth)
    }

    private var yearRange: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((current - 5)...current)
    }

    private func monthName(_ month: Int) -> String {
        DateFormatter().shortMonthSymbols[month - 1]
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    private func setMonth(_ month: Int) {
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.month = month
        if let newDate = calendar.date(from: components) {
            displayedMonth = newDate
        }
    }

    private func setYear(_ year: Int) {
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.year = year
        if let newDate = calendar.date(from: components) {
            displayedMonth = newDate
        }
    }

    private func dayNumber(_ date: Date) -> String {
        String(calendar.component(.day, from: date))
    }

    /// Full 6-row grid for the displayed month, including leading/trailing days
    /// from adjacent months so weekday columns always line up.
    private var gridDates: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var dates: [Date?] = []
        var current = firstWeekInterval.start

        for _ in 0..<42 { // 6 weeks * 7 days covers every month layout
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }
}

// MARK: - Day detail sheet

private struct DaySightingsSheet: View {

    @Environment(\.dismiss) private var dismiss
    let day: Date
    let sightings: [Sighting]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sightings) { sighting in
                    HStack(spacing: 14) {
                        if let data = sighting.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray5))
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Image(systemName: sighting.audioURL != nil ? "waveform" : "leaf.fill")
                                        .foregroundStyle(.secondary)
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(sighting.speciesName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(sighting.speciesType == .bird ? "Bird" : (sighting.speciesType == .plant ? "Plant" : "Unknown"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(day.formatted(.dateTime.month(.wide).day().year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
