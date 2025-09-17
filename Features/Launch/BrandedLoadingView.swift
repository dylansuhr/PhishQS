//
//  BrandedLoadingView.swift
//  PhishQS
//
//  Branded loading screen that perfectly matches iOS launch screen positioning
//  Uses GeometryReader to ensure logo is centered relative to full screen, not safe area
//

import SwiftUI

struct BrandedLoadingView: View {
    var body: some View {
        GeometryReader { geometry in
            Color.phishBlue
                .ignoresSafeArea()
                .overlay(
                    // Logo positioned relative to FULL SCREEN (matching Launch Screen behavior)
                    Image("white_phish_td_transparent")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .position(
                            x: geometry.size.width / 2,  // Center X of full screen
                            y: geometry.size.height / 2  // Center Y of full screen
                        )
                )
        }
        .ignoresSafeArea()
    }
}

struct BrandedLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        BrandedLoadingView()
    }
}