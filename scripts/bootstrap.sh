#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR=""
CONFIG_FILE=""
TARGET_DIR="$(pwd)"
MISE_PROFILE=""
MANIFEST_FILE=""
DRY_RUN="false"
AGENTS_ONLY="false"

show_help() {
  cat <<'EOF'
Usage: bootstrap.sh [options]

Copy agent entry files and selected configuration templates into a consuming
repository. Existing agent files are preserved with a warning. Other existing
files are never overwritten; different content stops the command before copying.

Options:
  --source <dir>          Source directory containing 'templates/' (default: script parent directory)
  --config <file>         Configuration YAML file (e.g., .dev-standards/config.yml)
  --target <dir>          Consuming repository root (default: current directory)
  --mise-profile <name>   Resolve an ambiguous mise template: gradle, maven, go, python, typescript
  --manifest <file>       Write copied/selected repository-relative paths for callers such as CI
  --agents-only           Copy only missing AGENTS.md, CLAUDE.md, and GEMINI.md entry files
  --dry-run               Validate and print the copy plan without changing the target repository
  -h, --help              Show this help
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SOURCE="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${DEFAULT_SOURCE}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --mise-profile)
      MISE_PROFILE="$2"
      shift 2
      ;;
    --manifest)
      MANIFEST_FILE="$2"
      shift 2
      ;;
    --agents-only)
      AGENTS_ONLY="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

if [[ -z "${CONFIG_FILE}" ]]; then
  echo "Error: --config <file> is required." >&2
  exit 1
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "Error: Config file not found: ${CONFIG_FILE}" >&2
  exit 1
fi

if [[ ! -d "${TARGET_DIR}" ]]; then
  echo "Error: Target directory not found: ${TARGET_DIR}" >&2
  exit 1
fi

TEMPLATES_DIR="${SOURCE_DIR}/templates"
if [[ ! -d "${TEMPLATES_DIR}" ]]; then
  echo "Error: templates directory not found at: ${TEMPLATES_DIR}" >&2
  exit 1
fi

python3 - \
  "${CONFIG_FILE}" \
  "${TEMPLATES_DIR}" \
  "${TARGET_DIR}" \
  "${MISE_PROFILE}" \
  "${MANIFEST_FILE}" \
  "${DRY_RUN}" \
  "${AGENTS_ONLY}" <<'PY'
import filecmp
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

config_path = Path(sys.argv[1])
templates_dir = Path(sys.argv[2]).resolve()
target_dir = Path(sys.argv[3]).resolve()
mise_profile = sys.argv[4]
manifest_path = Path(sys.argv[5]) if sys.argv[5] else None
dry_run = sys.argv[6] == "true"
agents_only = sys.argv[7] == "true"

list_keys = {"languages", "architectures", "frameworks", "builds", "tools", "runtimes"}
simple_value_pattern = re.compile(r"[A-Za-z0-9_.-]+")
qualified_tool_pattern = re.compile(r"[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*")
valid_mise_profiles = {"gradle", "maven", "go", "python", "typescript"}


def fail(message):
    sys.stderr.write(f"Error: {message}\n")
    raise SystemExit(1)


def validate_list_item(key, item):
    if not isinstance(item, str):
        fail(f"invalid value in {key}: {item}")
    pattern = qualified_tool_pattern if key == "tools" else simple_value_pattern
    segments = item.split("/")
    if not pattern.fullmatch(item) or any(segment in {".", ".."} for segment in segments):
        fail(f"invalid value in {key}: {item}")
    return item


def parse_inline_list(key, value):
    if not (value.startswith("[") and value.endswith("]")):
        return None
    inner = value[1:-1].strip()
    if not inner:
        return []
    items = [item.strip().strip("'\"") for item in inner.split(",")]
    return [validate_list_item(key, item) for item in items]


