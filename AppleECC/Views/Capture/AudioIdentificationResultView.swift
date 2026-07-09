//
//  AudioIdentificationResultView.swift
//  AppleECC
//

import SwiftUI
import SwiftData
import AVFoundation

struct AudioIdentificationResultView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    let audioURL: URL
    var onDismissSheet: (() -> Void)?
    
    @State private var viewModel = IdentificationViewModel()
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var waveformHeights: [CGFloat] = []
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Audio player section
            VStack(spacing: 20) {
                
                // Decorative waveform
                HStack(spacing: 3) {
                    ForEach(Array(waveformHeights.enumerated()), id: \.offset) { _, height in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.orange.opacity(isPlaying ? 0.8 : 0.5))
                            .frame(width: 4, height: height)
                            .animation(.easeInOut(duration: 0.3), value: isPlaying)
                    }
                }
                .frame(height: 70)
                
                // Play / pause button
                Button {
                    togglePlayback()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 56, height: 56)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                }
                
                Text("Bird call recording")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color(.systemGray6))
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Identifying state
                    if viewModel.isIdentifying {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.4)
                            Text("Identifying bird call...")
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
                                
                                Text("Couldn't identify this call")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("Try recording in a quieter environment with the bird call clearly audible.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                
                                Button("Try again") {
                                    onDismissSheet?()
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
                                        onDismissSheet?()
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
                                        viewModel.saveAudioToLibrary(audioURL: audioURL, context: modelContext)
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
                                        onDismissSheet?()
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
                            Button("Try again") {
                                onDismissSheet?()
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onDismissSheet?()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.primary)
                }
            }
        }
        .onAppear {
            generateWaveform()
            Task {
                await viewModel.identifyAudio(url: audioURL)
            }
        }
        .onDisappear {
            player?.stop()
        }
    }
    
    // MARK: - Waveform
    
    private func generateWaveform() {
        var heights: [CGFloat] = []
        for i in 0..<35 {
            // Create a wave-like pattern
            let base = sin(Double(i) * 0.4) * 20 + 35
            let variation = Double.random(in: -8...8)
            heights.append(CGFloat(max(10, base + variation)))
        }
        waveformHeights = heights
    }
    
    // MARK: - Playback
    
    private func togglePlayback() {
        if isPlaying {
            player?.stop()
            isPlaying = false
        } else {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)
                player = try AVAudioPlayer(contentsOf: audioURL)
                player?.play()
                isPlaying = true
            } catch {
                print("Playback error: \(error)")
            }
        }
    }
}
