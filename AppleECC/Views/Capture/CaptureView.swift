//
//  CaptureView.swift
//  AppleECC
//

import SwiftUI
import PhotosUI

struct CaptureView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    // Camera
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    
    // Photo library
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var libraryImage: UIImage?
    
    // Audio
    @State private var showAudioRecorder = false
    
    // Pass result back to GardenViewModel
    var onImageCaptured: ((UIImage) -> Void)?
    var onAudioCaptured: ((URL) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 32)
            
            // MARK: - Title
            Text("What did you find?")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 8)
            
            Text("Take a photo, record a bird call, or upload from your library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            
            // MARK: - Camera button
            CaptureOptionButton(
                icon: "camera.fill",
                label: "Take a photo",
                sublabel: "Identify a plant or bird",
                color: .green
            ) {
                showCamera = true
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // MARK: - Microphone button
            CaptureOptionButton(
                icon: "mic.fill",
                label: "Record a sound",
                sublabel: "Identify a bird by its call",
                color: .orange
            ) {
                showAudioRecorder = true
            }
            .padding(.horizontal, 24)
            
            // MARK: - Divider
            HStack {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1)
                Text("or")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            
            // MARK: - Upload from library
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18))
                    Text("Upload photo from library")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // MARK: - Cancel
            Button("Cancel") {
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
        }
        // MARK: - Camera sheet
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                cameraImage = image
                onImageCaptured?(image)
                dismiss()
            }
        }
        // MARK: - Audio sheet
        .sheet(isPresented: $showAudioRecorder) {
            AudioRecorderView { audioURL in
                onAudioCaptured?(audioURL)
                dismiss()
            }
        }
        // MARK: - Library photo loaded
        .onChange(of: photoPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    libraryImage = image
                    onImageCaptured?(image)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Reusable option button

struct CaptureOptionButton: View {
    let icon: String
    let label: String
    let sublabel: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(sublabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
