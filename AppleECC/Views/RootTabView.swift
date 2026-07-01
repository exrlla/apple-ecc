//
//  RootTabView.swift
//  AppleECC
//
//  Created by Apple on 6/29/26.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem{
                    Image(systemName: "camera")
                    Text("Capture")
                }
            CalendarView()
                .tabItem{
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            GardenView()
                .tabItem{
                    Image(systemName: "leaf")
                    Text("Garden")
                }
            LibraryView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Library")
                }
        }
    }
}

#Preview {
    RootTabView()
}
