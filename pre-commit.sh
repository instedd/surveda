#!/bin/sh
NC='\033[0m'
GREEN='\033[0;32m'

echo "----==== Running Mix tests ====----"
MIX_TESTS="$(docker-compose run --rm app mix test)"

if [ $? -eq 0 ]; then
  echo "${GREEN}OK${NC}";
else
  echo "${MIX_TESTS}"
fi

echo "----==== Running JS tests ====----"
JS_TESTS="$(docker-compose run --rm webpack yarn test)"

if [ $? -eq 0 ]; then
  echo "${GREEN}OK${NC}";
else
  echo "${JS_TESTS}"
fi

echo "----==== Running Flow tests ====----"
if hash flow 2>/dev/null; then
  FLOW_TESTS="$(flow check)"
else
  FLOW_TESTS="$(./node_modules/.bin/flow check)"
fi

if [ $? -eq 0 ]; then
  echo "${GREEN}OK${NC}";
else
  echo "${FLOW_TESTS}"
fi

echo "----==== Running Eslint tests ====----"
ESLINT_TESTS="$(docker-compose run --rm webpack yarn eslint)"

if [ $? -eq 0 ]; then
  echo "${GREEN}OK${NC}";
else
  echo "${ESLINT_TESTS}"
fi
