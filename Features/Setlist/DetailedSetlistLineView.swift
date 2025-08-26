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
        case song(name: String, duration: String?, transitionMark: String?, durationColor: Color?)
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
            
        case .song(let name, let duration, let transitionMark, let durationColor):
            HStack {
                HStack(spacing: 2) {
                    Text(name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let transitionMark = transitionMark, !transitionMark.isEmpty {
                        Text(transitionMark)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let duration = duration {
                    Text(duration)
                        .font(.body)
                        .foregroundColor(durationColor ?? .secondary)
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
        DetailedSetlistLineView(content: .song(name: "The Moma Dance", duration: "8:45", transitionMark: " >", durationColor: .orange))
        DetailedSetlistLineView(content: .song(name: "Rift", duration: "4:23", transitionMark: nil, durationColor: .green))
        DetailedSetlistLineView(content: .song(name: "Sigma Oasis", duration: nil, transitionMark: " ->", durationColor: nil))
        DetailedSetlistLineView(content: .setHeader("Encore:"))
        DetailedSetlistLineView(content: .song(name: "I Am the Walrus", duration: "4:56", transitionMark: nil, durationColor: .red))
    }
    .padding()
}