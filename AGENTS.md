# Repository Guidelines

## Project Structure & Module Organization
This repository stores shared development standards and AI assistant (Gemini, Claude, Antigravity) guidelines in a single unified source of truth.
- `standards/`: Composable development guidance grouped by base, language, architecture, framework, build-tools, tools, and runtime. Tool guides live under `tools/languages/<language>/` or `tools/frameworks/<framework>/`.
- `templates/`: Agent entry files and configuration templates copied into consuming repositories by the explicit bootstrap command.
- `scripts/compose.sh`: Composes `.dev-standards/styleguide.md` and synchronizes selected source documents under `.dev-standards/standards/`.
- `scripts/bootstrap.sh`: One-time, non-overwriting configuration bootstrap; it never creates application source directories.

## Build, Test, and Development Commands
This is a documentation and standard repository. Use the following commands for validation:
- `./scripts/compose.sh --config <test.yml> --output <output.md>`: Test guide composition locally.
- `./scripts/test-compose.sh`: Validate merged and per-module standard outputs, including stale module removal.
- `./scripts/test-bootstrap.sh`: Validate template mapping, idempotency, conflict handling, and the no-scaffold contract.
- `git diff --check`: Detect trailing whitespace and formatting issues.
- `git status --short`: Confirm changed files before committing.

## Coding Style & Naming Conventions
Write Markdown with clear headings, actionable guidelines, and fenced code blocks with language tags. Follow kebab-case for filenames under `standards/` (e.g., `react-ts.md`, `fastapi.md`). Do not maintain duplicate guidelines across separate folders.
