//
//  MarqueeText.swift
//  PhishQS
//
//  Reusable marquee text component for scrolling long text
//  Extracted from TourCalendarView.swift for better reusability
//

import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let width: CGFloat

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0

    private var shouldMarquee: Bool {
        textWidth > width - 8 // Account for padding
    }

    var body: some View {
        if shouldMarquee {
            // Category 2: Full marquee scroll
            GeometryReader { geometry in
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .fixedSize()
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear.onAppear {
                                textWidth = textGeometry.size.width
                                // Start from right edge when marquee is needed
                                offset = width
                            }
                        }
                    )
                    .offset(x: offset)
                    .frame(height: geometry.size.height, alignment: .center)
                    .clipped()
                    .onAppear {
                        startMarquee()
                    }
            }
            .frame(width: width)
        } else {
            // Category 1: Static display
            Text(text)
                .font(font)
                .foregroundColor(color)
                .background(
                    GeometryReader { textGeometry in
                        Color.clear.onAppear {
                            textWidth = textGeometry.size.width
                        }
                    }
                )
                .frame(width: width)
        }
    }

    private func startMarquee() {
        // UNIFORM SPEED: Consistent pixels per second across all badges
        let scrollSpeedPixelsPerSecond: Double = 25.0 // Easily adjustable speed

        // Calculate total scroll distance (from right edge to completely off left edge)
        let totalDistance = textWidth + width + 20 // +20 for clean exit
        let scrollDuration = totalDistance / scrollSpeedPixelsPerSecond

        // Start from right edge, scroll to left edge and beyond
        offset = width  // Start position: right edge of container

        // Small delay to ensure all marquees start together after reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: scrollDuration).repeatForever(autoreverses: false)) {
                offset = -textWidth - 20  // End position: completely off left edge
            }
        }
    }
}