#! /usr/bin/env bash

# make-release-tag.sh: Tag main with a release version.

readonly PROGNAME=$(basename "$0")
readonly OLDVERS="$1"
readonly NEWVERS="$2"

if [ -z "$OLDVERS" ] || [ -z "$NEWVERS" ]; then
    printf "Usage: %s OLDVERS NEWVERS\n" "$PROGNAME"
    exit 1
fi

set -o errexit
set -o nounset
set -o pipefail

git tag -F - "$NEWVERS" <<EOF
Tag $NEWVERS release.

$(git shortlog "$OLDVERS..HEAD")
EOF

printf "Created tag '%s'\n" "$NEWVERS"

# People set up their remotes in different ways, so we need to check
# which one to dry run against. Choose a remote name that pushes to the
# projectcontour org repository (i.e. not the user's Github fork).
readonly REMOTE=$(git remote -v | awk '$2~/projectcontour\/lint/ && $3=="(push)" {print $1}' | head -n 1)
if [ -z "$REMOTE" ]; then
    printf "%s: unable to determine remote for %s\n" "$PROGNAME" "projectcontour/lint"
    exit 1
fi

readonly BRANCH=$(git branch --show-current)

printf "Testing whether commit can be pushed\n"
git push --dry-run "$REMOTE" "$BRANCH"

printf "Testing whether tag '%s' can be pushed\n" "$NEWVERS"
git push --dry-run "$REMOTE" "$NEWVERS"

printf "Run 'git push %s %s' to push the commit and then 'git push %s %s' to push the tag if you are happy\n" "$REMOTE" "$BRANCH" "$REMOTE" "$NEWVERS"
