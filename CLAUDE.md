# Project Rules & Guidelines

## Development Methodology
- **Clean Architecture & SOLID**: Everything must be decoupled. Use a clear separation between Data, Domain, and UI layers.
- **Extensibility**: Design every component to be easily replaceable or extendable. Logic should be based on interfaces/abstract classes to allow adding new features (e.g., new prayer versions or custom additions) without modifying existing core code.
- **Testing**: Every feature, logic service, or data parser must include unit tests . No feature is considered "Done" without passing tests. 
- **Layered Separation**: Strictly separate business logic from the UI.
- **Data Layer**: Responsible for JSON parsing and API fetching.
- **Domain/Logic Layer**: Responsible for Halachic rules and prayer assembly.
- **Presentation Layer**: Flutter widgets only. No business logic should reside inside widgets.

## Git & Workflow
- **Branching**: Every feature/fix must be on a separate branch: `feature/name`.
- **Approval Flow**: After completing a feature and before running `git commit`, you MUST present a summary of changes and ask for user approval.
- **Commits**: Use descriptive, conventional commit messages.

## Halachic Standard
- **Orthodox only**: This application is a strictly Orthodox Halachic siddur. Every prayer text, comment, variable name, and piece of logic must reflect standard Orthodox Halachic practice exclusively.
- **Forbidden content**: Any reference — direct or indirect — to Reform, Conservative, Egalitarian, Liberal, or Reconstructionist practices is strictly forbidden anywhere in the codebase (source code, comments, JSON data, tests, and documentation). This includes but is not limited to: adding the Imahot (matriarchs) to the Avot blessing, egalitarian liturgical changes, or gender-neutral God-language.
- **Gender variants**: The only permitted gender differences are those that have a recognised Halachic basis in mainstream Orthodox poskim (e.g. a woman reciting a different verbal form). Always cite the Halachic source before adding such a variant.

## Environment & Tech
- Framework: Flutter.
- Primary Language: Hebrew (UI/Content), English (Code/Docs).
- Logic: Offline-first, JSON-driven.