#!/bin/bash

set -eu -o pipefail

here=$(realpath "$0")
here=$(dirname "$here")
cd "$here"

activemq_version="5.16.2"
activemq="apache-activemq-$activemq_version"
activemq_sha512="27bb26786640f74dcf404db884bedffc0af4bfb2a0248c398044ac9a13e19ff097c590b79eb1404e0b04d17a8f85a8f7de87186a96744e19162d70b3c7a9bdde"

jmx_prometheus_agent_version="0.15.0"
jmx_prometheus_agent="jmx_prometheus_javaagent-${jmx_prometheus_agent_version}"

rm -rf artifacts
mkdir artifacts

echo "Downloading $activemq"
aws s3 cp "s3://arkcase-container-artifacts/ark_activemq/${activemq}-bin.tar.gz" artifacts/
checksum=$(sha512sum "artifacts/${activemq}-bin.tar.gz" | awk '{ print $1 }')
if [ $checksum != $activemq_sha512 ]; then
    echo "Unexpected SHA512 checksum; possible man-in-the-middle-attack"
    rm "${activemq}-bin.tar.gz"
    exit 1
fi

echo "Downloading $jmx_prometheus_agent"
aws s3 cp "s3://arkcase-container-artifacts/ark_activemq/${jmx_prometheus_agent}.jar" artifacts/
