# !/bin/bash

docker run --name sncrypto-web -d -p 9003:9003 standardnotes/sncrypto-web:$SNCRYPTO_TAG

attempt=0
while [ $attempt -le 90 ]; do
    attempt=$(( $attempt + 1 ))
    echo "# Waiting service to be up (attempt: $attempt) ..."
    container_id=$(docker ps -aqf "name=sncrypto-web")
    result=$(docker logs $container_id)
    if grep -q 'Open browser to' <<< $result ; then
        sleep 2 # for warmup
        echo "# Service is up!"
        break
    fi
    sleep 2
done

echo "# Starting test suite ..."
npx mocha-headless-chrome --timeout 1200000 -f http://localhost:9003/test/test.html
test_result=$?

if [[ $test_result == 0 ]]
then
  exit 0
else
  exit 1
fi
