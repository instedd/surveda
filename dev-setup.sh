#!/bin/sh
docker-compose run --rm app mix deps.get
docker-compose run --rm brunch npm install
docker-compose run --rm app mix ecto.setup

