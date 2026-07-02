//
//  Sighting.swift
//  AppleECC
//

import SwiftData
import SwiftUI
import Foundation

@Model
class Sighting {
    var id: UUID
    var speciesName: String
    var speciesType: SpeciesType
    var capturedAt: Date
    var imageData: Data?
    var audioURL: String?
    var confidenceLevel: String
    var notes: String
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var cachedDescription: String?
    
    init(
        speciesName: String,
        speciesType: SpeciesType,
        imageData: Data? = nil,
        audioURL: String? = nil,
        confidenceLevel: String = "high",
        notes: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil
    ) {
        self.id = UUID()
        self.speciesName = speciesName
        self.speciesType = speciesType
        self.capturedAt = Date()
        self.imageData = imageData
        self.audioURL = audioURL
        self.confidenceLevel = confidenceLevel
        self.notes = notes
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
    }
    
    enum SpeciesType: String, Codable {
        case bird
        case plant
        case unknown
    }
}
