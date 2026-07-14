//
//  StreakCalculator.swift
//  AppleECC
//

import Foundation

enum StreakCalculator {
    
    /// Consecutive days (walking backward from today) that have at least one
    /// sighting, stopping at the first gap.
    static func activeStreakDates(sightings: [Sighting], calendar: Calendar = .current) -> Set<Date> {
        
        func sightingsExist(on day: Date) -> Bool {
            let start = calendar.startOfDay(for: day)
            guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return false }
            return sightings.contains { $0.capturedAt >= start && $0.capturedAt < end }
        }
        
        var streakDays: Set<Date> = []
        var cursor = calendar.startOfDay(for: Date())
        
        // If today has nothing yet, the streak is still alive through yesterday.
        if !sightingsExist(on: cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                return []
            }
            cursor = yesterday
        }
        
        while sightingsExist(on: cursor) {
            streakDays.insert(cursor)
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        
        return streakDays
    }
    
    static func currentStreak(sightings: [Sighting], calendar: Calendar = .current) -> Int {
        activeStreakDates(sightings: sightings, calendar: calendar).count
    }
}
