# !/bin/bash

HOST_OSTYPE=$(uname)
UID=1001
GID=1001
if [ "$HOST_OSTYPE" == "Linux"]; then
  UID=$(id -u)
  GID=$(id -g)
fi

[ -n "${SUITE}" ] || SUITE=$1 && shift 1
if [ -z "$SUITE" ];
then
  echo "Test suite argument is missing. Please choose canary, server or client"
  usage
  exit 1
fi

COMPOSE_FILE="docker-compose.${SUITE}.yml"

function setup {
  echo "# Copying the sample configuration files"
  cp docker/api-gateway.env.sample docker/api-gateway.env
  cp docker/auth.env.sample docker/auth.env
  cp docker/syncing-server-js.env.sample docker/syncing-server-js.env
  cp docker/mock-event-publisher.env.sample docker/mock-event-publisher.env
  cp docker/files.env.sample docker/files.env
}

function cleanup {
  local output_logs=$1
  if [ $output_logs == 1 ]
  then
    echo "Outputing last 100 lines of logs"
    docker compose -f $COMPOSE_FILE logs --tail=100
  fi
  echo "# Killing all containers"
  docker compose -f $COMPOSE_FILE kill
  echo "# Removing all containers"
  docker compose -f $COMPOSE_FILE rm -vf
}

function startContainers {
  echo "# Running Test Suite in $SUITE mode. Using $COMPOSE_FILE compose file."
  echo "# Pulling latest versions"
  docker compose -f $COMPOSE_FILE pull

  SNJS_TAG=$1 && shift 1
  echo "# Starting standardnotes/snjs:${SNJS_TAG} container"
  docker run -d -p 9001:9001 standardnotes/snjs:$SNJS_TAG

  echo "# Starting all containers for Test Suite"
  docker compose -f $COMPOSE_FILE up -d
}

function waitForServices {
  attempt=0
  while [ $attempt -le 90 ]; do
      attempt=$(( $attempt + 1 ))
      echo "# Waiting for all services to be up (attempt: $attempt) ..."
      result=$(docker compose -f $COMPOSE_FILE logs api-gateway)
      if grep -q 'Server started on port' <<< $result ; then
          sleep 2 # for warmup
          echo "# All services are up!"
          break
      fi
      sleep 2
  done
}

setup
cleanup 0
startContainers
waitForServices

echo "# Starting test suite ..."
npx mocha-headless-chrome --timeout 1200000 -f http://localhost:9001/packages/snjs/mocha/test.html
test_result=$?

cleanup $test_result

if [ $test_result == 0 ]
then
  exit 0
else
  exit 1
fi