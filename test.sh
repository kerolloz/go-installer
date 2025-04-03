#!/usr/bin/env bash

run_test() {
  local _CI="${1:-${CI:-}}"

  # Check if the script is running in a CI/CD environment
  if test -n "$_CI"; then
    echo "Running tests in a CI/CD environment"

    # Test the script in a CI/CD environment
    bash go.sh update
    bash go.sh update
    bash go.sh remove
    bash go.sh remove
    bash go.sh
    bash go.sh
    bash go.sh help
    bash go.sh --version 1.19.2

  else
    echo "Running tests locally (DOCKER ENVIRONMENT TEST TO PREVENT SIDE EFFECTS)"
    echo "This may take a while..."

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
      echo "Docker is not installed"
      exit 1
    fi

    # Test the script in a Docker environment (with docker security and isolation to prevent side effects)
    _docker_test_result=$(docker run --rm -e TERM=xterm -v "$(pwd):/app" -w /app ubuntu bash -c 'apt-get update && apt-get install -y curl && bash go.sh update && bash go.sh update && bash go.sh remove && bash go.sh remove && bash go.sh && bash go.sh && bash go.sh help && bash go.sh --version $(grep -o "v[0-9]*\.[0-9]*\.[0-9]*" <<<"$(bash go.sh --version | grep -o "v[0-9]*\.[0-9]*\.[0-9]*")")') && _docker_test_exit_code=$? || _docker_test_exit_code=$?

    if [[ $_docker_test_exit_code -ne 0 ]]; then
      echo "Docker test failed"
    else
      echo "Docker test passed"
    fi

    sudo rm -rf ./go

    return "$_docker_test_exit_code"
  fi
}

run_test "$@"

exit $?