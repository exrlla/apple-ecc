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
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return image }
        
        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    
    
    func identify(image: UIImage) async throws -> IdentificationResult {
        print("--- identify() called")
        print("--- api key: '\(apiKey)'")
        
        // 1. Encode image to base64
        let resized = resizeImage(image, maxDimension: 512)
        guard let imageData = resized.jpegData(compressionQuality: 0.4) else {
            throw IdentifierError.imageEncodingFailed
        }
        let base64Image = imageData.base64EncodedString()
        print("--- image encoded: \(imageData.count) bytes")
        print("--- base64 size: \(base64Image.count) bytes")
        
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
        print("--- request built, sending to API...")
        print("--- api key present: \(!apiKey.isEmpty)")
        
        // 5. Make the call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 6. Check status code
        guard let httpResponse = response as? HTTPURLResponse else {
            print("--- error: response was not HTTPURLResponse")
            throw IdentifierError.invalidResponse
        }
        print("--- HTTP status: \(httpResponse.statusCode)")
        
        let rawString = String(data: data, encoding: .utf8) ?? "could not decode"
        print("--- raw response: \(rawString)")
        
        guard httpResponse.statusCode == 200 else {
            throw IdentifierError.invalidResponse
        }
        
        // 7. Parse response
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = (json["content"] as? [[String: Any]])?.first,
            let text = content["text"] as? String
        else {
            print("--- error: could not parse JSON structure")
            throw IdentifierError.invalidResponse
        }
        
        print("--- parsed text: \(text)")
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
