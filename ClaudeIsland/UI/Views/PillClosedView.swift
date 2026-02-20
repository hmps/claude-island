//
//  PillClosedView.swift
//  ClaudeIsland
//
//  Compact pill-shaped closed state for external displays without a notch.
//  Extracted from NotchView to keep pill-specific view code isolated.
//

import SwiftUI

/// Pill closed state: [crab] [X running, Y idle] [spinner?]
struct PillClosedView: View {
    let instances: [SessionState]
    let isAnyProcessing: Bool
    let isProcessing: Bool
    let hasPendingPermission: Bool
    let hasWaitingForInput: Bool
    let activityNamespace: Namespace.ID
    let isSource: Bool

    var body: some View {
        HStack(spacing: 10) {
            ClaudeCrabIcon(size: 11, animateLegs: isAnyProcessing)
                .matchedGeometryEffect(id: "crab", in: activityNamespace, isSource: isSource)

            statusText
                .font(.system(size: 11, weight: .medium))
                .fixedSize()

            if isProcessing || hasPendingPermission {
                ProcessingSpinner()
                    .matchedGeometryEffect(id: "spinner", in: activityNamespace, isSource: isSource)
                    .frame(width: 12, height: 12)
            } else if hasWaitingForInput {
                ReadyForInputIndicatorIcon(size: 12, color: TerminalColors.green)
                    .matchedGeometryEffect(id: "spinner", in: activityNamespace, isSource: isSource)
            }
        }
        .padding(.horizontal, 12)
    }

    /// Attributed status with distinct colors for running vs idle
    private var statusText: Text {
        let running = instances.filter { $0.phase.isActive }.count
        let idle = instances.count - running
        var result = Text("")
        if running > 0 {
            result = result + Text("\(running) running").foregroundColor(.white)
        }
        if running > 0 && idle > 0 {
            result = result + Text("  ").foregroundColor(.clear)
        }
        if idle > 0 {
            result = result + Text("\(idle) idle").foregroundColor(.white.opacity(0.4))
        }
        return result
    }
}
