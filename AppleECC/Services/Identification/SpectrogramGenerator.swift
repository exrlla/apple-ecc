//
//  SpectrogramGenerator.swift
//  AppleECC
//

import Foundation
import AVFoundation
import Accelerate
import UIKit

enum SpectrogramError: Error {
    case couldNotReadAudio
    case emptyAudioBuffer
}

struct SpectrogramGenerator {
    
    // Tuning parameters
    private static let fftSize = 1024          // samples per FFT window
    private static let hopSize = 512            // overlap between windows (50%)
    private static let imageHeight = 300         // pixels tall (frequency axis)
    private static let imageWidth = 600          // pixels wide (time axis)
    
    /// Reads an audio file and produces a spectrogram image suitable for
    /// sending to Claude's image-based identification endpoint.
    static func generateSpectrogram(from url: URL) throws -> UIImage {
        let samples = try loadSamples(from: url)
        guard !samples.isEmpty else { throw SpectrogramError.emptyAudioBuffer }
        
        let magnitudes = computeSTFT(samples: samples)
        return renderImage(from: magnitudes)
    }
    
    // MARK: - Step 1: Load raw audio samples as Float array
    
    private static func loadSamples(from url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: file.fileFormat.sampleRate,
            channels: 1,
            interleaved: false
        )!
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            throw SpectrogramError.couldNotReadAudio
        }
        
        try file.read(into: buffer)
        
        guard let channelData = buffer.floatChannelData else {
            throw SpectrogramError.couldNotReadAudio
        }
        
        let frameLength = Int(buffer.frameLength)
        return Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
    }
    
    // MARK: - Step 2: Short-Time Fourier Transform → magnitude matrix
    
    private static func computeSTFT(samples: [Float]) -> [[Float]] {
        let log2n = vDSP_Length(log2(Float(fftSize)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return []
        }
        defer { vDSP_destroy_fftsetup(fftSetup) }
        
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        
        var magnitudeColumns: [[Float]] = []
        
        var start = 0
        while start + fftSize <= samples.count {
            let segment = Array(samples[start..<(start + fftSize)])
            
            var windowed = [Float](repeating: 0, count: fftSize)
            vDSP_vmul(segment, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))
            
            var realp = [Float](repeating: 0, count: fftSize / 2)
            var imagp = [Float](repeating: 0, count: fftSize / 2)
            var magnitudes = [Float](repeating: 0, count: fftSize / 2)
            
            realp.withUnsafeMutableBufferPointer { realPtr in
                imagp.withUnsafeMutableBufferPointer { imagPtr in
                    var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                    
                    windowed.withUnsafeBufferPointer { windowedPtr in
                        windowedPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { complexPtr in
                            vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
                        }
                    }
                    
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
                }
            }
            
            // Add a small floor to avoid log10(0) = -infinity
            var floored = magnitudes
            var epsilon: Float = 1e-6
            vDSP_vsadd(magnitudes, 1, &epsilon, &floored, 1, vDSP_Length(magnitudes.count))
            
            // Convert to dB scale (log magnitude) for perceptual usefulness
            var dbMagnitudes = [Float](repeating: 0, count: floored.count)
            var reference: Float = 1.0
            vDSP_vdbcon(floored, 1, &reference, &dbMagnitudes, 1, vDSP_Length(floored.count), 1)
            
            // Clamp to a reasonable floor so outliers/non-finite values don't skew normalization
            for i in 0..<dbMagnitudes.count {
                if !dbMagnitudes[i].isFinite {
                    dbMagnitudes[i] = -100
                } else {
                    dbMagnitudes[i] = max(dbMagnitudes[i], -100)
                }
            }
            
            magnitudeColumns.append(dbMagnitudes)
            start += hopSize
        }
        
        return magnitudeColumns
    }
    
    // MARK: - Step 3: Render magnitude matrix as a UIImage
    
    private static func renderImage(from magnitudeColumns: [[Float]]) -> UIImage {
        guard !magnitudeColumns.isEmpty, let firstColumn = magnitudeColumns.first else {
            return UIImage()
        }
        
        // Normalize magnitudes to 0...1 for color mapping (ignoring any non-finite stragglers)
        let allValues = magnitudeColumns.flatMap { $0 }.filter { $0.isFinite }
        let minVal = allValues.min() ?? -100
        let maxVal = allValues.max() ?? 0
        let range = max(maxVal - minVal, 0.0001)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: imageWidth, height: imageHeight))
        
        return renderer.image { context in
            // Black background
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
            
            let columnCount = magnitudeColumns.count
            let binCount = firstColumn.count
            let colWidth = CGFloat(imageWidth) / CGFloat(columnCount)
            let rowHeight = CGFloat(imageHeight) / CGFloat(binCount)
            
            for (col, magnitudes) in magnitudeColumns.enumerated() {
                for (bin, magnitude) in magnitudes.enumerated() {
                    guard magnitude.isFinite else { continue }
                    
                    let normalized = (magnitude - minVal) / range
                    let color = colorForIntensity(normalized)
                    color.setFill()
                    
                    let x = CGFloat(col) * colWidth
                    // Flip vertically so low frequencies are at the bottom
                    let y = CGFloat(imageHeight) - CGFloat(bin + 1) * rowHeight
                    
                    context.fill(CGRect(x: x, y: y, width: colWidth + 1, height: rowHeight + 1))
                }
            }
        }
    }
    
    // Simple heat-map style coloring: black -> blue -> yellow -> white
    private static func colorForIntensity(_ value: Float) -> UIColor {
        let clamped = max(0, min(1, value))
        
        switch clamped {
        case 0..<0.4:
            let t = CGFloat(clamped / 0.4)
            return UIColor(red: 0, green: 0, blue: t, alpha: 1)
        case 0.4..<0.75:
            let t = CGFloat((clamped - 0.4) / 0.35)
            return UIColor(red: t, green: t * 0.8, blue: 1 - t, alpha: 1)
        default:
            let t = CGFloat((clamped - 0.75) / 0.25)
            return UIColor(red: 1, green: 1, blue: t, alpha: 1)
        }
    }
}
