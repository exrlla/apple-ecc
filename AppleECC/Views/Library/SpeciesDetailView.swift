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
    
    @State private var claudeDescription: String = ""
    @State private var isLoadingDescription = false
    @State private var showDeleteConfirm = false
    @State private var showAddLocation = false
    @State private var locationInput: String = ""
    @State private var wikipediaImageURL: URL?
    
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
                        
                        // MARK: - Claude description
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About \(sighting.speciesName)")
                                .font(.headline)
                            
                            if isLoadingDescription {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("Getting description...")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            } else if claudeDescription.isEmpty {
                                Text("No description available.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(claudeDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
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
                loadDescriptionIfNeeded()
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
    
    // MARK: - Load Claude description
    private func loadDescriptionIfNeeded() {
        if let cached = sighting.cachedDescription, !cached.isEmpty {
            claudeDescription = cached
            return
        }
        
        isLoadingDescription = true
        
        Task {
            let apiKey = Bundle.main.infoDictionary?["ANTHROPIC_API_KEY"] as? String ?? ""
            let prompt = """
            Write a short, engaging 3-4 sentence description of the \(sighting.speciesName)
            as it relates to Chicago and the Midwest. Include one interesting fact,
            what season it's typically seen, and where in Chicago you might spot it.
            Keep it friendly and conversational, like a field guide for beginners.
            Reply with only the description, no headings or labels.
            """
            
            let body: [String: Any] = [
                "model": "claude-opus-4-6",
                "max_tokens": 200,
                "messages": [["role": "user", "content": prompt]]
            ]
            
            var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            if let (data, _) = try? await URLSession.shared.data(for: request),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = (json["content"] as? [[String: Any]])?.first,
               let text = content["text"] as? String {
                await MainActor.run {
                    claudeDescription = text
                    sighting.cachedDescription = text
                    try? modelContext.save()
                    isLoadingDescription = false
                }
            } else {
                await MainActor.run {
                    isLoadingDescription = false
                }
            }
        }
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
