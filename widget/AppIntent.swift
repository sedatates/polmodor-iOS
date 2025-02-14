//
//  AppIntent.swift
//  widget
//
//  Created by sedat ateş on 14.02.2025.
//

import AppIntents
import WidgetKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Configure the widget.")

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😀")
    var favoriteEmoji: String

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
