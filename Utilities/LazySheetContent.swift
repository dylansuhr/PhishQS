//
//  LazySheetContent.swift
//  PhishQS
//
//  Wrapper that defers sheet content initialization until presented
//  Prevents cold-start stickiness from eager view initialization
//

import SwiftUI

struct LazySheetContent<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
    }
}
