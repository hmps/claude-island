# Claude Island

macOS menu bar app for monitoring and interacting with Claude Code sessions. Displays a Dynamic Island-style UI in the notch area.

## Fork Context

Upstream: `farouqaldori/claude-island` (maintainer inactive). We cherry-pick from upstream PRs and add our own features.

## PR Integration Rules (Minimize Merge Conflicts)

1. **Keep logic in services, not views.** Views should call into service/utility files. Don't inline business logic (e.g. raw `Process()` calls) in SwiftUI views.
2. **Use existing infra.** `ProcessExecutor`, `TmuxPathFinder`, `TmuxController`, etc. Don't use `Process()` directly.
3. **Model field additions are OK.** Small, additive changes to models auto-merge cleanly.
4. **Most conflict-prone files** (minimize touching): `ClaudeInstancesView.swift`, `NotchView.swift`, `SessionState.swift`, `SessionStore.swift`
5. **Prefer adding methods to existing service files** over creating new files (avoids `project.pbxproj` conflicts).
6. **When new files are unavoidable**, commit `project.pbxproj` changes separately.
7. **Keep signing/dev team config** in a separate commit from feature work.

## Architecture

- **Services/**: Business logic (tmux, hooks, state management, terminal focus)
- **Models/**: Data types (`SessionState`, `SessionPhase`, etc.)
- **UI/Views/**: SwiftUI views (keep thin)
- **Resources/**: Hook scripts (`claude-island-state.py`)
