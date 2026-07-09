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
            
            customTabBar
        }
        .largeBoldTextEnabled()
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(tab: .capture, icon: "binoculars", title: "Capture")
            tabButton(tab: .calendar, icon: "calendar", title: "Calendar")
            tabButton(tab: .garden, icon: "leaf", title: "Garden")
            tabButton(tab: .library, icon: "book", title: "Library")
        }
        .frame(height: 43)
        .padding(.top, 6)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24
            )
            .fill(Color(hex: "839D9A"))
            .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func tabButton(tab: AppTab, icon: String, title: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            ZStack {
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.95) : Color.clear)
                    .frame(width: 76, height: 50)

                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 23, weight: .semibold))

                    Text(title)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(isSelected ? Color(hex: "646F4B") : .white)
            }
            .frame(width: 82, height: 54)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, -16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootTabView()
        .environmentObject(AccessibilitySettings())
}
