//
//  WindowProtocol.swift
//  Glimpse
//
//  Created by Glimpse Contributors on 9/1/2026.
//

import AppKit

/// Protocol abstracting NSWindow operations for testability.
@MainActor
protocol WindowProtocol: AnyObject {
    var isVisible: Bool { get }
    func makeKeyAndOrderFront(_ sender: Any?)
    func close()
}

// MARK: - NSWindow Conformance

extension NSWindow: WindowProtocol {}
