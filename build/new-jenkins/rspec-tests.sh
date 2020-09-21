#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

# calculate which group to run
max=$((CI_NODE_TOTAL * DOCKER_PROCESSES))
group=$(((max-CI_NODE_TOTAL * TEST_PROCESS) - CI_NODE_INDEX))
maybeOnlyFailures=()
if [ "${1-}" = 'only-failures' ] && [ ! "${RSPEC_LOG:-}" == "1" ]; then
  maybeOnlyFailures=("--test-options" "'--only-failures'")
fi

# we want actual globbing of individual elements for passing argument literals
# shellcheck disable=SC2068
bundle exec parallel_rspec . \
  --pattern "$TEST_PATTERN" \
  --exclude-pattern "$EXCLUDE_TESTS" \
  -n "$max" \
  --only-group "$group" \
  --verbose \
  --group-by runtime \
  --runtime-log log/parallel-runtime-rspec.log \
  ${maybeOnlyFailures[@]}
