//
//  GardenTile.swift
//  AppleECC
//

import Foundation

enum TileEdge {
    case center, leftSide, rightSide, corner
}

enum GardenLayout {
    static let gridSize = 6

    static func edge(row: Int, col: Int) -> TileEdge {
        let maxIndex = gridSize - 1
        switch (row, col) {
        case (maxIndex, maxIndex):
            return .corner
        case (maxIndex, _):
            return .leftSide
        case (_, maxIndex):
            return .rightSide
        default:
            return .center
        }
    }

    static func assetName(row: Int, col: Int) -> String {
        switch edge(row: row, col: col) {
        case .center:    return "tile_center"
        case .leftSide:  return "tile_left"
        case .rightSide: return "tile_right"
        case .corner:    return "tile_corner"
        }
    }
}
