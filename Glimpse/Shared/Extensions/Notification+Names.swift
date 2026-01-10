//
//  Notification+Names.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import Foundation

extension Notification.Name {
    /// Posted when the translation panel should be opened
    static let shouldOpenTranslationPanel = Notification.Name("shouldOpenTranslationPanel")

    /// Posted when captured text is ready for the panel
    static let didCapturePanelText = Notification.Name("didCapturePanelText")
}
