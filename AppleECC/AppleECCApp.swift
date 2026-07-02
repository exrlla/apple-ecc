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
    var body: some Scene {
        WindowGroup {
            RootTabView()
            
        }
        .modelContainer(for: Sighting.self)
    }
}
