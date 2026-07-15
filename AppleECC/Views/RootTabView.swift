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
    private var backgroundGradient: LinearGradient {
        if accessibilitySettings.colorblindAssistMode {
            LinearGradient(
                colors: [Color(hex: "CFE0F0"), Color(hex: "9DBEDD"), Color(hex: "6E93B8")],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            LinearGradient(
                colors: [Color(hex: "D3DDC8"), Color(hex: "AABA9E"), Color(hex: "7E9374")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    @State private var selectedTab: AppTab = .capture
    @State private var showingAccessibilitySettings = false
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .topTrailing) {
                backgroundGradient.ignoresSafeArea()
                
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
                
                Button {
                    showingAccessibilitySettings = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(14)
                }
                .padding(.top, -20)
                .padding(.trailing, 10)
            }
            
            customTabBar
        }
        .largeBoldTextEnabled()
        .sheet(isPresented: $showingAccessibilitySettings) {
            AccessibilitySettingsView()
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(tab: .capture, icon: "binoculars", title: "Capture")
            tabButton(tab: .calendar, icon: "calendar", title: "Calendar")
            tabButton(tab: .garden, icon: "leaf", title: "Garden")
            tabButton(tab: .library, icon: "book", title: "Library")
        }
        .padding(.horizontal, 10)
        .frame(height: 43)
        .padding(.top, 6)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24
            )
            .fill(Color(hex: "6B5642"))
            .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func tabButton(tab: AppTab, icon: String, title: String) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            selectedTab = tab
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color(hex: "8C7355"))
                        .frame(width: 80, height: 60)
                }
                
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                    Text(title)
                        .font(.geistPixel(11))
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .offset(y: 10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootTabView()
        .environmentObject(AccessibilitySettings())
}

