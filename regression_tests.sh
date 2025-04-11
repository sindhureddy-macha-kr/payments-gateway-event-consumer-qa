#!/bin/bash

if ! [ -x "$(command -v jq)" ]; then
    wget -O /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    chmod +x /usr/local/bin/jq
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed/failed to install.' >&2
  exit 1
fi

# t - Gradle task
# e - Environment (spring profile - eg: review, dev, test, stage)
# h - Service Host url to be tested
# u - Artifactory username
# p - Artifactory Edge Password
# o - Extra Arguments
while getopts t:e:h:u:p:o: flag
do
    case "${flag}" in
        t) task=${OPTARG};;
        e) env=${OPTARG};;
        h) host=${OPTARG};;
        u) username=${OPTARG};;
        p) password=${OPTARG};;
        o) extra_args=${OPTARG};;
    esac
done
echo "Task: $task";
echo "Env: $env";
echo "Host: $host";

echo "START: Running Regression tests on env $env and host $host with $task..."
export ARTIFACTORY_USER=$username
export ARTIFACTORY_EDGE_PASSWORD=$password

echo "systemProp.gradle.wrapperUser=$username" >> gradle.properties
echo "systemProp.gradle.wrapperPassword=$password" >> gradle.properties
#echo "artUsername=$username" >> gradle.properties
#echo "artEdgePassword=$password" >> gradle.properties

chmod +x gradlew

variables=""

entries=$(echo $extra_args | jq "to_entries")

for row in $(echo $entries | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }
   new_variable=`echo "-D"$(_jq '.key')"="$(_jq '.value')""`
   variables="${variables} ${new_variable}"
done

./gradlew $task -Denv=$env -Dgradle.wrapperUser=$username -Dgradle.wrapperPassword=$password -Dhost_url=$host $variables -i

if [[ $? -ne 0 ]] ; then
  echo "FINISH: There are test failures, failing build..."
  echo "Exiting with code 1."
  exit 1
else
  echo "FINISH: All tests passed!"
  echo "Exiting with code 0."
  exit 0
fi