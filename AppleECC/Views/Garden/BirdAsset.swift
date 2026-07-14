import Foundation

enum BirdAsset {
    static func assetName(for speciesName: String) -> String? {
        let mapping: [String: String] = [
            "Ruby-Throated Hummingbird": "ruby_throated_hummingbird",
            "Baltimore Oriole": "baltimore_oriole",
            "Red-winged Blackbird": "red_winged_blackbird", // matches your provided filename
            "Blue Jay": "bluejay",
            "American Robin": "american_robin",
            "Golden Finch": "golden_finch",
            "Northern Cardinal": "northern_cardinal",
            "Black-capped Chickadee": "black_capped_chickadee"
        ]
        return mapping[speciesName]
    }
}
