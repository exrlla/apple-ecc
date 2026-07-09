//
//  AppleECCApp.swift
//  AppleECC
//
//  Created by Apple on 6/29/26.
//

import SwiftUI
import SwiftData

@main
struct AppleECCApp: App {
    @StateObject private var accessibilitySettings = AccessibilitySettings()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(accessibilitySettings)
        }

        .modelContainer(for: [Sighting.self, GardenPlot.self])

    }
}
