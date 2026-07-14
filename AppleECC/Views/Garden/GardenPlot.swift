//
//  GardenPlot.swift
//  AppleECC
//

import SwiftData
import Foundation

@Model
final class GardenPlot {
    var row: Int
    var col: Int
    var assetName: String
    var speciesName: String = ""
    var dateAdded: Date

    init(row: Int, col: Int, assetName: String, speciesName: String = "") {
        self.row = row
        self.col = col
        self.assetName = assetName
        self.speciesName = speciesName
        self.dateAdded = .now
    }
}
