# Project Rules & Guidelines

## Development Methodology
- **Clean Architecture & SOLID**: Everything must be decoupled. Use a clear separation between Data, Domain, and UI layers.
- **Extensibility**: Design every component to be easily replaceable or extendable. Logic should be based on interfaces/abstract classes to allow adding new features (e.g., new prayer versions or custom additions) without modifying existing core code.
- **Testing**: Every feature, logic service, or data parser must include unit tests. No feature is considered "Done" without passing tests.
- **Layered Separation**: Strictly separate business logic from the UI.
- **Data Layer**: Responsible for JSON parsing and API fetching.
- **Domain/Logic Layer**: Responsible for Halachic rules and prayer assembly.
- **Presentation Layer**: Flutter widgets only. No business logic should reside inside widgets.

## Git & Workflow
- **Branching**: Every feature/fix must be on a separate branch: `feature/name`.
- **Approval Flow**: After completing a feature and before running `git commit`, you MUST present a summary of changes and ask for user approval.
- **Commits**: Use descriptive, conventional commit messages.

## Environment & Tech
- Framework: Flutter.
- Primary Language: Hebrew (UI/Content), English (Code/Docs).
- Logic: Offline-first, JSON-driven.