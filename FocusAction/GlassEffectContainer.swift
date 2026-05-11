//
//  GlassEffectContainer.swift
//  FocusAction
//
//

import SwiftUI

/// ガラスエフェクトコンテナ - 子要素をグループ化するためのビューコンテナ
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 0, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            content()
        }
    }
}
