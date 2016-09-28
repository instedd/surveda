#!/bin/bash
PROJECT_VERSION=`mix run --no-compile --no-start -e 'IO.write Mix.Project.config[:version]'`
TAG=`git describe --exact-match 2>/dev/null`

if [ "$TAG" = "" ]; then
  REV=`git rev-parse --short HEAD`
  VERSION="$PROJECT_VERSION-dev-$REV (build $TRAVIS_BUILD_NUMBER)"
else
  if [ "$PROJECT_VERSION" != "$TAG" ]; then
    echo "Project version and tag differs: $PROJECT_VERSION != $TAG"
    exit 1
  fi

  VERSION="$PROJECT_VERSION (build $TRAVIS_BUILD_NUMBER)"
fi

echo "Version: $VERSION"
echo $VERSION > VERSION

case $TRAVIS_BRANCH in
  release/*)
    if [ "$TAG" == "" ]; then
      DOCKER_TAG="${TRAVIS_BRANCH/#*\//}-dev"
    else
      DOCKER_TAG="$TAG"
      EXTRA_DOCKER_TAG="${TRAVIS_BRANCH/#*\//}"
    fi

    ;;

  master)
    DOCKER_TAG="dev"
    ;;

  stable)
    echo "Pulling $PROJECT_VERSION and tagging as latest"
    docker login -e ${DOCKER_EMAIL} -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DOCKER_REGISTRY}
    docker pull ${DOCKER_REPOSITORY}:${PROJECT_VERSION}
    docker tag ${DOCKER_REPOSITORY}:${PROJECT_VERSION} ${DOCKER_REPOSITORY}:latest
    docker push ${DOCKER_REPOSITORY}:latest
    exit 0
    ;;

  *)
    exit 0
    # DOCKER_TAG=${TRAVIS_BRANCH/\//_}
    ;;
esac

# Build assets
docker-compose run --rm brunch ./node_modules/brunch/bin/brunch build -p

# Build and push Docker image
echo "Docker tag: $DOCKER_TAG"
docker build -t ${DOCKER_REPOSITORY}:${DOCKER_TAG} .
docker login -e ${DOCKER_EMAIL} -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DOCKER_REGISTRY}
docker push ${DOCKER_REPOSITORY}:${DOCKER_TAG}

# Push extra image on exact tags
if [ "$EXTRA_DOCKER_TAG" != "" ]; then
  echo "Pushing also as $EXTRA_DOCKER_TAG"
  docker tag ${DOCKER_REPOSITORY}:${DOCKER_TAG} ${DOCKER_REPOSITORY}:${EXTRA_DOCKER_TAG}
  docker push ${DOCKER_REPOSITORY}:${EXTRA_DOCKER_TAG}
fi
