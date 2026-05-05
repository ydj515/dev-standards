# Repository Guidelines

## Project Structure & Module Organization
This repository stores shared development standards and LLM code review context for multiple projects. `README.md` explains the repository purpose and release flow. `gemini/base.md` contains common review principles. `gemini/languages/` holds language-specific guides such as `java.md`, `kotlin.md`, `python.md`, and `typescript.md`. `gemini/frameworks/` contains framework-specific extensions such as `spring.md`, `react-ts.md`, and `next-ts.md`. `gemini/config.yaml` is the baseline Gemini code review configuration.

## Build, Test, and Development Commands
This is a documentation-focused repository, so there is no application build step. Use the following commands before and after changes:

- `rg --files`: list all tracked documentation and configuration paths quickly.
- `git diff --check`: detect trailing whitespace and basic diff formatting issues.
- `git status --short`: confirm that only intended files changed before committing.
- `git tag v1.0.0` and `git push origin v1.0.0`: publish a standards release. Adjust the version number to match the change scope.

## Coding Style & Naming Conventions
Write Markdown with short paragraphs, descriptive headings, and concise lists. Use fenced code blocks with language tags for examples. Prefer lowercase file names with hyphens where needed, for example `typescript.md`, `react-ts.md`, and `next-ts.md`. Put language-agnostic rules in `base.md`; add language- or framework-specific guidance only to the matching file under `gemini/languages/` or `gemini/frameworks/`.

## Testing Guidelines
There is no automated test framework. Review changed documents manually and confirm they can be composed by downstream projects. When adding a new rule, include a concrete example or anti-pattern when useful. When editing `gemini/config.yaml`, preserve valid YAML syntax and existing key names unless the configuration contract is intentionally changing.

## Commit & Pull Request Guidelines
The Git history follows Conventional Commits, such as `docs: add kotlin.md` or `build: fix missing trailing newline`. Keep each PR focused on one logical change. In the PR description, summarize the standards area changed, affected languages or frameworks, and whether a release tag is needed. For documentation rendering changes, prefer relevant diffs and usage examples over screenshots.

## Security & Configuration Tips
Store only shared standards in this repository. Do not include project-specific API keys, tokens, internal URLs, or customer data, even in examples. Configuration changes can propagate to multiple repositories, so document the expected impact before changing defaults.
