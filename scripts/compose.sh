#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR=""
CONFIG_FILE=""
OUTPUT_FILE=""
MODULES_DIR=""
SOURCE_REF=""

show_help() {
  cat <<EOF
Usage: compose.sh [options]

Options:
  --source <dir>       Source directory containing 'standards/' (default: script parent directory)
  --config <file>      Configuration YAML file (e.g., .dev-standards/config.yml)
  --output <file>      Merged markdown file path (e.g., .dev-standards/styleguide.md)
                       Agent skill bundles are written next to this file
  --modules-dir <dir>  Optional directory for selected standards in their original hierarchy
  --source-ref <ref>   Optional source reference tag/commit for header
  -h, --help           Show this help
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
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --modules-dir)
      MODULES_DIR="$2"
      shift 2
      ;;
    --source-ref)
      SOURCE_REF="$2"
      shift 2
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

if [[ -z "${OUTPUT_FILE}" ]]; then
  echo "Error: --output <file> is required." >&2
  exit 1
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "Error: Config file not found: ${CONFIG_FILE}" >&2
  exit 1
fi

STANDARDS_DIR="${SOURCE_DIR}/standards"
if [[ ! -d "${STANDARDS_DIR}" ]]; then
  echo "Error: standards directory not found at: ${STANDARDS_DIR}" >&2
  exit 1
fi

