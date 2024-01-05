#!/bin/bash
BUILDER_IMAGE_BASE="${BUILDER_IMAGE_BASE:-'gitlab-master.nvidia.com:5005/whicks/milvus:builder'}"
BUILDER_IMAGE_TAG="${BUILDER_IMAGE_TAG:-'latest'}"

FORCE_BUILD_BUILDER="${FORCE_BUILD_BUILDER:-'false'}"

MILVUS_REPO="${MILVUS_REPO:-'git@github.com:milvus-io/milvus.git'}"
MILVUS_BRANCH='master'

pushd build_context
if ! [ -d 'milvus' ]
then
  if [ -z "$MILVUS_BRANCH" ]
  then
    MILVUS_BRANCH='master'
  fi
  git clone $MILVUS_REPO -b $MILVUS_BRANCH
else
  if ! [ -z "$MILVUS_BRANCH" ]
  then
    pushd milvus
    git fetch origin
    git checkout $MILVUS_BRANCH
    git pull origin $MILVUS_BRANCH
    popd
  fi
fi

popd

if [[ ":$BUILDER_IMAGE_BASE" == *:* ]]
then
  BUILDER_IMAGE="${BUILDER_IMAGE_BASE}-${BUILDER_IMAGE_TAG}"
else
  BUILDER_IMAGE="${BUILDER_IMAGE_BASE}:${BUILDER_IMAGE_TAG}"
fi

if [ "$FORCE_BUILD_BUILDER" != "true" ] || docker pull $BUILDER_IMAGE
then
  echo "Pulled prebuilt builder image: $BUILDER_IMAGE"
else
  echo "Building builder image: $BUILDER_IMAGE"
  docker build -t "$BUILDER_IMAGE" ./build_context
  docker push "$BUILDER_IMAGE" || echo "Failed to push builder image: $BUILDER_IMAGE"
fi

docker run -v "$(pwd)/build_context/milvus:/workspace/src" --rm "$BUILDER_IMAGE"
