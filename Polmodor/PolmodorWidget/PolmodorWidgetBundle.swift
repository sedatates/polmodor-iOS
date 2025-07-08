//
//  PolmodorWidgetBundle.swift
//  PolmodorWidget
//
//  Created by sedat ateş on 2.03.2025.
//

import SwiftUI
import WidgetKit

@main
struct PolmodorWidgetBundle: WidgetBundle {
    var body: some Widget {
        PolmodorWidget()
        PolmodorWidgetControl()
        PolmodorWidgetLiveActivity()
    }
}
