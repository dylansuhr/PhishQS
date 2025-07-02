//
//  ContentView.swift
//  PhishQS
//
//  Created by Dylan Suhr on 5/28/25.
//

import SwiftUI

// Entry point for the app UI (currently a placeholder)
struct ContentView: View {
    var body: some View {
        VStack {
            // SF Symbol used as a placeholder graphic
            Image(systemName: "globe")
                .imageScale(.large)        // scale to large size
                .foregroundStyle(.tint)    // use system tint color (default blue)

            // static placeholder text
            Text("Hello, world!")
        }
        .padding() // padding around entire VStack
    }
}

// Preview block used for canvas previews in Xcode
#Preview {
    ContentView()
}
