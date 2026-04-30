#!/usr/bin/env bats
#
# build_worker_yaml_spec.bats — structural assertions for the
# `.github/workflows/build-worker.yaml` reusable workflow.
#
# Reusable workflows can't be unit-tested by exec'ing them, but their
# structural invariants (which inputs exist, which `with:` keys
# forward into docker/build-push-action) are still grep-able. These
# tests lock the #195 changes — `context_path` / `dockerfile_path`
# inputs and the corresponding `context:` / `file:` lines in the 3
# build steps — so a future refactor that drops one of them lights up
# CI red instead of silently breaking nested-Dockerfile downstreams.

bats_require_minimum_version 1.5.0

setup() {
  load "${BATS_TEST_DIRNAME}/test_helper"
  WF="/source/.github/workflows/build-worker.yaml"
  [[ -f "${WF}" ]] || skip "build-worker.yaml not at expected path"
}

# ── Inputs declared (#195) ────────────────────────────────────────────

@test "build-worker.yaml: declares context_path input with default '.'" {
  run grep -A 3 '^      context_path:' "${WF}"
  assert_success
  assert_output --partial 'required: false'
  assert_output --partial 'type: string'
  assert_output --partial 'default: "."'
}

@test "build-worker.yaml: declares dockerfile_path input with empty default" {
  run grep -A 3 '^      dockerfile_path:' "${WF}"
  assert_success
  assert_output --partial 'required: false'
  assert_output --partial 'type: string'
  assert_output --partial 'default: ""'
}

# ── Build steps forward both inputs (#195) ────────────────────────────

@test "build-worker.yaml: 3 build steps all reference inputs.context_path" {
  # Three `docker/build-push-action` calls — test/devel/runtime stages.
  # Each must read context from the new input; `context: .` would
  # silently work for repo-root-Dockerfile callers but break the
  # nested-Dockerfile use case the issue body documented.
  run grep -c 'context: ${{ inputs.context_path }}' "${WF}"
  assert_success
  assert_output "3"
}

@test "build-worker.yaml: 3 build steps all forward inputs.dockerfile_path with format() fallback" {
  # The `||` short-circuit means an empty dockerfile_path falls back
  # to `<context_path>/Dockerfile`, matching docker/build-push-action's
  # implicit default. Override path lets callers pin a non-standard
  # filename.
  run grep -c "file: \${{ inputs.dockerfile_path || format('{0}/Dockerfile', inputs.context_path) }}" "${WF}"
  assert_success
  assert_output "3"
}

@test "build-worker.yaml: no leftover hardcoded 'context: .' lines" {
  # Catches partial-refactor regressions where one of the 3 stages
  # gets reverted by accident. The post-#195 file should have ZERO
  # `context: .` literals — every reference reads from the input.
  run grep -c '^          context: \.$' "${WF}"
  [ "${status}" -ne 0 ] || [ "${output}" = "0" ]
}

@test "build-worker.yaml: no hardcoded Dockerfile path bypassing the input" {
  # Belt-and-braces against someone hard-coding `file: ./Dockerfile`
  # in one stage and forgetting that callers expect the input to flow
  # through.
  run grep -E '^[[:space:]]+file: \./Dockerfile$' "${WF}"
  [ "${status}" -ne 0 ] || [ -z "${output}" ]
}

# ── Backwards compatibility ──────────────────────────────────────────

@test "build-worker.yaml: defaults preserve repo-root-Dockerfile behavior" {
  # Both inputs default such that an existing caller passing only
  # `image_name:` still resolves to context=. and file=./Dockerfile —
  # what every pre-#195 downstream main.yaml expects. Asserts the
  # combination, not just each default in isolation.
  local _ctx _df
  _ctx="$(grep -A 3 '^      context_path:' "${WF}" | grep 'default:' | head -1)"
  _df="$(grep -A 3 '^      dockerfile_path:' "${WF}" | grep 'default:' | head -1)"
  [[ "${_ctx}" == *'"."'* ]]
  [[ "${_df}" == *'""'* ]]
}
