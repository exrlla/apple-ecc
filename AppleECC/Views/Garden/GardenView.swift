//
//  GardenView.swift
//  AppleECC
//

import SwiftUI
import SwiftData

struct GardenView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    @Query private var plots: [GardenPlot]
    @Query private var sightings: [Sighting]
    
    @State private var gardenHover = false
    @State private var selectedSighting: Sighting?
    
    // Watering
    @State private var isWatering = false
    @State private var wateringTask: Task<Void, Never>?

    private var isWateringCanUnlocked: Bool {
        StreakCalculator.currentStreak(sightings: sightings) >= 3
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Image("background_day_other")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                // Garden content
                ZStack {
                    // Ground layer — fixed 6x6 diamond
                    ForEach(0..<GardenLayout.gridSize, id: \.self) { row in
                        ForEach(0..<GardenLayout.gridSize, id: \.self) { col in
                            Image(GardenLayout.assetName(row: row, col: col))
                                .resizable()
                                .frame(width: IsoMath.tileWidth, height: IsoMath.tileArtHeight)
                                .offset(IsoMath.screenOffset(row: row, col: col))
                                .offset(y: (IsoMath.tileArtHeight - IsoMath.tileHeight) / 2)
                                .zIndex(IsoMath.zIndex(row: row, col: col))
                        }
                    }
                    
                    // Planted species (birds + plants)
                    ForEach(plots) { plot in
                        PlotSpriteView(
                            plot: plot,
                            isPlant: PlantAsset.allAssetNames.contains(plot.assetName),
                            onTap: { handleTap(on: plot) }
                        )
                    }
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.5)
                .offset(y: gardenHover ? -6 : 6)
                .animation(
                    accessibilitySettings.reduceMotion ? nil :
                            .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                    value: gardenHover
                )
                .onAppear {
                    gardenHover = true
                }
                
                // Header text
                VStack {
                    ZStack {
                        Text("See the world hiding in plain sight.")
                            .offset(x: -0.6, y: 0)
                        
                        Text("See the world hiding in plain sight.")
                            .offset(x: 0.6, y: 0)
                    }
                    .font(.custom("Geist Pixel", size: 18))
                    .fontWeight(.heavy)
                    .foregroundStyle(Color(hex: "46351D"))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 260)
                    
                    Spacer()
                }
                
                // Watering can button — top right (unlocked at 3-day streak)
                if isWateringCanUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                startWatering()
                            } label: {
                                Image("watering_can_color")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                                    .padding(8)
                                    .background(.white.opacity(0.65))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isWatering)
                            .padding(.trailing, 20)
                            .padding(.top, 64)
                        }
                        Spacer()
                    }
                }
                
                // Water droplet animation overlay
                if isWatering {
                    WateringOverlay(screenSize: geo.size)
                        .transition(.opacity)
                        .zIndex(1000)
                }
            }
        }
        .ignoresSafeArea()
        .sheet(item: $selectedSighting) { sighting in
            SpeciesDetailView(sighting: sighting)
        }
        .onDisappear {
            wateringTask?.cancel()
            wateringTask = nil
        }
    }
    
    // MARK: - Watering
    
    private func startWatering() {
        guard !isWatering, !accessibilitySettings.reduceMotion else { return }
        
        withAnimation(.easeIn(duration: 0.2)) {
            isWatering = true
        }
        
        wateringTask?.cancel()
        wateringTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.4)) {
                isWatering = false
            }
        }
    }
    
    // MARK: - Tap handling
    
    private func handleTap(on plot: GardenPlot) {
        if let sighting = sighting(for: plot) {
            selectedSighting = sighting
        } else {
            print("🔴 No sighting found for plot: \(plot.speciesName.isEmpty ? plot.assetName : plot.speciesName)")
        }
    }
    
    // Find the most recent sighting matching this plot
    private func sighting(for plot: GardenPlot) -> Sighting? {
        // New plots: match on stored species name
        if !plot.speciesName.isEmpty {
            return sightings
                .filter { $0.speciesName == plot.speciesName }
                .max(by: { $0.capturedAt < $1.capturedAt })
        }
        
        // Old plots (placed before speciesName existed): reverse-match via asset lookup
        return sightings
            .filter {
                BirdAsset.assetName(for: $0.speciesName) == plot.assetName
                || PlantAsset.assetName(for: $0.speciesName) == plot.assetName
            }
            .max(by: { $0.capturedAt < $1.capturedAt })
    }
}

// MARK: - Watering overlay

struct WateringOverlay: View {
    let screenSize: CGSize
    private let dropletCount = 45
    
    var body: some View {
        ZStack {
            ForEach(0..<dropletCount, id: \.self) { _ in
                FallingDroplet(screenSize: screenSize)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct FallingDroplet: View {
    let screenSize: CGSize
    
    @State private var falling = false
    
    // Randomized once per droplet
    @State private var xFraction = CGFloat.random(in: 0.02...0.98)
    @State private var delay = Double.random(in: 0...1.6)
    @State private var duration = Double.random(in: 0.8...1.4)
    @State private var size = CGFloat.random(in: 10...20)
    @State private var opacity = Double.random(in: 0.6...0.95)
    
    var body: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: size))
            .foregroundStyle(Color(hex: "5AB1BB").opacity(opacity))
            .position(
                x: xFraction * screenSize.width,
                y: falling ? screenSize.height + 40 : -40
            )
            .animation(
                .easeIn(duration: duration)
                .delay(delay)
                .repeatForever(autoreverses: false),
                value: falling
            )
            .onAppear {
                falling = true
            }
    }
}

// MARK: - Plot sprite with sporadic hop animation

struct PlotSpriteView: View {
    let plot: GardenPlot
    let isPlant: Bool
    var onTap: (() -> Void)? = nil
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    @State private var hopOffset: CGFloat = 0
    @State private var hopTask: Task<Void, Never>?
    
    var body: some View {
        Image(plot.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: IsoMath.tileWidth * (isPlant ? 1.3 : 0.8))
            .offset(y: hopOffset)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
            .offset(IsoMath.screenOffset(row: plot.row, col: plot.col))
            .offset(y: (IsoMath.tileArtHeight - IsoMath.tileHeight) / 2 - 20)
            .zIndex(IsoMath.zIndex(row: plot.row, col: plot.col) + 500)
            .onAppear {
                guard !isPlant else { return }
                startHopping()
            }
            .onDisappear {
                hopTask?.cancel()
                hopTask = nil
            }
    }
    
    private func startHopping() {
        hopTask?.cancel()
        hopTask = Task {
            while !Task.isCancelled {
                // Wait a random 5–10 seconds between hop bursts
                let waitSeconds = Double.random(in: 5...10)
                try? await Task.sleep(for: .seconds(waitSeconds))
                if Task.isCancelled { return }
                
                // Do 2–3 quick little hops
                let hopCount = Int.random(in: 2...3)
                for _ in 0..<hopCount {
                    withAnimation(.easeOut(duration: 0.12)) {
                        hopOffset = -5
                    }
                    try? await Task.sleep(for: .seconds(0.12))
                    
                    withAnimation(.easeIn(duration: 0.12)) {
                        hopOffset = 0
                    }
                    try? await Task.sleep(for: .seconds(0.18))
                }
            }
        }
    }
}

#Preview {
    GardenView()
        .modelContainer(for: [GardenPlot.self, Sighting.self], inMemory: true)
        .environmentObject(AccessibilitySettings())
}
