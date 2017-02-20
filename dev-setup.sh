#!/bin/sh
docker-compose run --rm app mix deps.get
docker-compose run --rm brunch yarn install
docker-compose run --rm app mix ecto.setup