def parse_config():
    data = {}
    current_key = None
    with config_path.open("r", encoding="utf-8") as config_file:
        for raw_line in config_file:
            line = raw_line.split("#", 1)[0].strip()
            if not line:
                continue

            list_match = re.fullmatch(r"-\s*(.+)", line)
            if list_match and current_key in list_keys:
                item = list_match.group(1).strip().strip("'\"")
                data.setdefault(current_key, []).append(validate_list_item(current_key, item))
                continue

            key_value_match = re.match(r"^([A-Za-z0-9_.-]+):\s*(.*)", line)
            if not key_value_match:
                continue

            key, value = key_value_match.group(1), key_value_match.group(2).strip()
            if not value:
                current_key = key
                data[key] = []
            elif key in list_keys and (inline_values := parse_inline_list(key, value)) is not None:
                current_key = None
                data[key] = inline_values
            else:
                current_key = None
                if value.lower() == "true":
                    data[key] = True
                elif value.lower() == "false":
                    data[key] = False
                else:
                    data[key] = value.strip("'\"")
    return data


def selection_values(data, key, legacy_key=None):
    value = data.get(key)
    if value is None and legacy_key is not None:
        value = data.get(legacy_key)
    if value is None:
        return []
    if isinstance(value, str):
        value = [value]
    if not isinstance(value, list):
        fail(f"{key} must be an array")
    return [validate_list_item(key, item) for item in value]


data = parse_config()
languages = [] if agents_only else selection_values(data, "languages", "language")
builds = [] if agents_only else selection_values(data, "builds", "build")
tools = [] if agents_only else selection_values(data, "tools")
runtimes = [] if agents_only else selection_values(data, "runtimes", "runtime")
tool_names = [tool.rsplit("/", 1)[-1] for tool in tools]

if {"prettier", "biome"}.issubset(set(tool_names)):
    fail("Select only one TypeScript formatter: prettier or biome")
if {"kover", "jacoco"}.issubset(set(tool_names)):
    fail("Select only one JVM coverage tool: kover or jacoco")

plan = []
planned_targets = {}


def add_template(source_relative, target_relative, selected_by, existing_policy="error"):
    source = templates_dir / source_relative
    if not source.is_file():
        fail(f"template not found for {selected_by}: {source}")
    if target_relative in planned_targets:
        if planned_targets[target_relative] != (source, existing_policy):
            fail(f"multiple templates target the same file: {target_relative}")
        return
    planned_targets[target_relative] = (source, existing_policy)
    plan.append((source, target_relative, selected_by, existing_policy))


add_template("agents/AGENTS.md", "AGENTS.md", "agent-entry", existing_policy="preserve")
add_template("agents/CLAUDE.md", "CLAUDE.md", "agent-entry", existing_policy="preserve")
add_template("agents/GEMINI.md", "GEMINI.md", "agent-entry", existing_policy="preserve")


if languages:
    add_template("editorconfig/.editorconfig", ".editorconfig", "languages")

build_templates = {
    "gradle": ("gradle/libs.versions.toml.example", "gradle/libs.versions.toml"),
    "maven": ("maven/pom.xml.example", "pom.xml"),
}
for build in builds:
    if build in build_templates:
        source_relative, target_relative = build_templates[build]
        add_template(source_relative, target_relative, f"builds:{build}")

tool_templates = {
    "biome": [("biome/biome.json.example", "biome.json")],
    "checkstyle": [("checkstyle/checkstyle.xml", "config/checkstyle/checkstyle.xml")],
    "dependency-cruiser": [
        ("dependency-cruiser/react-ts/.dependency-cruiser.cjs.example", ".dependency-cruiser.cjs")
    ],
    "detekt": [("detekt/detekt.yml", "config/detekt/detekt.yml")],
    "eslint": [("eslint/typescript/eslint.config.mjs.example", "eslint.config.mjs")],
    "golangci-lint": [("golangci-lint/.golangci.yml.example", ".golangci.yml")],
    "pmd": [("pmd/ruleset.xml", "config/pmd/ruleset.xml")],
    "pnpm": [("pnpm/pnpm-workspace.yaml.example", "pnpm-workspace.yaml")],
    "prettier": [
        ("prettier/prettier.config.mjs.example", "prettier.config.mjs"),
        ("prettier/.prettierignore.example", ".prettierignore"),
    ],
    "pyright": [("pyright/pyrightconfig.json.example", "pyrightconfig.json")],
    "ruff": [("ruff/ruff.toml.example", "ruff.toml")],
    "spotbugs": [("spotbugs/exclude-filter.xml", "config/spotbugs/exclude-filter.xml")],
    "vitest": [("vitest/react-ts/vitest.config.ts.example", "vitest.config.ts")],
}
for selector, tool_name in zip(tools, tool_names):
    for source_relative, target_relative in tool_templates.get(tool_name, []):
        add_template(source_relative, target_relative, f"tools:{selector}")