# Parse config with the Python 3 standard library; no YAML package is required.
PARSED_FILES=$(python3 - "${CONFIG_FILE}" "${STANDARDS_DIR}" << 'EOF'
import sys
import re
from pathlib import Path

config_path = sys.argv[1]
standards_dir = Path(sys.argv[2])

with open(config_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

data = {}
current_key = None
list_keys = {"languages", "architectures", "frameworks", "builds", "tools", "runtimes"}
simple_value_pattern = re.compile(r"[A-Za-z0-9_.-]+")
qualified_tool_pattern = re.compile(r"[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*")


def validate_list_item(key, item):
    if not isinstance(item, str):
        sys.stderr.write(f"Error: invalid value in {key}: {item}\n")
        raise SystemExit(1)
    pattern = qualified_tool_pattern if key == "tools" else simple_value_pattern
    segments = item.split("/")
    if not pattern.fullmatch(item) or any(segment in {".", ".."} for segment in segments):
        sys.stderr.write(f"Error: invalid value in {key}: {item}\n")
        raise SystemExit(1)
    return item


def parse_inline_list(key, value):
    if not (value.startswith("[") and value.endswith("]")):
        return None

    inner = value[1:-1].strip()
    if not inner:
        return []

    items = [item.strip().strip("'\"") for item in inner.split(",")]
    return [validate_list_item(key, item) for item in items]


def selection_values(key, value):
    if value is None:
        return []
    if isinstance(value, str):
        value = [value]
    if not isinstance(value, list):
        sys.stderr.write(f"Error: {key} must be an array\n")
        raise SystemExit(1)
    return [validate_list_item(key, item) for item in value]

for raw_line in lines:
    line = raw_line.split("#")[0].strip()
    if not line:
        continue

    list_match = re.fullmatch(r"-\s*(.+)", line)
    if list_match and current_key in list_keys:
        item = list_match.group(1).strip().strip("'\"")
        data.setdefault(current_key, []).append(validate_list_item(current_key, item))
        continue

    kv_match = re.match(r"^([A-Za-z0-9_.-]+):\s*(.*)", line)
    if kv_match:
        k, v = kv_match.group(1), kv_match.group(2).strip()
        if not v:
            current_key = k
            data[k] = []
        elif k in list_keys and (inline_values := parse_inline_list(k, v)) is not None:
            current_key = None
            data[k] = inline_values
        else:
            current_key = None
            if v.lower() == "true":
                data[k] = True
            elif v.lower() == "false":
                data[k] = False
            else:
                data[k] = v.strip("'\"")

files_to_include = []

# 1. Base and shared contribution workflows
if data.get("base", True) is True:
    for relative in (
        "base.md", "workflows/commit.md", "workflows/pr.md",
        "workflows/branch.md", "workflows/worktree.md",
    ):
        base_file = standards_dir / relative
        if base_file.is_file():
            files_to_include.append(str(base_file))

# 2. Languages
langs = selection_values("languages", data.get("languages") or data.get("language", []))
for lang in langs:
    lang_file = standards_dir / "languages" / f"{lang}.md"
    if lang_file.is_file():
        files_to_include.append(str(lang_file))
    else:
        sys.stderr.write(f"[WARN] Language guide not found: {lang_file}\n")

fws = selection_values("frameworks", data.get("frameworks", []))

# 3. Architecture profiles
# Omission applies framework defaults. A language alone does not imply an
# application architecture. An explicit empty list opts out, and an explicit
# non-empty list replaces inferred defaults.
default_architectures_by_framework = {
    "spring": ["layered-clean"],
    "fastapi": ["feature-layered"],
    "react-ts": ["feature-sliced"],
    "next-ts": ["route-feature"],
}

if "architectures" in data:
    architectures = selection_values("architectures", data.get("architectures"))
else:
    architectures = []
    for fw in fws:
        if fw == "react-ts" and "next-ts" in fws:
            continue
        architectures.extend(default_architectures_by_framework.get(fw, []))
    architectures = list(dict.fromkeys(architectures))

for architecture in architectures:
    architecture_file = standards_dir / "architectures" / f"{architecture}.md"
    if architecture_file.is_file():
        files_to_include.append(str(architecture_file))
    else:
        sys.stderr.write(f"[WARN] Architecture guide not found: {architecture_file}\n")

# 4. Frameworks
for fw in fws:
    fw_file = standards_dir / "frameworks" / f"{fw}.md"
    if fw_file.is_file():
        files_to_include.append(str(fw_file))
    else:
        sys.stderr.write(f"[WARN] Framework guide not found: {fw_file}\n")

# 5. Build tools
builds = selection_values("builds", data.get("builds") or data.get("build", []))
for build in builds:
    build_file = standards_dir / "build-tools" / f"{build}.md"
    if build_file.is_file():
        files_to_include.append(str(build_file))
    else:
        sys.stderr.write(f"[WARN] Build guide not found: {build_file}\n")

# 6. Tools
tools = selection_values("tools", data.get("tools", []))
tool_names = {tool.rsplit("/", 1)[-1] for tool in tools}
if {"prettier", "biome"}.issubset(tool_names):
    sys.stderr.write("Error: Select only one TypeScript formatter: prettier or biome\n")
    raise SystemExit(1)
if {"kover", "jacoco"}.issubset(tool_names):
    sys.stderr.write("Error: Select only one JVM coverage tool: kover or jacoco\n")
    raise SystemExit(1)
for tool in tools:
    tools_dir = standards_dir / "tools"
    if "/" in tool:
        candidates = [tools_dir / f"{tool}.md"]
    else:
        candidates = sorted(tools_dir.rglob(f"{tool}.md"))

    matches = [candidate for candidate in candidates if candidate.is_file()]
    if len(matches) == 1:
        files_to_include.append(str(matches[0]))
    elif len(matches) > 1:
        relative_matches = ", ".join(str(match.relative_to(tools_dir)) for match in matches)
        sys.stderr.write(
            f"Error: Tool guide is ambiguous: {tool}. Use a qualified selector: {relative_matches}\n"
        )
        raise SystemExit(1)
    else:
        sys.stderr.write(f"[WARN] Tool guide not found: {tool}\n")

# 7. Runtimes
runtimes = selection_values("runtimes", data.get("runtimes") or data.get("runtime", []))
for runtime in runtimes:
    runtime_file = standards_dir / "runtime" / f"{runtime}.md"
    if runtime_file.is_file():
        files_to_include.append(str(runtime_file))
    else:
        sys.stderr.write(f"[WARN] Runtime guide not found: {runtime_file}\n")

print("\n".join(files_to_include))
EOF
)

mkdir -p "$(dirname "${OUTPUT_FILE}")"

TMP_OUTPUT="$(mktemp)"

cat << 'EOF' > "${TMP_OUTPUT}"
<!-- Generated by dev-standards. Do not edit directly. -->
EOF

if [[ -n "${SOURCE_REF}" ]]; then
  echo "<!-- Source: ${SOURCE_REF} -->" >> "${TMP_OUTPUT}"
fi
echo "" >> "${TMP_OUTPUT}"

while IFS= read -r filepath; do
  if [[ -n "${filepath}" && -f "${filepath}" ]]; then
    cat "${filepath}" >> "${TMP_OUTPUT}"
    echo "" >> "${TMP_OUTPUT}"
    echo "---" >> "${TMP_OUTPUT}"
    echo "" >> "${TMP_OUTPUT}"
  fi
done <<< "${PARSED_FILES}"

mv "${TMP_OUTPUT}" "${OUTPUT_FILE}"
echo "Successfully generated ${OUTPUT_FILE}"

if [[ -n "${MODULES_DIR}" ]]; then
  PARSED_FILES_MANIFEST="$(mktemp)"
  printf '%s\n' "${PARSED_FILES}" > "${PARSED_FILES_MANIFEST}"

  python3 - \
    "${STANDARDS_DIR}" \
    "${MODULES_DIR}" \
    "${PARSED_FILES_MANIFEST}" <<'PY'
import os
import shutil
import sys
import tempfile
from pathlib import Path

standards_dir = Path(sys.argv[1]).resolve()
modules_dir = Path(sys.argv[2]).resolve()
manifest_path = Path(sys.argv[3])

protected_directories = {
    Path("/").resolve(),
    Path.home().resolve(),
    standards_dir,
    standards_dir.parent,
}
if modules_dir in protected_directories:
    sys.stderr.write(f"Error: refusing unsafe modules directory: {modules_dir}\n")
    raise SystemExit(1)
if modules_dir.is_symlink():
    sys.stderr.write(f"Error: modules directory must not be a symbolic link: {modules_dir}\n")
    raise SystemExit(1)
if modules_dir.exists() and not modules_dir.is_dir():
    sys.stderr.write(f"Error: modules path is not a directory: {modules_dir}\n")
    raise SystemExit(1)

modules_parent = modules_dir.parent
modules_parent.mkdir(parents=True, exist_ok=True)
temporary_dir = Path(tempfile.mkdtemp(prefix=".standards-", dir=modules_parent))

try:
    selected_files = [
        Path(line)
        for line in manifest_path.read_text(encoding="utf-8").splitlines()
        if line
    ]
    for source in selected_files:
        resolved_source = source.resolve()
        try:
            relative_path = resolved_source.relative_to(standards_dir)
        except ValueError:
            sys.stderr.write(f"Error: selected standard is outside standards directory: {source}\n")
            raise SystemExit(1)
        target = temporary_dir / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(resolved_source, target)

    if modules_dir.exists():
        shutil.rmtree(modules_dir)
    os.replace(temporary_dir, modules_dir)
except BaseException:
    shutil.rmtree(temporary_dir, ignore_errors=True)
    raise
PY

  rm -f -- "${PARSED_FILES_MANIFEST}"
  echo "Successfully synchronized selected standards to ${MODULES_DIR}"
fi

# Distribute self-contained skills next to the guide. Native agent directories
# remain project-owned and are modified only when the user invokes a skill.
python3 - "${SOURCE_DIR}/templates/agent-skills" "$(dirname "${OUTPUT_FILE}")" <<'PY'
import os
import sys
import tempfile
from pathlib import Path

templates = Path(sys.argv[1])
destination = Path(sys.argv[2]).absolute()

if not templates.is_dir():
    print("[WARN] No agent skill templates in source; skipping skill distribution", file=sys.stderr)
    raise SystemExit(0)

plan = []
for agent in ("codex", "claude", "gemini"):
    skill = destination / agent / "skills" / "merge-dev-standards"
    for relative in (
        "SKILL.md",
        "references/merge-rules.md",
        "references/codex.md",
        "references/claude.md",
        "references/gemini.md",
        "assets/worktreeinclude",
        "assets/AGENTS.md",
    ):
        source = templates.parent / "agents/AGENTS.md" if relative == "assets/AGENTS.md" else templates / relative
        target = skill / relative
        if not source.is_file():
            raise SystemExit(f"Error: agent skill template not found: {source}")
        for path in (target, *target.parents):
            if path.is_symlink():
                raise SystemExit(f"Error: refusing symbolic link in agent skill destination: {path}")
            if path.exists() and (not path.is_file() if path == target else not path.is_dir()):
                raise SystemExit(f"Error: incompatible agent skill destination: {path}")
            if path == destination:
                break
        plan.append((target, source.read_bytes()))

for target, content in plan:
    if target.is_file() and target.read_bytes() == content:
        continue
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as temporary:
        temporary.write(content)
        temporary_path = Path(temporary.name)
    try:
        os.replace(temporary_path, target)
    finally:
        temporary_path.unlink(missing_ok=True)
print(f"Successfully distributed agent skills to {destination}")
PY
