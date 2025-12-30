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
    @State private var hasMeasured: Bool = false

    private var shouldMarquee: Bool {
        hasMeasured && textWidth > width - 8 // Account for padding
    }

    var body: some View {
        // Always measure text width first using hidden text
        ZStack {
            // Hidden measurement text
            Text(text)
                .font(font)
                .fixedSize()
                .background(
                    GeometryReader { textGeometry in
                        Color.clear.onAppear {
                            textWidth = textGeometry.size.width
                            hasMeasured = true
                        }
                    }
                )
                .hidden()

            // Visible content
            if shouldMarquee {
                // Full marquee scroll
                GeometryReader { geometry in
                    Text(text)
                        .font(font)
                        .foregroundColor(color)
                        .fixedSize()
                        .offset(x: offset)
                        .frame(height: geometry.size.height, alignment: .center)
                        .clipped()
                        .onAppear {
                            startMarquee()
                        }
                }
                .frame(width: width)
            } else if hasMeasured {
                // Static display (text fits)
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .frame(width: width)
            }
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