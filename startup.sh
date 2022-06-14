#!/bin/bash

set -eu -o pipefail

DATA="/app/data"

[ -e "${DATA}" ] || { echo "The data directory [${DATA}] does not exist" ; exit 1 ; }
[ -d "${DATA}" ] || { echo "The path [${DATA}] is not a directory" ; exit 1 ; }
[ -r "${DATA}" ] || { echo "The data directory [${DATA}] is not readable by ${USER} (${UID}:$(id -g))" ; exit 1 ; }
[ -w "${DATA}" ] || { echo "The data directory [${DATA}] is not writable by ${USER} (${UID}:$(id -g))" ; exit 1 ; }
[ -x "${DATA}" ] || { echo "The data directory [${DATA}] is not executable by ${USER} (${UID}:$(id -g))" ; exit 1 ; }

# Remove any pending lock file
rm -rf "${DATA}/kahadb/lock" &>/dev/null || true

# Fork into the application
exec "/app/activemq/bin/activemq" "console"
