//
//  DetailedSetlistLineView.swift
//  PhishQS
//
//  Created by Claude on 7/25/25.
//

import SwiftUI

/// Component for displaying individual songs with durations in setlist view
struct DetailedSetlistLineView: View {
    let content: LineContent
    
    enum LineContent {
        case setHeader(String)
        case song(name: String, duration: String?)
    }
    
    var body: some View {
        switch content {
        case .setHeader(let header):
            Text(header)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
            
        case .song(let name, let duration):
            HStack {
                Text(name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let duration = duration {
                    Text(duration)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fontDesign(.monospaced)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 4) {
        DetailedSetlistLineView(content: .setHeader("Set 1:"))
        DetailedSetlistLineView(content: .song(name: "The Moma Dance", duration: "8:45"))
        DetailedSetlistLineView(content: .song(name: "Rift", duration: "4:23"))
        DetailedSetlistLineView(content: .song(name: "Sigma Oasis", duration: nil))
        DetailedSetlistLineView(content: .setHeader("Encore:"))
        DetailedSetlistLineView(content: .song(name: "I Am the Walrus", duration: "4:56"))
    }
    .padding()
}