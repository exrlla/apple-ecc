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
                
                // Planted birds
                ForEach(plots) { plot in
                    Image(plot.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: IsoMath.tileWidth * 0.8)
                        .offset(IsoMath.screenOffset(row: plot.row, col: plot.col))
                        .offset(y: (IsoMath.tileArtHeight - IsoMath.tileHeight) / 2 - 20)
                        .zIndex(IsoMath.zIndex(row: plot.row, col: plot.col) + 500)
                }
            }
            .position(x: geo.size.width / 2, y: geo.size.height * 0.3)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GardenView()
        .modelContainer(for: [GardenPlot.self], inMemory: true)
}
