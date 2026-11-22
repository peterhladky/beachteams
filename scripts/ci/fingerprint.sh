#!/usr/bin/env bash
# Prints a hash of the current working tree state (status + diff). Used to prove that a
# read-only agent did not modify anything: compare the hash before and after the run.
set -euo pipefail
{ git status --porcelain --untracked-files=all; git diff; } | sha256sum | cut -d' ' -f1
