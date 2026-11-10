#!/usr/bin/env bash
# Load the config headless and run the smoke tests.
#   ./test/run.sh              uses the packages already installed in this repo
#   OFFLINE=1 ./test/run.sh    never try to download packages
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
extra=()
if [ "${OFFLINE:-0}" = 1 ]; then
  # Survives init-package.el redefining the function.
  extra=(--eval "(advice-add 'my/use-package-ensure :override #'ignore)")
fi
exec "${EMACS:-emacs}" --batch --init-directory "$dir" \
  ${extra[@]+"${extra[@]}"} \
  -l "$dir/early-init.el" -l "$dir/init.el" \
  -l "$dir/test/smoke-test.el" \
  -f ert-run-tests-batch-and-exit
