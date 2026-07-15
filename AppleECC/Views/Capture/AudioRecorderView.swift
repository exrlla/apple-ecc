//
//  AudioRecorderView.swift
//  AppleECC
//

import SwiftUI
import AVFoundation

struct AudioRecorderView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var recorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var recordingURL: URL?
    @State private var pulse = false
    
    var onAudioCaptured: ((URL) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "D8E7EF"), Color(hex: "AECEDE"), Color(hex: "7BB2D9")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    VStack(spacing: 10) {
                        Image(systemName: "waveform")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color(hex: "46351D"))
                        
                        Text(isRecording ? "Listening..." : "Tap to record a bird call")
                            .font(.geistPixel(22))
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: "46351D"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Pulsing record button
                    Button {
                        isRecording ? stopRecording() : startRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "46351D").opacity(0.10))
                                .frame(width: 96, height: 96)
                                .offset(x: 4, y: 4)
                            
                            Circle()
                                .stroke(Color(hex: "46351D"), lineWidth: 3)
                                .fill(isRecording ? Color(hex: "C0504D") : Color(hex: "7BB2D9"))
                                .frame(width: 96, height: 96)
                                .scaleEffect(pulse && isRecording ? 1.08 : 1.0)
                                .animation(
                                    isRecording ?
                                        .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default,
                                    value: pulse
                                )
                            
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .onAppear { pulse = true }
                    
                    if !isRecording, recordingURL != nil {
                        Button {
                            if let url = recordingURL {
                                onAudioCaptured?(url)
                                dismiss()
                            }
                        } label: {
                            Text("Use this recording")
                                .font(.geistPixel(17))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(hex: "46351D"))
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(hex: "46351D").opacity(0.3), lineWidth: 1.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    
                    Spacer()
                    
                    Button("Cancel") { dismiss() }
                        .font(.geistPixel(16))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "46351D").opacity(0.6))
                        .padding(.bottom, 32)
                }
            }
        }
    }
    
    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .default)
        try? session.setActive(true)
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("birdcall_\(Date().timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        recordingURL = url
        isRecording = true
    }
    
    private func stopRecording() {
        recorder?.stop()
        isRecording = false
    }
}
