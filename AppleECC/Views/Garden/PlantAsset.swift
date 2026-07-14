//
//  PlantAsset.swift
//  AppleECC
//

import Foundation

enum PlantAsset {
    private static let mapping: [String: String] = [
        "Bur Oak": "buroak",
        "Elm": "elm"
    ]
    
    static func assetName(for speciesName: String) -> String? {
        mapping[speciesName]
    }
    
    /// All known plant asset names — used to distinguish plant sprites from bird sprites (e.g. in GardenView).
    static let allAssetNames: Set<String> = Set(mapping.values)
}
