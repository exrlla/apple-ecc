//
//  LargeBoldTextModifier.swift
//  AppleECC
//
//  Created by lena on 7/9/26.
//

import SwiftUI

struct LargeBoldTextModifier: ViewModifier {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings

    func body(content: Content) -> some View {
        content
            .fontWeight(accessibilitySettings.largeBoldText ? .semibold : .regular)
            .dynamicTypeSize(
                accessibilitySettings.largeBoldText
                ? DynamicTypeSize.accessibility1
                : DynamicTypeSize.large
            )
    }
}

extension View {
    func largeBoldTextEnabled() -> some View {
        modifier(LargeBoldTextModifier())
    }
}
