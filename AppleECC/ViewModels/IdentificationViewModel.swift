//
//  IdentificationViewModel.swift
//  AppleECC
//

import SwiftUI
import SwiftData

@MainActor
@Observable
class IdentificationViewModel {
    
    // State the view reads
    var isIdentifying = false
    var result: IdentificationResult? = nil
    var savedSighting: Sighting? = nil
    var errorMessage: String? = nil
    var showResult = false
    
    private var identifier: CloudIdentifier = {
        let key = Bundle.main.infoDictionary?["ANTHROPIC_API_KEY"] as? String ?? ""
        return CloudIdentifier(apiKey: key)
    }()
    
    // MARK: - Step 1: Identify the image
    func identify(image: UIImage) async {
        guard !isIdentifying else { return }
        isIdentifying = true
        errorMessage = nil
        result = nil
        
        do {
            let identified = try await identifier.identify(image: image)
            result = identified
            showResult = true
        } catch {
            print("--- identification error: \(error)")
            errorMessage = "Something went wrong identifying this image. Please try again."
        }
        
        isIdentifying = false
    }
    
    // MARK: - Step 2: Save to library (SwiftData)
    func saveToLibrary(image: UIImage, context: ModelContext) {
        print("--- saveToLibrary called")
        guard let result = result else { return }
        guard result.confidence != .notIdentified else { return }
        
        let imageData = image.jpegData(compressionQuality: 0.8)
        
        let birdNames = [
            "Ruby-Throated Hummingbird", "Baltimore Oriole",
            "Red-Winged Blackbird", "Blue Jay",
            "White-Throated Sparrow", "Palm Warbler",
            "Northern Cardinal", "Black-Capped Chickadee",
            "Golden Finch"
        ]
        let speciesType: Sighting.SpeciesType = birdNames.contains(result.speciesName) ? .bird : .plant
        
        let sighting = Sighting(
            speciesName: result.speciesName,
            speciesType: speciesType,
            imageData: imageData,
            confidenceLevel: result.confidence == .high ? "high" : "low"
        )
        
        context.insert(sighting)
        savedSighting = sighting
        print("--- sighting inserted, about to save")
        
        // Only birds get planted in the garden — plants don't have BirdAsset art
        if speciesType == .bird || speciesType == .plant {
            GardenPlacement.placeSpecies(speciesName: result.speciesName, context: context)
                }
        
        print("--- about to call context.save()")
        do {
            print("--- SAVE using context: \(ObjectIdentifier(context))")
            try context.save()
            print("--- save succeeded")

        } catch {
            print("--- SAVE ERROR: \(error)")
            errorMessage = "Identified but couldn't save. Please try again."
        }
    }
    
    // MARK: - Step 1b: Identify audio
    func identifyAudio(url: URL) async {
        guard !isIdentifying else { return }
        isIdentifying = true
        errorMessage = nil
        result = nil
        
        do {
            let identified = try await identifier.identifyAudio(url: url)
            result = identified
            showResult = true
        } catch {
            print("--- audio identification error: \(error)")
            errorMessage = "Something went wrong identifying this recording. Please try again."
        }
        
        isIdentifying = false
    }
    
    // MARK: - Step 2b: Save audio sighting to library
    func saveAudioToLibrary(audioURL: URL, context: ModelContext) {
        guard let result = result else { return }
        guard result.confidence != .notIdentified else { return }
        
        let sighting = Sighting(
            speciesName: result.speciesName,
            speciesType: .bird,
            audioURL: audioURL.absoluteString,
            confidenceLevel: result.confidence == .high ? "high" : "low"
        )
        
        context.insert(sighting)
        savedSighting = sighting
        
        GardenPlacement.placeBird(speciesName: result.speciesName, context: context)
        
        do {
            try context.save()
        } catch {
            print("--- SAVE ERROR: \(error)")
            errorMessage = "Identified but couldn't save. Please try again."
        }
    }
    
    func reset() {
        result = nil
        savedSighting = nil
        errorMessage = nil
        showResult = false
        isIdentifying = false
    }
}
