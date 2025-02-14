//
//  Item.swift
//  polmodor
//
//  Created by sedat ateş on 14.02.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
