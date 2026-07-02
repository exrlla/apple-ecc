
//
//  IdentificationResultView.swift
//  AppleECC
//

import SwiftUI
import SwiftData

struct IdentificationResultView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let image: UIImage
    @State private var viewModel = IdentificationViewModel()
    
    // Tells the parent (CaptureView) we're fully done
    var onSaved: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Photo preview
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Identifying state
                    if viewModel.isIdentifying {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.4)
                            Text("Identifying...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                    }
                    
                    // MARK: - Result
                    if let result = viewModel.result {
                        VStack(spacing: 8) {
                            
                            if result.confidence == .notIdentified {
                                // Not identified
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 24)
                                
                                Text("Couldn't identify this")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("Try a clearer photo with the subject centered and well lit.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                
                                Button("Try again") {
                                    dismiss()
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color.orange)
                                .clipShape(Capsule())
                                .padding(.top, 8)
                                
                            } else {
                                // Successfully identified
                                VStack(spacing: 6) {
                                    Text("Found it!")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.green)
                                        .padding(.top, 24)
                                    
                                    Text(result.speciesName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                    
                                    // Confidence badge
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(result.confidence == .high ? Color.green : Color.orange)
                                            .frame(width: 7, height: 7)
                                        Text(result.confidence == .high ? "High confidence" : "Low confidence")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                // Already saved confirmation
                                if viewModel.savedSighting != nil {
                                    VStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundStyle(.green)
                                        Text("Added to your library!")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.top, 8)
                                    
                                    Button("Done") {
                                        onSaved?()
                                        dismiss()
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                                    
                                } else {
                                    // Add to library button
                                    Button {
                                        viewModel.saveToLibrary(image: image, context: modelContext)
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add to library")
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .padding(.horizontal, 24)
                                    }
                                    
                                    Button("Try again") {
                                        dismiss()
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    // MARK: - Error state
                    if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 36))
                                .foregroundStyle(.orange)
                                .padding(.top, 24)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Button("Try again") { dismiss() }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            Task.detached(priority: .userInitiated) {
                await viewModel.identify(image: image)
            }
        }
    }
}
