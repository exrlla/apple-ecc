//
//  LibraryView.swift
//  AppleECC
//

import SwiftUI
import SwiftData

// MARK: - Geist Pixel font helper

extension Font {
    static func geistPixel(_ size: CGFloat) -> Font {
        .custom("Geist Pixel", size: size)
    }
}

struct LibraryView: View {
    private var backgroundGradient: LinearGradient {
        if accessibilitySettings.colorblindAssistMode {
            LinearGradient(
                colors: [Color(hex: "CFE0F0"), Color(hex: "9DBEDD"), Color(hex: "6E93B8")],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            LinearGradient(
                colors: [Color(hex: "D3DDC8"), Color(hex: "AABA9E"), Color(hex: "7E9374")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sighting.capturedAt, order: .reverse) private var sightings: [Sighting]
    @State private var selectedFilter: SpeciesFilter = .all
    @State private var selectedSighting: Sighting?
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    enum SpeciesFilter: String, CaseIterable {
        case all = "All"
        case birds = "Birds"
        case plants = "Plants"
    }
    
    var filteredSightings: [Sighting] {
        switch selectedFilter {
        case .all: return sightings
        case .birds: return sightings.filter { $0.speciesType == .bird }
        case .plants: return sightings.filter { $0.speciesType == .plant }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Library")
                    .font(.geistPixel(32))
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: "46351D"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                Divider()
                // MARK: - Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SpeciesFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                label: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Divider()
                
                if filteredSightings.isEmpty {
                    // MARK: - Empty state
                    VStack(spacing: 18) {
                            Image(systemName: "leaf.circle")
                                .font(.system(size: 64))
                                .foregroundStyle(Color(hex: "46351D").opacity(0.5))
                            Text("Nothing here yet")
                                .font(.geistPixel(22))
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                            Text("Identify a bird or plant to start building your library.")
                                .font(.geistPixel(16))
                                .fontWeight(.medium)
                                .foregroundStyle(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                        .padding(.top, 60)
                } else {
                    // MARK: - Sightings list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                                ForEach(filteredSightings) { sighting in
                                    LibraryRowView(sighting: sighting)
                                        .onTapGesture { selectedSighting = sighting
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
            }
            .background(backgroundGradient.ignoresSafeArea())
            .sheet(item: $selectedSighting) { sighting in
                SpeciesDetailView(sighting: sighting)
            }
        }
        .onAppear {
            print("--- LibraryView using context: \(ObjectIdentifier(modelContext))")
            print("--- LibraryView sees \(sightings.count) sightings")
        }
    }
}

// MARK: - Library row

struct LibraryRowView: View {
    let sighting: Sighting
    
    @State private var wikipediaImageURL: URL?
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    var body: some View {
        HStack(spacing: 14) {
            
            // MARK: - Thumbnail
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
                        case .failure, .empty:
                            fallbackIcon
                        @unknown default:
                            fallbackIcon
                        }
                    }
                } else {
                    fallbackIcon
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .task {
                await loadWikipediaImageIfNeeded()
            }
            
            // MARK: - Info
            VStack(alignment: .leading, spacing: 5) {
                Text(sighting.speciesName)
                    .font(.geistPixel(15))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                // Time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(sighting.capturedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.geistPixel(12))
                        .foregroundStyle(.secondary)
                }
                
                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                        .foregroundStyle(sighting.locationName != nil ? .secondary : .tertiary)
                    Text(sighting.locationName ?? "No location — tap to add")
                        .font(.geistPixel(12))
                        .foregroundStyle(sighting.locationName != nil ? .secondary : .tertiary)
                        .italic(sighting.locationName == nil)
                }
            }
            
            Spacer()
            
            // Type badge + chevron
            VStack(alignment: .trailing, spacing: 8) {
                Text(sighting.speciesType == .bird ? "Bird" : "Plant")
                    .font(.geistPixel(11))
                    .fontWeight(.medium)
                    .foregroundStyle(sighting.speciesType == .bird ? .blue : accessibilitySettings.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        sighting.speciesType == .bird
                        ? Color.blue.opacity(0.12)
                        : accessibilitySettings.accentColor.opacity(0.12)
                    )
                    .clipShape(Capsule())
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
    
    private var fallbackIcon: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: sighting.speciesType == .bird ? "bird" : "leaf")
                    .foregroundStyle(.secondary)
            )
    }
    
    // MARK: - Load Wikipedia image (properly parsed, matching SpeciesDetailView)
    private func loadWikipediaImageIfNeeded() async {
        guard sighting.imageData == nil, wikipediaImageURL == nil else { return }
        
        let encoded = sighting.speciesName
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        
        guard let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else { return }
        
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let thumbnail = json["thumbnail"] as? [String: Any],
           let source = thumbnail["source"] as? String,
           let imageURL = URL(string: source) {
            wikipediaImageURL = imageURL
        }
    }
}

// MARK: - Filter pill

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.geistPixel(15))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? accessibilitySettings.accentColor : Color(.systemGray6))
                .clipShape(Capsule())
        }
    }
}
