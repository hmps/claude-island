//
//  ProcessWatcher.swift
//  ClaudeIsland
//
//  Watches Claude processes for exit and periodically refreshes active session state.
//  Uses DispatchSource for instant process exit detection (no polling).
//

import Foundation
import os.log

actor ProcessWatcher {
    static let shared = ProcessWatcher()

    private static let logger = Logger(subsystem: "com.claudeisland", category: "ProcessWatcher")

    /// Active process exit watchers, keyed by sessionId
    private nonisolated(unsafe) var watchers: [String: DispatchSourceProcess] = [:]

    /// Periodic state refresh task
    private var refreshTask: Task<Void, Never>?

    /// Refresh interval for active sessions (5 seconds)
    private let refreshIntervalNs: UInt64 = 5_000_000_000

    // MARK: - Process Exit Watching

    /// Start watching a process for exit via kernel notification
    func watch(pid: Int, sessionId: String) {
        stop(sessionId: sessionId)

        let source = DispatchSource.makeProcessSource(
            identifier: pid_t(pid),
            eventMask: .exit,
            queue: .global(qos: .utility)
        )
        source.setEventHandler {
            Task { await ProcessWatcher.shared.handleExit(sessionId: sessionId, pid: pid) }
        }
        source.resume()
        watchers[sessionId] = source

        // Edge case: process may have exited between PID assignment and watch start
        if !Self.isProcessRunning(pid: pid) {
            handleExit(sessionId: sessionId, pid: pid)
        }
    }

    /// Stop watching a specific session's process
    func stop(sessionId: String) {
        watchers[sessionId]?.cancel()
        watchers.removeValue(forKey: sessionId)
    }

    /// Handle a watched process exiting — marks the session as ended via SessionStore
    private func handleExit(sessionId: String, pid: Int) {
        stop(sessionId: sessionId)
        Self.logger.info("Process \(pid) exited, ending session \(sessionId.prefix(8))")
        Task {
            await SessionStore.shared.process(.processExited(sessionId: sessionId))
        }
    }

    /// Check if a process is still running
    private nonisolated static func isProcessRunning(pid: Int) -> Bool {
        kill(Int32(pid), 0) == 0
    }

    // MARK: - Periodic State Refresh

    /// Start periodic file sync for active sessions (keeps UI fresh between hook events)
    func startPeriodicRefresh() {
        guard refreshTask == nil else { return }

        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: refreshIntervalNs)
                guard !Task.isCancelled else { break }
                await refreshActiveSessions()
            }
        }
        Self.logger.info("Started periodic state refresh")
    }

    /// Stop all watching and periodic refresh
    func stopAll() {
        refreshTask?.cancel()
        refreshTask = nil
        for (_, watcher) in watchers { watcher.cancel() }
        watchers.removeAll()
        Self.logger.info("Stopped process watching and periodic refresh")
    }

    /// Trigger file sync for sessions that are actively processing
    private func refreshActiveSessions() async {
        let sessions = await SessionStore.shared.allSessions()
        for session in sessions {
            switch session.phase {
            case .processing, .waitingForApproval:
                await SessionStore.shared.requestFileSync(sessionId: session.sessionId, cwd: session.cwd)
            default:
                break
            }
        }
    }
}
