//
//  CustomeNavigationLink.swift
//  Polmodor
//
//  Created by sedat ateş on 28.02.2025.
//

import SwiftUI

struct CustomNavigationLink<D: View, L: View>: View {
  @ViewBuilder var destination: () -> D
  @ViewBuilder var label: () -> L
  
  @State private var isActive = false
  
  var body: some View {
    Button {
      withAnimation {
        isActive = true
      }
    } label: {
      label()
    }
    .onAppear {
      isActive = false
    }
    .overlay {
      NavigationLink(isActive: $isActive) {
        destination()
      } label: {
        EmptyView()
      }
      .opacity(0)
    }
  }
}
