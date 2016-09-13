#!/bin/bash
TAG=${TRAVIS_BRANCH/#master/latest}
TAG=${TAG/\//_}

git describe --always > VERSION

# Build assets
docker-compose run --rm brunch ./node_modules/brunch/bin/brunch build -p

# Build and push Docker image
docker build -t ${DOCKER_REPOSITORY}:$TAG .
docker login -e ${DOCKER_EMAIL} -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DOCKER_REGISTRY}
docker push ${DOCKER_REPOSITORY}:$TAG
