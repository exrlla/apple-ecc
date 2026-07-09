//
//  LibraryView.swift
//  AppleECC
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    
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
                Toggle("Large Bold Text", isOn: $accessibilitySettings.largeBoldText)
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                
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
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "leaf.circle")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("Nothing here yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Identify a bird or plant to start building your library.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    // MARK: - Sightings list
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(filteredSightings) { sighting in
                                LibraryRowView(sighting: sighting)
                                    .onTapGesture {
                                        selectedSighting = sighting
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedSighting) { sighting in
                SpeciesDetailView(sighting: sighting)
            }
        }
    }
}

// MARK: - Library row

struct LibraryRowView: View {
    let sighting: Sighting
    
    @State private var wikipediaImageURL: URL?
    
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
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                // Time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(sighting.capturedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                        .foregroundStyle(sighting.locationName != nil ? .secondary : .tertiary)
                    Text(sighting.locationName ?? "No location — tap to add")
                        .font(.caption)
                        .foregroundStyle(sighting.locationName != nil ? .secondary : .tertiary)
                        .italic(sighting.locationName == nil)
                }
            }
            
            Spacer()
            
            // Type badge + chevron
            VStack(alignment: .trailing, spacing: 8) {
                Text(sighting.speciesType == .bird ? "Bird" : "Plant")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(sighting.speciesType == .bird ? .blue : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        sighting.speciesType == .bird
                            ? Color.blue.opacity(0.12)
                            : Color.green.opacity(0.12)
                    )
                    .clipShape(Capsule())
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
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
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(.systemGray6))
                .clipShape(Capsule())
        }
    }
}
