//
//  GardenView.swift
//  AppleECC
//

import SwiftUI
import SwiftData

struct GardenView: View {
    
    @Query private var plots: [GardenPlot]

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
                            isPlant: PlantAsset.allAssetNames.contains(plot.assetName)
                        )
                    }
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.5)
                
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
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Plot sprite with sporadic hop animation

struct PlotSpriteView: View {
    let plot: GardenPlot
    let isPlant: Bool
    
    @State private var hopOffset: CGFloat = 0
    @State private var hopTask: Task<Void, Never>?
    
    var body: some View {
        Image(plot.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: IsoMath.tileWidth * (isPlant ? 1.3 : 0.8))
            .offset(IsoMath.screenOffset(row: plot.row, col: plot.col))
            .offset(y: (IsoMath.tileArtHeight - IsoMath.tileHeight) / 2 - 20)
            .offset(y: hopOffset)
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
        .modelContainer(for: [GardenPlot.self], inMemory: true)
}
