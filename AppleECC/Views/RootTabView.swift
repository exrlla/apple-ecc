//
//  RootTabView.swift
//  AppleECC
//
//  Created by Apple on 6/29/26.
//

import SwiftUI

enum AppTab {
    case capture
    case calendar
    case garden
    case library
}

struct RootTabView: View {
    let backgroundColor = Color(hex: "AABA9E")
    @State private var selectedTab: AppTab = .capture
    @Namespace private var glassNamespace
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                switch selectedTab {
                case .capture:
                    CaptureView()
                case .calendar:
                    CalendarView()
                case .garden:
                    GardenView()
                case .library:
                    LibraryView()
                }
            }
            
            floatingTabBar
        }
        .largeBoldTextEnabled()
    }
    
    private var floatingTabBar: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 0) {
                tabButton(tab: .capture, icon: "binoculars", title: "Capture")
                tabButton(tab: .calendar, icon: "calendar", title: "Calendar")
                tabButton(tab: .garden, icon: "leaf", title: "Garden")
                tabButton(tab: .library, icon: "book", title: "Library")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
    
    private func tabButton(tab: AppTab, icon: String, title: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            ZStack {
                if isSelected {
                    Capsule()
                        .fill(Color(hex: "46351D"))
                        .glassEffectID("selectedTab", in: glassNamespace)
                }
                
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 21, weight: .semibold))

                    Text(title)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(isSelected ? .white : Color(hex: "46351D"))
            }
            .frame(width: 68, height: 50)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootTabView()
        .environmentObject(AccessibilitySettings())
}
