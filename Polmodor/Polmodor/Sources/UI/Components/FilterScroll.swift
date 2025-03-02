//
//  FilterScroll.swift
//  Polmodor
//
//  Created by sedat ateş on 27.02.2025.
//

import SwiftUI

public struct FilterScroll<Content: View >: View {
    public var content: Content
    var direction: Axis.Set = .vertical
    
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        VStack {
            ScrollView {
                
            }
        }
    }
}

extension FilterScroll {
    public func expanded(_ isExpanded: Bool) -> Self {
        var copy = self
        copy.direction = isExpanded ? .vertical : .horizontal
        return copy
    }
}
