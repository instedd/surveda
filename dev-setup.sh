#!/bin/sh
set -e

# set color variables
COLOR_REST="$(tput sgr0)"
COLOR_GREEN="$(tput setaf 2)"
COLOR_MAGENTA="$(tput setaf 5)"
COLOR_LIGHT_BLUE="$(tput setaf 81)"

echo "$COLOR_LIGHT_BLUE 🧑‍🔧 Setting up pre-commit script... $COLOR_REST"
cd .git/hooks/
ln -sf ../../pre-commit.sh pre-commit
cd ../..

echo "$COLOR_LIGHT_BLUE 🧑‍🔧 Building Docker images... $COLOR_REST"
docker-compose build

echo "$COLOR_LIGHT_BLUE 🧑‍🔧 Installing dependencies... $COLOR_REST"
docker-compose run --rm app mix deps.get
docker-compose run --rm webpack yarn install

echo "$COLOR_LIGHT_BLUE 🧑‍🔧 Setting up database... $COLOR_REST"
docker-compose run --rm app mix ecto.setup

echo "$COLOR_LIGHT_BLUE ✨ Everything ready! $COLOR_REST"
