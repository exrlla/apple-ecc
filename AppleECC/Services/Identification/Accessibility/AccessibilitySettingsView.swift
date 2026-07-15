//
//  AccessibilitySettingsView.swift
//  AppleECC
//
//  Created by lena on 7/9/26.
//

import SwiftUI

struct AccessibilitySettingsView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Large bold text", isOn: $accessibilitySettings.largeBoldText)
                        .font(.title3)
                    Text("Increases text size and weight throughout the app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Toggle("Colorblind-friendly colors", isOn: $accessibilitySettings.colorblindAssistMode)
                        .font(.title3)
                    Text("Swaps green accents for a blue palette that's easier to distinguish.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Toggle("Reduce motion", isOn: $accessibilitySettings.reduceMotion)
                        .font(.title3)
                    Text("Turns off the garden's hovering, hopping, and watering animations.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Label("Species descriptions in Library can be read aloud with the Listen button.", systemImage: "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Accessibility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
