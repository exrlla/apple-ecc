//
//  AccessibilitySettings.swift
//  AppleECC
//
//  Created by lena on 7/9/26.
//

import Combine
import SwiftUI

final class AccessibilitySettings: ObservableObject {
    @Published var largeBoldText: Bool = false
    @Published var colorblindAssistMode: Bool = false
    @Published var reduceMotion: Bool = false

    var accentColor: Color {
        colorblindAssistMode ? Color(hex: "3378C4") : Color.green
    }
}
