#!/bin/sh
echo "Running Mix tests"
MIX_TESTS="$(docker-compose run --rm app mix test)"

if [ $? -eq 0 ]; then
   echo "OK";
else
  echo "${MIX_TESTS}"
fi

echo "Running Brunch tests"
BRUNCH_TESTS="$(docker-compose run --rm brunch npm test)"

if [ $? -eq 0 ]; then
  echo "OK";
else
  echo "${BRUNCH_TESTS}"
fi

echo "Running Flow tests"
FLOW_TESTS="$(flow check)"

if [ $? -eq 0 ]; then
  echo "OK";
else
  echo "${FLOW_TESTS}"
fi

echo "Running Eslint tests"
ESLINT_TESTS="$(docker-compose run --rm brunch node_modules/.bin/eslint --ext .jsx,.js web/static/js/ test/js)"

if [ $? -eq 0 ]; then
  echo "OK";
else
  echo "${ESLINT_TESTS}"
fi
