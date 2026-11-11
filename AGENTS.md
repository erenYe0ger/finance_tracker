# AI Coding Agent Guidelines

## 1. Project Principles
- Make the smallest correct change that satisfies the task.
- Prefer simple, readable and maintainable implementations.
- Avoid unnecessary abstractions, dependencies, files and directories.
- Do not overengineer.
- Preserve the existing architecture and coding conventions.

## 2. Repository Exploration
- Inspect only files relevant to the requested task.
- Never use unrestricted recursive scans.
- Never scan `.venv`, `.git`, `build`, `.dart_tool`, caches or generated directories.
- Never read or print `.env`, credentials, secrets or private configuration.
- Prefer targeted file searches and directory listings.
- Do not repeatedly read files already inspected unless they have changed.
- Do not inspect Flutter files when working exclusively on the backend, and vice versa.

## 3. Token and Tool Efficiency
- Avoid unnecessary tool calls and repeated model interactions.
- Do not dump large directory listings or entire files when targeted inspection is sufficient.
- Use concise command output.
- Avoid repeating information already established in the conversation or project files.
- Do not create unnecessary plans, todos or subagents for straightforward tasks.
- Use subagents only when independent parallel work provides a clear benefit.
- Never sacrifice correctness, security or verification to reduce token usage.

## 4. Implementation
- Reuse existing dependencies and utilities.
- Do not introduce new packages without a clear technical justification.
- Avoid unnecessary helper layers, repositories, factories and wrappers.
- Keep functions focused and code understandable.
- Add comments only when they explain non-obvious decisions.
- Do not modify unrelated files.

## 5. Verification
- Verify only the functionality affected by the change.
- Prefer focused commands and manual checks.
- Do not create automated tests or test directories unless explicitly requested.
- Never claim something was verified if it was not actually executed.
- Report verification limitations honestly.

## 6. Project Boundaries
- Follow the requested phase and scope strictly.
- Do not implement future features prematurely.
- Do not change technology choices without discussing them first.
- Never modify secrets or environment files.
- Preserve existing database data and migration history.

## 7. Final Response
Report briefly:
- What changed.
- Files created or modified.
- Verification performed and results.
- Remaining limitations or decisions requiring approval.
