#!/bin/bash

declare -r USER_NAME="`whoami`"
declare -r GID="`id -g`"
declare -r IMAGE_NAME="devenv"
declare -r CONTAINER_NAME="${IMAGE_NAME}-${USER_NAME}"
DOCKER_GID="`getent group docker | cut -d: -f3 || true`"
declare -r DOCKER_GID="${DOCKER_GID:-998}"
declare -r DATA_DIR="${HOME}/data"

port=2222
extra_build_args=""
extra_run_options=""

if [ -S /var/run/docker.sock ]; then
	extra_build_args="--build-arg docker_gid=${DOCKER_GID}"
	extra_run_options="-v /var/run/docker.sock:/var/run/docker.sock"
fi

# The container is running, leave it alone
[ -n "`docker ps|grep "$CONTAINER_NAME"`" ] && exit 0

# The container doesn't exist, create it
[ -z "`docker images|grep "${IMAGE_NAME}"`" ] && \
	docker build \
		--build-arg user="${USER_NAME}" \
		--build-arg uid="${UID}" \
		--build-arg gid="${GID}" \
		${extra_build_args} \
		-t "${IMAGE_NAME}:latest" .

# Create a data dir if it doesn't exist
mkdir -p "${DATA_DIR}"

# Start the container and name it
docker run -d -p $port:22 \
	--name "${CONTAINER_NAME}" \
	-v "${DATA_DIR}:/data" \
	${extra_run_options} \
	"${IMAGE_NAME}"

