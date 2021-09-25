#!/bin/bash

# quietly stash changes in working tree while leaving the index intact
git stash -q --keep-index
# check if all files in index are pepified
dir=`git rev-parse --show-toplevel`;
# get the file names in the staged area thar are either new or modified
files_in_index=`git diff --name-only --diff-filter=ACMRTUXB --staged HEAD -- $dir`
# pass test || fail test
`/Data/tools/git_tools/hook_installer/perltidy-batch.pm -c` && tidy=1 || tidy=0
`/Data/tools/git_tools/hook_installer/pep8ify-batch.pm -c` && peped=1 || peped=0

# quietly reapply the stashed changes in the working tree
git stash pop -q
if [[ $peped -eq 0 || $tidy -eq 0 ]]; then # true if one or more of tests fail.
    exit 1 # exit with error code
fi
