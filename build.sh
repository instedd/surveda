#!/bin/bash
set -eo pipefail

# This will load the script from this repository. Make sure to point to a specific commit so the build continues to work
# event if breaking changes are introduced in this repository
source <(curl -s https://raw.githubusercontent.com/manastech/ci-docker-builder/bdf32a7b1847739a58d169d4a989c673a671b32f/build.sh)

# Prepare the build
dockerSetup

# Write a VERSION file for the footer
docker-compose run --rm app mix run --no-compile --no-start -e 'File.write! "VERSION", Mix.Project.config[:version]'

# Build assets
docker-compose run --rm webpack yarn deploy

# Build and push the Docker image
dockerBuildAndPush
