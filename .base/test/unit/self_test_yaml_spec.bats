#!/usr/bin/env bats
#
# self_test_yaml_spec.bats — structural assertions for the
# `.github/workflows/self-test.yaml` workflow.
#
# Locks two cumulative invariants:
#
# 1. #305 actionlint gate (original): an `actionlint` job runs
#    rhysd/actionlint via Docker against the workflows tree, and the
#    downstream jobs (test / integration-e2e / behavioural) declare
#    `needs:` on actionlint so they cannot start until actionlint
#    passes.
#
# 2. #317 P1 classifier + buildx GHA cache: a `classify` job emits
#    `code_changed` + `behavioural_relevant` outputs based on PR diff
#    against the doc-only allow-list and behavioural block-list; the
#    `test` job always runs (required check) but short-circuits to
#    SUCCESS on doc-only PRs; `integration-e2e` + `behavioural` gate
#    via job-level `if:`. All three test-tools image builds use
#    docker/build-push-action with shared `scope=test-tools` GHA cache.

bats_require_minimum_version 1.5.0

setup() {
  load "${BATS_TEST_DIRNAME}/test_helper"
  WF="/source/.github/workflows/self-test.yaml"
  [[ -f "${WF}" ]] || skip "self-test.yaml not at expected path"
}

# ── actionlint job declared (#305) ────────────────────────────────────

@test "self-test.yaml: declares actionlint job" {
  run grep -E '^  actionlint:' "${WF}"
  assert_success
}

@test "self-test.yaml: actionlint job runs rhysd/actionlint via Docker with pinned tag" {
  run grep -E 'rhysd/actionlint:[0-9]+\.[0-9]+\.[0-9]+' "${WF}"
  assert_success
}

# ── classify job declared with both outputs (#317) ────────────────────

@test "self-test.yaml: declares classify job (#317)" {
  run grep -E '^  classify:' "${WF}"
  assert_success
}

@test "self-test.yaml: classify job declares code_changed output (#317)" {
  run awk '/^  classify:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial 'code_changed: ${{ steps.diff.outputs.code_changed }}'
}

@test "self-test.yaml: classify job declares behavioural_relevant output (#317)" {
  run awk '/^  classify:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial 'behavioural_relevant: ${{ steps.diff.outputs.behavioural_relevant }}'
}

@test "self-test.yaml: classify uses doc-only allow-list 'doc/**' + 'README.md' + 'LICENSE' (#317)" {
  run awk '/^  classify:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial "':!doc/**'"
  assert_output --partial "':!README.md'"
  assert_output --partial "':!LICENSE'"
}

@test "self-test.yaml: classify uses behavioural block-list entrypoint + compose + Dockerfile + wrappers + init/upgrade + workflows (#317)" {
  run awk '/^  classify:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial "'script/entrypoint.sh'"
  assert_output --partial "'compose.yaml'"
  assert_output --partial "'dockerfile/Dockerfile.example'"
  assert_output --partial "'dockerfile/Dockerfile.test-tools'"
  assert_output --partial "'script/docker/build.sh'"
  assert_output --partial "'script/docker/run.sh'"
  assert_output --partial "'script/docker/exec.sh'"
  assert_output --partial "'script/docker/stop.sh'"
  assert_output --partial "'test/behavioural/**'"
  assert_output --partial "'init.sh' 'upgrade.sh'"
  assert_output --partial "'.github/workflows/**'"
}

@test "self-test.yaml: classify defaults code_changed/behavioural_relevant to true on non-PR events (#317)" {
  run awk '/^  classify:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  # Both outputs branch to 'true' when EVENT_NAME != pull_request
  assert_output --partial '!= "pull_request"'
  assert_output --partial 'code_changed=true'
  assert_output --partial 'behavioural_relevant=true'
}

# ── Downstream jobs gate on actionlint + classify (#305 / #317) ───────

@test "self-test.yaml: test job declares needs on actionlint AND classify (#317)" {
  run awk '/^  test:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial 'needs: [actionlint, classify]'
}

@test "self-test.yaml: integration-e2e job declares needs on actionlint AND classify (#317)" {
  run awk '/^  integration-e2e:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial 'needs: [actionlint, classify]'
}

@test "self-test.yaml: behavioural job declares needs on actionlint AND classify (#317)" {
  run awk '/^  behavioural:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial 'needs: [actionlint, classify]'
}

# ── Doc-only short-circuit + conditional gating (#317) ────────────────

@test "self-test.yaml: test job has doc-only short-circuit step (#317)" {
  run awk '/^  test:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial "needs.classify.outputs.code_changed == 'false'"
  assert_output --partial "Doc-only short-circuit"
}

@test "self-test.yaml: test job real steps gated by code_changed == 'true' (#317)" {
  run awk '/^  test:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  # At least one step should be gated by the positive branch
  assert_output --partial "needs.classify.outputs.code_changed == 'true'"
}

@test "self-test.yaml: integration-e2e job-level if: gates on code_changed (#317)" {
  run awk '/^  integration-e2e:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial "if: needs.classify.outputs.code_changed == 'true'"
}

@test "self-test.yaml: behavioural job-level if: gates on code_changed (#317 P1)" {
  run awk '/^  behavioural:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial "if: needs.classify.outputs.code_changed == 'true'"
}

# ── buildx GHA cache on test-tools builds (#317) ──────────────────────

@test "self-test.yaml: test job uses docker/build-push-action with GHA cache scope=test-tools (#317)" {
  run awk '/^  test:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial 'uses: docker/build-push-action@v6'
  assert_output --partial 'cache-from: type=gha,scope=test-tools'
  assert_output --partial 'cache-to: type=gha,scope=test-tools,mode=max'
}

@test "self-test.yaml: behavioural job uses docker/build-push-action with GHA cache scope=test-tools (#317)" {
  run awk '/^  behavioural:/{flag=1; next} /^  [a-z]/{flag=0} flag' "${WF}"
  assert_success
  assert_output --partial 'uses: docker/build-push-action@v6'
  assert_output --partial 'cache-from: type=gha,scope=test-tools'
  assert_output --partial 'cache-to: type=gha,scope=test-tools,mode=max'
}
