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

run_bootstrap() {
  bash "${SCRIPT_DIR}/bootstrap.sh" --source "${SOURCE_DIR}" "$@"
}

for profile in gradle maven go python typescript; do
  mise_template="${SOURCE_DIR}/templates/mise/${profile}/mise.toml.example"
  grep -Fq 'min_version = "REPLACE_ME"' "${mise_template}" || \
    fail "mise template should declare min_version: ${profile}"
  grep -Fq 'lockfile = true' "${mise_template}" || \
    fail "mise template should enable lockfile: ${profile}"
done

react_dir="${TEST_ROOT}/react"
mkdir -p "${react_dir}/.dev-standards"
cat > "${react_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
base: true
languages: [typescript]
frameworks: [react-ts]
tools:
  - eslint
  - prettier
  - pnpm
  - frameworks/react-ts/dependency-cruiser
  - frameworks/react-ts/vitest
runtimes: [mise]
YAML

run_bootstrap \
  --config "${react_dir}/.dev-standards/config.yml" \
  --target "${react_dir}" \
  --manifest "${react_dir}/manifest.txt"

for relative_path in \
  AGENTS.md \
  CLAUDE.md \
  GEMINI.md \
  .editorconfig \
  eslint.config.mjs \
  .dependency-cruiser.cjs \
  prettier.config.mjs \
  .prettierignore \
  pnpm-workspace.yaml \
  vitest.config.ts \
  mise.toml; do
  assert_file "${react_dir}/${relative_path}"
  grep -Fxq "${relative_path}" "${react_dir}/manifest.txt" || fail "manifest missing ${relative_path}"
done
cmp -s "${react_dir}/AGENTS.md" "${SOURCE_DIR}/templates/agents/AGENTS.md" || \
  fail "AGENTS.md should match the central template"
cmp -s "${react_dir}/CLAUDE.md" "${SOURCE_DIR}/templates/agents/CLAUDE.md" || \
  fail "CLAUDE.md should match the central template"
cmp -s "${react_dir}/GEMINI.md" "${SOURCE_DIR}/templates/agents/GEMINI.md" || \
  fail "GEMINI.md should match the central template"
[[ "$(cat "${react_dir}/CLAUDE.md")" == "@AGENTS.md" ]] || \
  fail "CLAUDE.md should reference only AGENTS.md"
[[ "$(cat "${react_dir}/GEMINI.md")" == "@./AGENTS.md" ]] || \
  fail "GEMINI.md should import only AGENTS.md"
assert_absent "${react_dir}/src"

# Re-running against identical files is intentionally idempotent.
run_bootstrap --config "${react_dir}/.dev-standards/config.yml" --target "${react_dir}"

spring_dir="${TEST_ROOT}/spring"
mkdir -p "${spring_dir}/.dev-standards"
cat > "${spring_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
languages: [kotlin, java]
frameworks: [spring]
builds: [gradle]
tools: [detekt, checkstyle, pmd, spotbugs]
runtimes: [mise]
YAML

run_bootstrap --config "${spring_dir}/.dev-standards/config.yml" --target "${spring_dir}"

for relative_path in \
  .editorconfig \
  gradle/libs.versions.toml \
  config/detekt/detekt.yml \
  config/checkstyle/checkstyle.xml \
  config/pmd/ruleset.xml \
  config/spotbugs/exclude-filter.xml \
  mise.toml; do
  assert_file "${spring_dir}/${relative_path}"
done
assert_absent "${spring_dir}/src"

maven_dir="${TEST_ROOT}/maven"
mkdir -p "${maven_dir}/.dev-standards"
cat > "${maven_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
languages: [java]
builds: [maven]
runtimes: [mise]
YAML

run_bootstrap --config "${maven_dir}/.dev-standards/config.yml" --target "${maven_dir}"
assert_file "${maven_dir}/pom.xml"
assert_file "${maven_dir}/mise.toml"

conflict_dir="${TEST_ROOT}/conflict"
mkdir -p "${conflict_dir}/.dev-standards"
cat > "${conflict_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
languages: [typescript]
tools: [eslint]
YAML
printf 'project-owned\n' > "${conflict_dir}/.editorconfig"

if run_bootstrap --config "${conflict_dir}/.dev-standards/config.yml" --target "${conflict_dir}"; then
  fail "different existing configuration should stop bootstrap"
fi
assert_absent "${conflict_dir}/eslint.config.mjs"
assert_absent "${conflict_dir}/AGENTS.md"
assert_absent "${conflict_dir}/CLAUDE.md"
assert_absent "${conflict_dir}/GEMINI.md"

agents_only_dir="${TEST_ROOT}/agents-only"
mkdir -p "${agents_only_dir}/.dev-standards"
cat > "${agents_only_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
languages: [go]
runtimes: [mise]
YAML
printf 'project-owned editor settings\n' > "${agents_only_dir}/.editorconfig"
printf 'project-owned runtime settings\n' > "${agents_only_dir}/mise.toml"

