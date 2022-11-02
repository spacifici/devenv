#!/bin/bash

declare -r USER_NAME="`whoami`"
declare -r GID="`id -g`"
declare -r IMAGE_NAME="devenv"
declare -r CONTAINER_NAME="${IMAGE_NAME}-${USER_NAME}"
DOCKER_GID="`getent group docker | cut -d: -f3 || true`"
declare -r DOCKER_GID="${DOCKER_GID:-998}"
declare -r DATA_DIR="${HOME}/data"

port="${DEVENV_PORT:-2222}"
ubuntu_version="${DEVENV_UBUNTU_VERSION:-22.04}"
extra_build_args=""
extra_run_options=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		-p|--port)
			port="$2"
			shift
			shift
			;;
		-v|--version)
			ubuntu_version="$2"
			shift
			shift
			;;
		-h|--help)
			echo "Usage: $0 [OPTIONS]"
			echo ""
			echo "    -p --port    The port on which ssh should listen (default $port)"
			echo "    -v --version The ubuntu version to be used as base image (default $ubuntu_version)"
			echo "    -h --help    Print this help message"
			exit 0
			;;
		*)
			echo "Unknown argument $1" >&2
			exit 1
			;;
	esac
done

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
		--build-arg ubuntu_version="${ubuntu_version}" \
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

