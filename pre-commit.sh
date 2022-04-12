#!/bin/sh

if git rev-parse --verify HEAD >/dev/null 2>&1
then
	against=HEAD
else
	# Initial commit: diff against an empty tree object
	against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

# Redirect output to stderr.
exec 1>&2

NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'

if [ -z "$GIT_DIR" ]; then
  # manual invocation: list all changed files
  FILES="git diff-index $against --name-only --diff-filter d"
else
  # pre-commit hook: list cached files
  FILES="git diff-index --cached $against --name-only --diff-filter d"
fi

ELIXIR_FILES=$($FILES | egrep '\.(ex|exs|eex|heex)$')
ASSET_FILES=$($FILES | egrep '\.(js|jsx|css|scss)$' | grep assets/ | grep -v assets/vendor)

MIX="docker-compose run --no-deps --rm app mix"
YARN="docker-compose run --no-deps --rm webpack yarn"

report() {
  if [ $1 -eq 0 ]; then
    echo "[${GREEN}OK${NC}]"
  else
    echo "[${RED}ERROR${NC}]"
    exit 1
  fi
}

if [ ! -z "$ELIXIR_FILES" ]; then
  echo -n "==== Running mix format (check)... "
  $MIX format --check-formatted ${ELIXIR_FILES}
  report $?
fi

if [ ! -z "$ASSET_FILES" ]; then
  echo -n "==== Running prettier (check)... "
  $YARN -s prettier -c --loglevel=warn ${ASSET_FILES}
  report $?
fi

exit 0
