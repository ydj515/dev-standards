#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  if [[ -n "${TEST_ROOT}" && -d "${TEST_ROOT}" ]]; then
    rm -rf -- "${TEST_ROOT}"
  fi
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "expected file: $1"
}

assert_absent() {
  [[ ! -e "$1" ]] || fail "expected path to remain absent: $1"
}

architecture_headings=(
  "## 1. 적용 기준"
  "## 2. 기본 구조와 의존 방향"
  "## 3. DTO와 오류 위치"
  "## 4. 샘플 요청 흐름"
  "## 5. 경계와 검증"
  "## 6. 피해야 할 구조"
)

for architecture_file in "${SOURCE_DIR}"/standards/architectures/*.md; do
  for heading in "${architecture_headings[@]}"; do
    grep -Fqx "${heading}" "${architecture_file}" ||
      fail "architecture guide is missing standard heading '${heading}': ${architecture_file}"
  done
  grep -Eq '\.(<ext>|py|ts|tsx)' "${architecture_file}" ||
    fail "architecture guide is missing sample files: ${architecture_file}"
done

consumer_dir="${TEST_ROOT}/consumer"
mkdir -p "${consumer_dir}/.dev-standards"
cat > "${consumer_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
base: true
languages: [kotlin, typescript]
frameworks: [spring, react-ts]
builds: [gradle]
tools:
  - detekt
  - ktlint
  - kover
  - archunit
  - checkstyle
  - pmd
  - spotbugs
  - eslint
  - prettier
  - pnpm
  - frameworks/react-ts/dependency-cruiser
  - frameworks/react-ts/vitest
runtimes: [mise]
YAML

bash "${SCRIPT_DIR}/compose.sh" \
  --source "${SOURCE_DIR}" \
  --config "${consumer_dir}/.dev-standards/config.yml" \
  --output "${consumer_dir}/.dev-standards/styleguide.md" \
  --modules-dir "${consumer_dir}/.dev-standards/standards" \
  --source-ref "dev-standards@main"

assert_file "${consumer_dir}/.dev-standards/styleguide.md"
for relative_path in \
  base.md \
  workflows/commit.md \
  workflows/pr.md \
  workflows/branch.md \
  workflows/worktree.md \
  languages/kotlin.md \
  languages/typescript.md \
  architectures/layered-clean.md \
  architectures/feature-sliced.md \
  frameworks/spring.md \
  frameworks/react-ts.md \
  build-tools/gradle.md \
  tools/languages/kotlin/detekt.md \
  tools/languages/kotlin/ktlint.md \
  tools/languages/kotlin/kover.md \
  tools/languages/java/archunit.md \
  tools/languages/java/checkstyle.md \
  tools/languages/java/pmd.md \
  tools/languages/java/spotbugs.md \
  tools/languages/typescript/eslint.md \
  tools/languages/typescript/prettier.md \
  tools/languages/typescript/pnpm.md \
  tools/frameworks/react-ts/dependency-cruiser.md \
  tools/frameworks/react-ts/vitest.md \
  runtime/mise.md; do
  assert_file "${consumer_dir}/.dev-standards/standards/${relative_path}"
  cmp -s \
    "${consumer_dir}/.dev-standards/standards/${relative_path}" \
    "${SOURCE_DIR}/standards/${relative_path}" || fail "copied standard differs: ${relative_path}"
done

grep -Fq '<!-- Source: dev-standards@main -->' \
  "${consumer_dir}/.dev-standards/styleguide.md" || fail "merged styleguide is missing source ref"
grep -Fq '# Kotlin Guidelines & Standards' \
  "${consumer_dir}/.dev-standards/styleguide.md" || fail "merged styleguide is missing Kotlin"
grep -Fq '# React + TypeScript Guidelines & Standards' \
  "${consumer_dir}/.dev-standards/styleguide.md" || fail "merged styleguide is missing React"
grep -Fq '# Layered Clean Architecture Guidelines & Standards' \
  "${consumer_dir}/.dev-standards/styleguide.md" || fail "merged styleguide is missing Spring's default architecture"
grep -Fq '# Feature-Sliced Frontend Architecture Guidelines & Standards' \
  "${consumer_dir}/.dev-standards/styleguide.md" || fail "merged styleguide is missing React's default architecture"
assert_absent "${consumer_dir}/src"

# Omitted architectures resolve framework defaults only.
default_architecture_dir="${TEST_ROOT}/default-architectures"
mkdir -p "${default_architecture_dir}/.dev-standards"
cat > "${default_architecture_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
base: false
languages: [go, python, typescript]
frameworks: [fastapi, react-ts, next-ts]
YAML

bash "${SCRIPT_DIR}/compose.sh" \
  --source "${SOURCE_DIR}" \
  --config "${default_architecture_dir}/.dev-standards/config.yml" \
  --output "${default_architecture_dir}/.dev-standards/styleguide.md" \
  --modules-dir "${default_architecture_dir}/.dev-standards/standards"

for relative_path in \
  architectures/feature-layered.md \
  architectures/route-feature.md; do
  assert_file "${default_architecture_dir}/.dev-standards/standards/${relative_path}"
done
assert_absent "${default_architecture_dir}/.dev-standards/standards/architectures/domain-oriented.md"
assert_absent "${default_architecture_dir}/.dev-standards/standards/architectures/feature-sliced.md"

# A language selection does not imply an application architecture.
language_only_dir="${TEST_ROOT}/language-only"
mkdir -p "${language_only_dir}/.dev-standards"
cat > "${language_only_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
base: false
languages: [go]
YAML

bash "${SCRIPT_DIR}/compose.sh" \
  --source "${SOURCE_DIR}" \
  --config "${language_only_dir}/.dev-standards/config.yml" \
  --output "${language_only_dir}/.dev-standards/styleguide.md" \
  --modules-dir "${language_only_dir}/.dev-standards/standards"

assert_file "${language_only_dir}/.dev-standards/standards/languages/go.md"
assert_absent "${language_only_dir}/.dev-standards/standards/architectures"

# An explicit architecture list replaces inferred defaults.
explicit_architecture_dir="${TEST_ROOT}/explicit-architecture"
mkdir -p "${explicit_architecture_dir}/.dev-standards"
cat > "${explicit_architecture_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
base: false
languages: [kotlin]
frameworks: [spring]
architectures: [domain-oriented]
YAML

bash "${SCRIPT_DIR}/compose.sh" \
  --source "${SOURCE_DIR}" \
  --config "${explicit_architecture_dir}/.dev-standards/config.yml" \
  --output "${explicit_architecture_dir}/.dev-standards/styleguide.md" \
  --modules-dir "${explicit_architecture_dir}/.dev-standards/standards"

assert_file "${explicit_architecture_dir}/.dev-standards/standards/architectures/domain-oriented.md"
assert_absent "${explicit_architecture_dir}/.dev-standards/standards/architectures/layered-clean.md"

# An explicit empty list disables inferred defaults.
no_architecture_dir="${TEST_ROOT}/no-architecture"
mkdir -p "${no_architecture_dir}/.dev-standards"
cat > "${no_architecture_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
base: false
languages: [go]
frameworks: [spring]
architectures: []
YAML

bash "${SCRIPT_DIR}/compose.sh" \
  --source "${SOURCE_DIR}" \
  --config "${no_architecture_dir}/.dev-standards/config.yml" \
  --output "${no_architecture_dir}/.dev-standards/styleguide.md" \
  --modules-dir "${no_architecture_dir}/.dev-standards/standards"

assert_absent "${no_architecture_dir}/.dev-standards/standards/architectures"

# Framework-scoped tool selectors preserve their hierarchy and remain independently composable.
framework_tool_dir="${TEST_ROOT}/framework-tools"
mkdir -p "${framework_tool_dir}/.dev-standards"
cat > "${framework_tool_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
base: false
tools:
  - frameworks/react-ts/eslint-plugin-react-hooks
  - frameworks/next-ts/eslint-config-next
YAML

bash "${SCRIPT_DIR}/compose.sh" \
  --source "${SOURCE_DIR}" \
  --config "${framework_tool_dir}/.dev-standards/config.yml" \
  --output "${framework_tool_dir}/.dev-standards/styleguide.md" \
  --modules-dir "${framework_tool_dir}/.dev-standards/standards"

for relative_path in \
  tools/frameworks/react-ts/eslint-plugin-react-hooks.md \
  tools/frameworks/next-ts/eslint-config-next.md; do
  assert_file "${framework_tool_dir}/.dev-standards/standards/${relative_path}"
done

# JaCoCo remains independently selectable for Java-centric JVM builds.
jacoco_dir="${TEST_ROOT}/jacoco"
mkdir -p "${jacoco_dir}/.dev-standards"
cat > "${jacoco_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
languages: [java]
builds: [gradle]
tools: [jacoco]
YAML

bash "${SCRIPT_DIR}/compose.sh" \
  --source "${SOURCE_DIR}" \
  --config "${jacoco_dir}/.dev-standards/config.yml" \
  --output "${jacoco_dir}/.dev-standards/styleguide.md" \
  --modules-dir "${jacoco_dir}/.dev-standards/standards"

assert_file "${jacoco_dir}/.dev-standards/standards/tools/languages/java/jacoco.md"

# Omitting base includes contribution guides in both original and merged outputs.
for guide in commit pr branch worktree; do
  cmp -s "${SOURCE_DIR}/standards/workflows/${guide}.md" \
    "${jacoco_dir}/.dev-standards/standards/workflows/${guide}.md" || \
    fail "default base should distribute the ${guide} guide"
done
python3 - "${SOURCE_DIR}" "${jacoco_dir}/.dev-standards/styleguide.md" <<'PY'
import sys
from pathlib import Path

source, output = map(Path, sys.argv[1:])
merged = output.read_text()
for guide in ("commit", "pr", "branch", "worktree"):
    assert (source / "standards/workflows" / f"{guide}.md").read_text() in merged
PY

# A single JVM module must not run two competing coverage plugins.
coverage_conflict_dir="${TEST_ROOT}/coverage-conflict"
mkdir -p "${coverage_conflict_dir}/.dev-standards"
cat > "${coverage_conflict_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
tools: [kover, jacoco]
YAML

if bash "${SCRIPT_DIR}/compose.sh" \
  --source "${SOURCE_DIR}" \
  --config "${coverage_conflict_dir}/.dev-standards/config.yml" \
  --output "${coverage_conflict_dir}/.dev-standards/styleguide.md" \
  --modules-dir "${coverage_conflict_dir}/.dev-standards/standards"; then
  fail "Kover and JaCoCo should not be composable together"
fi
assert_absent "${coverage_conflict_dir}/.dev-standards/styleguide.md"

# A changed selection replaces only the generated standards tree and removes stale modules.
cat > "${consumer_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
base: false
languages: [python]
tools: [ruff, pyright]
YAML

bash "${SCRIPT_DIR}/compose.sh" \
  --source "${SOURCE_DIR}" \
  --config "${consumer_dir}/.dev-standards/config.yml" \
  --output "${consumer_dir}/.dev-standards/styleguide.md" \
  --modules-dir "${consumer_dir}/.dev-standards/standards"

assert_file "${consumer_dir}/.dev-standards/standards/languages/python.md"
assert_file "${consumer_dir}/.dev-standards/standards/tools/languages/python/ruff.md"
assert_file "${consumer_dir}/.dev-standards/standards/tools/languages/python/pyright.md"
assert_absent "${consumer_dir}/.dev-standards/standards/base.md"
assert_absent "${consumer_dir}/.dev-standards/standards/workflows"
assert_absent "${consumer_dir}/.dev-standards/standards/languages/kotlin.md"
assert_absent "${consumer_dir}/.dev-standards/standards/architectures"
assert_file "${consumer_dir}/.dev-standards/config.yml"
assert_absent "${consumer_dir}/src"

python3 "${SCRIPT_DIR}/test-agent-skills.py"

echo "All compose tests passed"
