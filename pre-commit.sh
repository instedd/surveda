#!/bin/sh

MIX_TESTS="$(docker-compose run --rm app mix test)"

if [ $? -eq 0 ]; then
   echo "Mix tests are OK";
else
  echo "${MIX_TESTS}"
fi

BRUNCH_TESTS="$(docker-compose run --rm brunch npm test)"

if [ $? -eq 0 ]; then
  echo "Brunch tests are OK";
else
  echo "${BRUNCH_TESTS}"
fi

FLOW_TESTS="$(flow check)"

if [ $? -eq 0 ]; then
  echo "Flow tests are OK";
else
  echo "${FLOW_TESTS}"
fi

ESLINT_TESTS="$(docker-compose run --rm brunch node_modules/.bin/eslint --ext .jsx,.js web/static/js/ test/js)"

if [ $? -eq 0 ]; then
  echo "Eslint tests are OK";
else
  echo "${ESLINT_TESTS}"
fi