if "mise" in runtimes:
    inferred_profiles = []
    for candidate in [*builds, *languages]:
        if candidate in valid_mise_profiles and candidate not in inferred_profiles:
            inferred_profiles.append(candidate)

    if mise_profile:
        if mise_profile not in valid_mise_profiles:
            choices = ", ".join(sorted(valid_mise_profiles))
            fail(f"invalid --mise-profile '{mise_profile}'. Choose one of: {choices}")
        selected_mise_profile = mise_profile
    elif len(inferred_profiles) == 1:
        selected_mise_profile = inferred_profiles[0]
    elif not inferred_profiles:
        fail("cannot infer a mise template. Pass --mise-profile explicitly")
    else:
        candidates = ", ".join(inferred_profiles)
        fail(
            "multiple mise templates match the selection "
            f"({candidates}). Pass --mise-profile explicitly"
        )

    add_template(
        f"mise/{selected_mise_profile}/mise.toml.example",
        "mise.toml",
        f"runtimes:mise ({selected_mise_profile})",
    )

conflicts = []
states = []
for source, target_relative, selected_by, existing_policy in plan:
    target = target_dir / target_relative
    if target.is_symlink():
        if existing_policy == "preserve":
            states.append(("SKIPPED", source, target, target_relative, selected_by))
        else:
            conflicts.append(f"{target_relative} is a symbolic link")
        continue
    if target.exists():
        if not target.is_file():
            if existing_policy == "preserve":
                states.append(("SKIPPED", source, target, target_relative, selected_by))
            else:
                conflicts.append(f"{target_relative} exists and is not a regular file")
        elif filecmp.cmp(source, target, shallow=False):
            states.append(("UNCHANGED", source, target, target_relative, selected_by))
        elif existing_policy == "preserve":
            states.append(("SKIPPED", source, target, target_relative, selected_by))
        else:
            conflicts.append(f"{target_relative} already exists with different content")
    else:
        states.append(("CREATE", source, target, target_relative, selected_by))

if conflicts:
    sys.stderr.write("Bootstrap stopped before copying files:\n")
    for conflict in conflicts:
        sys.stderr.write(f"- {conflict}\n")
    raise SystemExit(1)

for state, source, target, target_relative, selected_by in states:
    if state == "CREATE" and not dry_run:
        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as temporary_file:
            temporary_path = Path(temporary_file.name)
        try:
            shutil.copy2(source, temporary_path)
            os.replace(temporary_path, target)
        finally:
            temporary_path.unlink(missing_ok=True)
    display_state = "WOULD CREATE" if dry_run and state == "CREATE" else state
    if state == "SKIPPED":
        sys.stderr.write(
            f"[WARN] Existing {target_relative} preserved; "
            "verify that it references the shared standards\n"
        )
    else:
        print(f"{display_state} {target_relative} ({selected_by})")

if manifest_path is not None and not dry_run:
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_contents = "".join(
        f"{target_relative}\n"
        for state, _, _, target_relative, _ in states
        if state != "SKIPPED"
    )
    manifest_path.write_text(manifest_contents, encoding="utf-8")

if not plan:
    print("No configuration templates selected")
elif dry_run:
    print(f"Validated {len(plan)} template(s); target repository was not changed")
else:
    created_count = sum(1 for state, *_ in states if state == "CREATE")
    unchanged_count = sum(1 for state, *_ in states if state == "UNCHANGED")
    skipped_count = sum(1 for state, *_ in states if state == "SKIPPED")
    print(
        f"Bootstrapped {created_count} file(s); "
        f"{unchanged_count} unchanged; {skipped_count} existing agent file(s) preserved"
    )
PY
