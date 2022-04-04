#!/bin/sh
NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'

STAGED_FILES="git diff-index --cached HEAD --name-only --diff-filter d"
STAGED_ELIXIR_FILES=$($STAGED_FILES | egrep '\.(ex|exs|eex|heex)$')
STAGED_ASSET_FILES=$($STAGED_FILES | egrep '\.(js|css|scss)$' | grep -v web/static/vendor)

MIX="docker-compose run --rm app mix"
YARN="docker-compose run --rm webpack yarn"

report() {
  if [ $1 -eq 0 ]; then
    echo "[${GREEN}OK${NC}]"
  else
    echo "[${RED}ERROR${NC}]"
    exit 1
  fi
}

if [ ! -z $STAGED_ELIXIR_FILES ]; then
  echo -n "==== Running mix format... "
  $MIX format ${STAGED_ELIXIR_FILES}
  report $?
fi

if [ ! -z $STAGED_ASSET_FILES ]; then
  echo -n "==== Running prettier... "
  $YARN -s prettier -c ${STAGED_ASSET_FILES}
  report $?
fi

exit 0
