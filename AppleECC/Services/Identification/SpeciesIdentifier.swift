//
//  SpeciesIdentifier.swift
//  AppleECC
//

import UIKit

struct IdentificationResult {
    let speciesName: String
    let confidence: ConfidenceLevel
    
    enum ConfidenceLevel {
        case high
        case low
        case notIdentified
    }
}

protocol SpeciesIdentifier {
    func identify(image: UIImage) async throws -> IdentificationResult
}
