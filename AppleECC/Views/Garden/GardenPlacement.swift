import SwiftData
import Foundation

enum GardenPlacement {
    
    /// Picks a random unoccupied cell and places the bird there.
    /// Returns false if the garden is full or the species has no asset mapping.
    @discardableResult
    static func placeBird(speciesName: String, context: ModelContext) -> Bool {
        guard let assetName = BirdAsset.assetName(for: speciesName) else {
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
}