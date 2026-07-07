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
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image("logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 175, height: 175)
                            .frame(width: 125, height: 125)
                            .clipShape(LogoHexagon())
                            .overlay(
                                LogoHexagon()
                                    .stroke(.white, lineWidth: 3)
                            )
                        
                        ZStack {
                            Text("PERCH")
                                .offset(x: -0.6, y: 0)

                            Text("PERCH")
                                .offset(x: 0.6, y: 0)

                            Text("PERCH")
                                .offset(x: 0, y: 0.6)
                        }
                        .font(.custom("Geist Pixel", size: 30))
                        .fontWeight(.heavy)
                        .foregroundStyle(Color(hex: "46351D"))
                        .tracking(3)
                        .frame(width: 175)
                        .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .padding(.top, 75)
                
                Spacer()
                    .frame(maxHeight: 30)
                
                CaptureOptionButton(
                    icon: "camera",
                    label: "Take a photo",
                    sublabel: "Identify a plant or bird",
                    color: .green
                ) {
                    showCamera = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                CaptureOptionButton(
                    icon: "mic",
                    label: "Record a sound",
                    sublabel: "Identify a bird by its call",
                    color: .yellow
                ) {
                    showAudioRecorder = true
                }
                .padding(.horizontal, 24)
                
                HStack {
                    Rectangle()
                        .fill(Color(hex: "46351D"))
                        .frame(height: 2)
                    Text("or")
                        .font(.footnote)
                        .foregroundStyle(Color(hex: "46351D"))
                        .padding(.horizontal, 12)
                    Rectangle()
                        .fill(Color(hex: "46351D"))
                        .frame(height: 2)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.28))
                                .frame(width: 62, height: 62)

                            Image("album")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Upload photo")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)

                            Text("from library")
                                .font(.title3)
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
                        .frame(width: 60, height: 60)
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text(sublabel)
                        .font(.body)
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

struct LogoHexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let inset: CGFloat = rect.width * 0.16
        
        path.move(to: CGPoint(x: inset, y: 0))
        path.addLine(to: CGPoint(x: rect.width - inset, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: inset))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - inset))
        path.addLine(to: CGPoint(x: rect.width - inset, y: rect.height))
        path.addLine(to: CGPoint(x: inset, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height - inset))
        path.addLine(to: CGPoint(x: 0, y: inset))
        path.closeSubpath()
        
        return path
    }
}
