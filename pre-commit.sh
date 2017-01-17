#!/bin/sh
docker-compose run --rm app mix test
docker-compose run --rm brunch npm test
flow check
docker-compose run --rm brunch node_modules/.bin/eslint --ext .jsx,.js web/static/js/
