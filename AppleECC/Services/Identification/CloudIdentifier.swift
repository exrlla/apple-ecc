//
//  CloudIdentifier.swift
//  AppleECC
//

import UIKit

enum IdentifierError: Error {
    case imageEncodingFailed
    case networkError(Error)
    case invalidResponse
    case apiError(String)
}

class CloudIdentifier: SpeciesIdentifier {
    
    private let apiKey: String
    private let endpoint = "https://api.anthropic.com/v1/messages"
    
    private let chicagoSpecies = [
        "Bur Oak",
        "Elm",
        "Ruby-Throated Hummingbird",
        "Baltimore Oriole",
        "Red-Winged Blackbird",
        "Blue Jay",
        "White-Throated Sparrow",
        "Palm Warbler",
        "Northern Cardinal",
        "Black-Capped Chickadee"
    ]
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func identify(image: UIImage) async throws -> IdentificationResult {
        
        // 1. Encode image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw IdentifierError.imageEncodingFailed
        }
        let base64Image = imageData.base64EncodedString()
        
        // 2. Build the prompt
        let speciesList = chicagoSpecies.joined(separator: ", ")
        let prompt = """
        You are identifying Chicago-native bird and plant species only.
        Look at this image and determine if it contains one of these species: \(speciesList).
        
        Reply in this exact format and nothing else:
        SPECIES: [species name or 'not identified']
        CONFIDENCE: [high or low]
        
        Use 'not identified' if the image is unclear, not a species from the list, 
        or you are not reasonably sure.
        """
        
        // 3. Build request body
        let requestBody: [String: Any] = [
            "model": "claude-opus-4-6",
            "max_tokens": 100,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
        
        // 4. Build URLRequest
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 5. Make the call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IdentifierError.invalidResponse
        }
        
        // 6. Parse response
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = (json["content"] as? [[String: Any]])?.first,
            let text = content["text"] as? String
        else {
            throw IdentifierError.invalidResponse
        }
        
        return parseResponse(text)
    }
    
    // 7. Parse Claude's structured reply into an IdentificationResult
    private func parseResponse(_ text: String) -> IdentificationResult {
        let lines = text.components(separatedBy: "\n")
        
        var speciesName = "not identified"
        var confidence: IdentificationResult.ConfidenceLevel = .notIdentified
        
        for line in lines {
            if line.hasPrefix("SPECIES:") {
                speciesName = line
                    .replacingOccurrences(of: "SPECIES:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
            if line.hasPrefix("CONFIDENCE:") {
                let value = line
                    .replacingOccurrences(of: "CONFIDENCE:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                    .lowercased()
                confidence = value == "high" ? .high : .low
            }
        }
        
        if speciesName.lowercased() == "not identified" {
            return IdentificationResult(speciesName: "not identified", confidence: .notIdentified)
        }
        
        return IdentificationResult(speciesName: speciesName, confidence: confidence)
    }
}
