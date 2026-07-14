import SwiftData
import Foundation

enum GardenPlacement {
    
    /// Picks a random unoccupied cell and places a species sprite there.
    /// Looks up the asset across both bird and plant asset maps.
    /// Returns false if the garden is full or the species has no asset mapping.
    @discardableResult
    static func placeSpecies(speciesName: String, context: ModelContext) -> Bool {
        guard let assetName = resolveAssetName(for: speciesName) else {
            return false
        }
        
        let descriptor = FetchDescriptor<GardenPlot>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let occupied = Set(existing.map { "\($0.row)-\($0.col)" })
        
        var allCells: [(Int, Int)] = []
        for row in 0..<GardenLayout.gridSize {
            for col in 0..<GardenLayout.gridSize {
                if !occupied.contains("\(row)-\(col)") {
                    allCells.append((row, col))
                }
            }
        }
        
        guard let (row, col) = allCells.randomElement() else {
            return false // garden full
        }
        
        let plot = GardenPlot(row: row, col: col, assetName: assetName)
        context.insert(plot)
        return true
    }
    
    /// Checks bird assets first, then plant assets.
    private static func resolveAssetName(for speciesName: String) -> String? {
        if let birdAsset = BirdAsset.assetName(for: speciesName) {
            return birdAsset
        }
        return PlantAsset.assetName(for: speciesName)
    }
    
    // MARK: - Backward-compatible alias
    
    @discardableResult
    static func placeBird(speciesName: String, context: ModelContext) -> Bool {
        placeSpecies(speciesName: speciesName, context: context)
    }
}
