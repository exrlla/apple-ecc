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
    
    var onAudioCaptured: ((URL) -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                
                Spacer()
                
                Text(isRecording ? "Listening..." : "Tap to record a bird call")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(isRecording ? .red : .primary)
                
                // Pulsing record button
                Button {
                    isRecording ? stopRecording() : startRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red.opacity(0.15) : Color.orange.opacity(0.12))
                            .frame(width: 120, height: 120)
                        Circle()
                            .fill(isRecording ? Color.red : Color.orange)
                            .frame(width: 80, height: 80)
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                    }
                }
                
                if !isRecording, recordingURL != nil {
                    Button("Use this recording") {
                        if let url = recordingURL {
                            onAudioCaptured?(url)
                            dismiss()
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Button("Cancel") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
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
