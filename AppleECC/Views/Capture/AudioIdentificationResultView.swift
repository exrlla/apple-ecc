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
                            .fill(Color(hex: "7BB2D9").opacity(isPlaying ? 0.9 : 0.55))
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
                            .fill(Color(hex: "46351D").opacity(0.08))
                            .frame(width: 80, height: 80)
                            .offset(x: 3, y: 3)
                        Circle()
                            .stroke(Color(hex: "46351D"), lineWidth: 2.5)
                            .fill(Color(hex: "7BB2D9"))
                            .frame(width: 80, height: 80)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                
                Text("Bird call recording")
                    .font(.geistPixel(18))
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .background(
                LinearGradient(
                    colors: [Color(hex: "EAF2F7"), Color(hex: "D8E7EF")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Identifying state
                    if viewModel.isIdentifying {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.4)
                                .tint(Color(hex: "7BB2D9"))
                            Text("Identifying bird call...")
                                .font(.geistPixel(17))
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)
                        }
                        .padding(.top, 40)
                    }
                    
                    // MARK: - Result
                    if let result = viewModel.result {
                        VStack(spacing: 8) {
                            
                            if result.confidence == .notIdentified {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color(hex: "46351D").opacity(0.4))
                                    .padding(.top, 24)
                                
                                Text("Couldn't identify this call")
                                    .font(.geistPixel(20))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                                
                                Text("Try recording in a quieter environment with the bird call clearly audible.")
                                    .font(.geistPixel(16))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.black)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                
                                Button {
                                    onDismissSheet?()
                                } label: {
                                    Text("Try again")
                                        .font(.geistPixel(17))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 14)
                                        .background(Color(hex: "7BB2D9"))
                                        .clipShape(Capsule())
                                }
                                .padding(.top, 8)
                                
                            } else {
                                // Successfully identified
                                VStack(spacing: 6) {
                                    Text("Found it!")
                                        .font(.geistPixel(14))
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color(hex: "4E8F5C"))
                                        .padding(.top, 24)
                                    
                                    Text(result.speciesName)
                                        .font(.geistPixel(23))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.black)
                                        .multilineTextAlignment(.center)
                                    
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(result.confidence == .high ? Color(hex: "4E8F5C") : Color(hex: "D08C3A"))
                                            .frame(width: 7, height: 7)
                                        Text(result.confidence == .high ? "High confidence" : "Low confidence")
                                            .font(.geistPixel(13))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color(hex: "46351D").opacity(0.7))
                                    }
                                }
                                
                                // Already saved confirmation
                                if viewModel.savedSighting != nil {
                                    VStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundStyle(Color(hex: "4E8F5C"))
                                        Text("Added to your library!")
                                            .font(.geistPixel(16))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.black)
                                    }
                                    .padding(.top, 8)
                                    
                                    Button {
                                        onDismissSheet?()
                                    } label: {
                                        Text("Done")
                                            .font(.geistPixel(17))
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(Color(hex: "4E8F5C"))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
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
                                        .font(.geistPixel(17))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color(hex: "7BB2D9"))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    Button {
                                        onDismissSheet?()
                                    } label: {
                                        Text("Try again")
                                            .font(.geistPixel(16))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.black.opacity(0.6))
                                    }
                                }
                            }
                        }
                    }
                    
                    // MARK: - Error state
                    if let error = viewModel.errorMessage {
                        VStack(spacing: 14) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(Color(hex: "D08C3A"))
                                .padding(.top, 24)
                            Text(error)
                                .font(.geistPixel(18))
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Button {
                                onDismissSheet?()
                            } label: {
                                Text("Try again")
                                    .font(.geistPixel(17))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "7BB2D9"))
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 4)
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
                        .foregroundStyle(Color(hex: "46351D"))
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
