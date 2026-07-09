//
//  SpeciesDetailView.swift
//  AppleECC
//

import SwiftUI
import SwiftData
import MapKit

struct SpeciesDetailView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let sighting: Sighting
    
    @State private var showDeleteConfirm = false
    @State private var showAddLocation = false
    @State private var locationInput: String = ""
    @State private var wikipediaImageURL: URL?
    @State private var speechService = SpeechService()
    
    // MARK: - Hardcoded species descriptions
    private static let speciesDescriptions: [String: String] = [
        "Bur Oak": "The Bur Oak is one of the most iconic trees of the Midwest prairie, known for its thick, corky bark that helps it survive prairie fires. You'll spot its distinctive fringed acorn caps scattered beneath mature trees in Chicago's forest preserves, especially in fall. Some Bur Oaks in the region are over 200 years old, making them living witnesses to the city's earliest history. Look for them year-round in places like the Morton Arboretum or along the Chicago River.",
        
        "Elm": "Elms once lined nearly every street in Chicago, forming leafy tunnels before Dutch elm disease devastated the population in the mid-20th century. Today, disease-resistant varieties are being replanted throughout the city, and you can still find majestic old survivors in parks like Lincoln Park. Their distinctive vase-shaped canopy and serrated leaves turn a warm yellow in autumn. Elms are best appreciated in summer when their full canopy provides shade along Chicago's boulevards.",
        
        "Ruby-Throated Hummingbird": "The Ruby-Throated Hummingbird is the only hummingbird species commonly seen in the Chicago area, arriving each spring after an incredible non-stop flight across the Gulf of Mexico. Males flash a brilliant iridescent red throat patch when catching the light just right. Look for them from May through September, especially near gardens with tubular red or orange flowers like trumpet vine or bee balm. Feeders filled with sugar water are a great way to attract them to backyards throughout the city.",
        
        "Baltimore Oriole": "Named for the orange and black colors that matched Lord Baltimore's coat of arms, the Baltimore Oriole is a striking summer visitor to Chicago's parks and wooded areas. They're best spotted from late April through September, often high in tree canopies where they weave intricate hanging nests. Their flute-like whistled song is a familiar sound of Chicago springs. Try offering orange slices or grape jelly in your backyard to attract these colorful birds.",
        
        "Red-Winged Blackbird": "One of the most abundant birds in North America, the Red-Winged Blackbird is easily recognized by the males' bold red and yellow shoulder patches, flashed dramatically during territorial displays. They're a classic sign of spring in Chicago, arriving in marshes and wetlands as early as February and staying through fall. Listen for their distinctive conk-la-ree call near the Skokie Lagoons or along the lakefront. Females look completely different, with streaky brown plumage that helps camouflage them near their nests.",
        
        "Blue Jay": "The Blue Jay is a year-round Chicago resident, instantly recognizable by its vivid blue, white, and black plumage and prominent crest. Known for their intelligence, Blue Jays cache thousands of acorns each fall and are credited with helping oak forests spread across the Midwest. Their loud, jeering calls can be heard in parks and backyards throughout the city all year long. They're also skilled mimics, sometimes imitating the calls of hawks to scare off other birds from feeders.",
        
        "White-Throated Sparrow": "The White-Throated Sparrow passes through Chicago each spring and fall during migration, though some also spend the winter in the area. Its clear, whistled song is often remembered by the mnemonic 'Oh sweet Canada, Canada, Canada.' Look for its namesake white throat patch and yellow spot between the eye and bill while it forages on the ground in brushy areas. Forest preserves with dense understory, like those along the North Branch Trail, are great places to spot them scratching through leaf litter.",
        
        "Palm Warbler": "The Palm Warbler is a common migrant through Chicago each spring and fall, easily identified by its constant tail-bobbing habit as it forages low to the ground. Despite its tropical-sounding name, it actually breeds in Canadian bogs, not palm trees. Its warm rusty cap and yellow undertail feathers stand out during April and October migration windows. Lakefront parks and forest preserve edges are good spots to catch this energetic little warbler passing through.",
        
        "Northern Cardinal": "Illinois's state bird, the Northern Cardinal is a beloved year-round resident of Chicago, with the male's brilliant red plumage standing out dramatically against winter snow. Cardinals don't migrate, so they're a reliable sight at backyard feeders throughout every season. Females sport a more subtle reddish-brown color but share the male's distinctive crest. Their clear, whistled songs are among the first bird sounds heard on quiet Chicago mornings, even in the depths of winter.",
        
        "Black-Capped Chickadee": "The Black-Capped Chickadee is a cheerful year-round presence in Chicago, recognized by its black cap and bib contrasting with white cheeks. Despite their tiny size, chickadees are remarkably hardy, surviving harsh Midwest winters by caching thousands of food items each fall and recalling their locations with surprising accuracy. Their namesake chick-a-dee-dee-dee call, along with a whistled fee-bee song, is a familiar sound in parks and wooded backyards throughout the year. They're also famously curious and can sometimes be hand-fed with patience."
    ]
    
    private var speciesDescription: String {
        Self.speciesDescriptions[sighting.speciesName] ?? "No description available for this species yet."
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // MARK: - Image
                    Group {
                        if let imageData = sighting.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else if let url = wikipediaImageURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    placeholderImage
                                }
                            }
                        } else {
                            placeholderImage
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipped()
                    
                    // MARK: - Content
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // MARK: - Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text(sighting.speciesType == .bird ? "Bird" : "Plant")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(sighting.speciesType == .bird ? .blue : .green)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        sighting.speciesType == .bird
                                        ? Color.blue.opacity(0.12)
                                        : Color.green.opacity(0.12)
                                    )
                                    .clipShape(Capsule())
                                
                                if sighting.confidenceLevel == "low" {
                                    Text("Low confidence")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                Spacer()
                            }
                            
                            Text(sighting.speciesName)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Divider()
                        
                        // MARK: - Sighting details
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Sighting details")
                                .font(.headline)
                            
                            DetailRow(
                                icon: "calendar",
                                label: "Date",
                                value: sighting.capturedAt.formatted(date: .long, time: .omitted)
                            )
                            
                            DetailRow(
                                icon: "clock",
                                label: "Time",
                                value: sighting.capturedAt.formatted(date: .omitted, time: .shortened)
                            )
                            
                            // Location row
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                Text("Location")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let location = sighting.locationName {
                                    Text(location)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                } else {
                                    Button("Add location") {
                                        showAddLocation = true
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                }
                            }
                            
                            // Map if coordinates exist
                            if let lat = sighting.latitude,
                               let lon = sighting.longitude {
                                let coordinate = CLLocationCoordinate2D(
                                    latitude: lat,
                                    longitude: lon
                                )
                                Map(initialPosition: .region(
                                    MKCoordinateRegion(
                                        center: coordinate,
                                        span: MKCoordinateSpan(
                                            latitudeDelta: 0.01,
                                            longitudeDelta: 0.01
                                        )
                                    )
                                )) {
                                    Marker(sighting.speciesName, coordinate: coordinate)
                                }
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        Divider()
                        
                        // MARK: - Species description
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("About \(sighting.speciesName)")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button {
                                    speechService.speak("\(sighting.speciesName). \(speciesDescription)")
                                } label: {
                                    Label("Listen", systemImage: "speaker.wave.2.fill")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            
                            Text(speciesDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Divider()
                        
                        // MARK: - Delete
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete sighting", systemImage: "trash")
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAddLocation) {
                AddLocationView(locationName: $locationInput) { name in
                    sighting.locationName = name
                    try? modelContext.save()
                }
            }
            .confirmationDialog(
                "Delete this sighting?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(sighting)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove \(sighting.speciesName) from your library.")
            }
            .onAppear {
                loadWikipediaImageIfNeeded()
            }
        }
    }
    
    // MARK: - Placeholder
    var placeholderImage: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: sighting.speciesType == .bird ? "bird" : "leaf")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            )
    }
    
    // MARK: - Load Wikipedia image
    private func loadWikipediaImageIfNeeded() {
        guard sighting.imageData == nil else { return }
        
        let encoded = sighting.speciesName
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        
        guard let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else { return }
        
        Task {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let thumbnail = json["thumbnail"] as? [String: Any],
               let source = thumbnail["source"] as? String,
               let imageURL = URL(string: source) {
                await MainActor.run {
                    wikipediaImageURL = imageURL
                }
            }
        }
    }
}

// MARK: - Add location view

struct AddLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var locationName: String
    var onSave: (String) -> Void
    
    @State private var input: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where did you see this?")
                        .font(.headline)
                    TextField("e.g. Lincoln Park, Montrose Beach...", text: $input)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                Spacer()
            }
            .navigationTitle("Add location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(input)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Detail row

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
