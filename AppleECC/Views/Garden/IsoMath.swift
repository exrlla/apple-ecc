//
//  IsoMath.swift
//  AppleECC
//
//  Created by Apple on 7/7/26.
//

import SwiftUI

enum IsoMath {
    static let tileWidth: CGFloat = 60      // diamond width — grid spacing
    static let tileHeight: CGFloat = 35      // diamond height — grid spacing only
    static let tileArtHeight: CGFloat = 35  // full block art height including depth

    static func screenOffset(row: Int, col: Int) -> CGSize {
        let x = CGFloat(col - row) * (tileWidth / 2)
        let y = CGFloat(col + row) * (tileHeight / 2.6)
        return CGSize(width: x, height: y)
    }

    static func zIndex(row: Int, col: Int) -> Double {
        Double(row + col)
    }
}
