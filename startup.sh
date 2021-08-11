#!/bin/bash

set -eu -o pipefail

# Remove any pending lock file
rm -rf /app/data/kahadb/lock

exec /app/activemq/bin/activemq console
