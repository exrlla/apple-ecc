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
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: "7BB2D9"))
                        .frame(width: 100, height: 100)
                    
                    Text("PERCH")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "646F4B"))
                }
                
                Spacer()
            }
            .padding(.leading, 10)
            .padding(.top, 10)
            
            Spacer()
                .frame(maxHeight: 60)
            
            Text("What did you find?")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.black)
                .padding(.bottom, 8)

            Text("Take a photo, record a bird call, or upload from your library.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 34)
                .padding(.bottom, 40)
            
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
            
            CaptureOptionButton(
                icon: "mic.fill",
                label: "Record a sound",
                sublabel: "Identify a bird by its call",
                color: .orange
            ) {
                showAudioRecorder = true
            }
            .padding(.horizontal, 24)
            
            HStack {
                Rectangle()
                    .fill(.black)
                    .frame(height: 2)
                Text("or")
                    .font(.footnote)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                Rectangle()
                    .fill(.black)
                    .frame(height: 2)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.28))
                            .frame(width: 52, height: 52)

                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.blue.opacity(0.95))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upload photo")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text("from library")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(Color(hex: "839D9A"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                cameraImage = image
                onImageCaptured?(image)
                dismiss()
            }
        }
        .sheet(isPresented: $showAudioRecorder) {
            AudioRecorderView { audioURL in
                onAudioCaptured?(audioURL)
                dismiss()
            }
        }
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
                        .fill(color.opacity(0.30))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .fontWeight(.semibold)
                        .foregroundStyle(color.opacity(0.95))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text(sublabel)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(hex: "839D9A"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
