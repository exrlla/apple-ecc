//
//  IdentificationViewModel.swift
//  AppleECC
//

import SwiftUI
import SwiftData

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
        print("--- loading API key, found: \(!key.isEmpty)")
        return CloudIdentifier(apiKey: key)
    }()
    
    // MARK: - Step 1: Identify the image
    func identify(image: UIImage) async {
        guard !isIdentifying else { return }  // add this line
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
        guard let result = result else { return }
        guard result.confidence != .notIdentified else { return }
        
        let imageData = image.jpegData(compressionQuality: 0.8)
        
        // Guess species type from name — birds vs plants
        let birdNames = [
            "Ruby-Throated Hummingbird", "Baltimore Oriole",
            "Red-Winged Blackbird", "Blue Jay",
            "White-Throated Sparrow", "Palm Warbler",
            "Northern Cardinal", "Black-Capped Chickadee"
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
        
        do {
            try context.save()
        } catch {
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
