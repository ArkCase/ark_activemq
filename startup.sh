#!/bin/bash

set -eu -o pipefail

#
# Take ownership of the data directory, if necessary
#
DATA="/app/data"

AMQ_GROUP="$(id -gn "${AMQ_USER}")"

OWNER="$(stat -c "%U:%G" "${DATA}")"
if [ "${OWNER}" != "${AMQ_USER}:${AMQ_GROUP}" ] ; then
	echo "Fixing the ownership for the data directory at [${DATA}]..."
	chown -R "${AMQ_USER}:${AMQ_GROUP}" "${DATA}"
fi
PERMS="$(stat -c "%a" "${DATA}")"
if [ "${PERMS}" != "770" ] ; then
	echo "Fixing the permissions for the data directory at [${DATA}]..."
	chmod -R ug+rwX,o-rwx "${DATA}"
fi

#
# Remove any pending lock file
#
rm -rf /app/data/kahadb/lock

#
# Run this as the activemq user, and use exec to ensure there's no way back
#
exec su \
	--preserve-environment \
	--shell=/bin/bash \
	"${AMQ_USER}" \
	--command "exec /app/activemq/bin/activemq console"
