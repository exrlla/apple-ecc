//
//  RootTabView.swift
//  AppleECC
//
//  Created by Apple on 6/29/26.
//

import SwiftUI

struct RootTabView: View {
    let backgroundColor = Color(red: 191/255, green: 210/255, blue: 191/255)

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.shadowColor = UIColor.clear

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().backgroundColor = UIColor.white
        UITabBar.appearance().isTranslucent = false
    }

    var body: some View {
        TabView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                CaptureView()
            }
            .tabItem {
                Image(systemName: "binoculars")
                Text("Capture")
            }

            ZStack {
                backgroundColor.ignoresSafeArea()
                CalendarView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Calendar")
            }

            ZStack {
                backgroundColor.ignoresSafeArea()
                GardenView()
            }
            .tabItem {
                Image(systemName: "leaf")
                Text("Garden")
            }

            ZStack {
                backgroundColor.ignoresSafeArea()
                LibraryView()
            }
            .tabItem {
                Image(systemName: "book")
                Text("Library")
            }
        }
        .tint(Color(hex: "646F4B"))
        .onAppear {
            let tabBar = UITabBar.appearance()
            tabBar.layer.cornerRadius = 26
            tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            tabBar.layer.masksToBounds = true
        }
    }
}


#Preview {
    RootTabView()
}

