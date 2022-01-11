#!/bin/bash
set -eo pipefail

# This will load the script from this repository. Make sure to point to a specific commit so the build continues to work
# event if breaking changes are introduced in this repository
source <(curl -s https://raw.githubusercontent.com/manastech/ci-docker-builder/c72777146ee4fe9192d585870661ebde508b63fd/build.sh)

# Prepare the build
dockerSetup

# Write a VERSION file for the footer
echo $VERSION > VERSION

# Build assets
docker-compose run --rm app mix deps.get
docker-compose run --rm webpack yarn install --no-progress
docker-compose run --rm webpack yarn deploy

# Build and push the Docker image
dockerBuildAndPush