run_bootstrap \
  --config "${agents_only_dir}/.dev-standards/config.yml" \
  --target "${agents_only_dir}" \
  --manifest "${agents_only_dir}/manifest.txt" \
  --agents-only

for relative_path in AGENTS.md CLAUDE.md GEMINI.md; do
  assert_file "${agents_only_dir}/${relative_path}"
  grep -Fxq "${relative_path}" "${agents_only_dir}/manifest.txt" || \
    fail "agents-only manifest missing ${relative_path}"
done
[[ "$(cat "${agents_only_dir}/.editorconfig")" == "project-owned editor settings" ]] || \
  fail "agents-only bootstrap should preserve .editorconfig"
[[ "$(cat "${agents_only_dir}/mise.toml")" == "project-owned runtime settings" ]] || \
  fail "agents-only bootstrap should preserve mise.toml"
[[ "$(wc -l < "${agents_only_dir}/manifest.txt" | tr -d ' ')" == "3" ]] || \
  fail "agents-only manifest should contain only agent entry files"

ambiguous_dir="${TEST_ROOT}/ambiguous"
mkdir -p "${ambiguous_dir}/.dev-standards"
cat > "${ambiguous_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
languages: [kotlin, typescript]
builds: [gradle]
runtimes: [mise]
YAML

if run_bootstrap --config "${ambiguous_dir}/.dev-standards/config.yml" --target "${ambiguous_dir}"; then
  fail "ambiguous mise selection should require --mise-profile"
fi
assert_absent "${ambiguous_dir}/mise.toml"

run_bootstrap \
  --config "${ambiguous_dir}/.dev-standards/config.yml" \
  --target "${ambiguous_dir}" \
  --mise-profile gradle
assert_file "${ambiguous_dir}/mise.toml"
cmp -s "${ambiguous_dir}/mise.toml" "${SOURCE_DIR}/templates/mise/gradle/mise.toml.example" || \
  fail "explicit mise profile should select the matching template"
assert_absent "${ambiguous_dir}/src"

dry_run_dir="${TEST_ROOT}/dry-run"
mkdir -p "${dry_run_dir}/.dev-standards"
cat > "${dry_run_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
languages: [python]
tools: [languages/python/ruff, pyright]
runtimes: [mise]
YAML

run_bootstrap \
  --config "${dry_run_dir}/.dev-standards/config.yml" \
  --target "${dry_run_dir}" \
  --dry-run
assert_absent "${dry_run_dir}/.editorconfig"
assert_absent "${dry_run_dir}/ruff.toml"
assert_absent "${dry_run_dir}/pyrightconfig.json"
assert_absent "${dry_run_dir}/mise.toml"
assert_absent "${dry_run_dir}/AGENTS.md"
assert_absent "${dry_run_dir}/CLAUDE.md"
assert_absent "${dry_run_dir}/GEMINI.md"

existing_agent_dir="${TEST_ROOT}/existing-agent"
mkdir -p "${existing_agent_dir}/.dev-standards"
cat > "${existing_agent_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
base: false
YAML
printf '%s\n' '# Project-owned agent instructions' > "${existing_agent_dir}/AGENTS.md"
printf '%s\n' '# Project-owned Gemini instructions' > "${existing_agent_dir}/GEMINI.md"

run_bootstrap \
  --config "${existing_agent_dir}/.dev-standards/config.yml" \
  --target "${existing_agent_dir}" \
  --manifest "${existing_agent_dir}/manifest.txt"
grep -Fqx '# Project-owned agent instructions' "${existing_agent_dir}/AGENTS.md" || \
  fail "existing AGENTS.md should be preserved"
grep -Fqx '# Project-owned Gemini instructions' "${existing_agent_dir}/GEMINI.md" || \
  fail "existing GEMINI.md should be preserved"
assert_file "${existing_agent_dir}/CLAUDE.md"
if grep -Fxq 'AGENTS.md' "${existing_agent_dir}/manifest.txt"; then
  fail "preserved AGENTS.md should not be added to the bootstrap manifest"
fi
grep -Fxq 'CLAUDE.md' "${existing_agent_dir}/manifest.txt" || \
  fail "created CLAUDE.md should be added to the bootstrap manifest"
if grep -Fxq 'GEMINI.md' "${existing_agent_dir}/manifest.txt"; then
  fail "preserved GEMINI.md should not be added to the bootstrap manifest"
fi

empty_dir="${TEST_ROOT}/empty"
mkdir -p "${empty_dir}/.dev-standards"
cat > "${empty_dir}/.dev-standards/config.yml" <<'YAML'
version: 1
base: false
languages: []
frameworks: []
builds: []
tools: []
runtimes: []
YAML

run_bootstrap --config "${empty_dir}/.dev-standards/config.yml" --target "${empty_dir}"
assert_file "${empty_dir}/AGENTS.md"
assert_file "${empty_dir}/CLAUDE.md"
assert_file "${empty_dir}/GEMINI.md"
[[ "$(find "${empty_dir}" -type f | wc -l | tr -d ' ')" == "4" ]] || \
  fail "empty standard selection should create only agent entry files"

echo "All bootstrap tests passed"
