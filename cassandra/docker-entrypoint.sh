#!/bin/bash
set -e

: ${CASSANDRA_LISTEN_ADDRESS='auto'}
if [ "$CASSANDRA_LISTEN_ADDRESS" = 'auto' ]; then
	CASSANDRA_LISTEN_ADDRESS="$(hostname --ip-address)"
fi

: ${CASSANDRA_BROADCAST_ADDRESS="$CASSANDRA_LISTEN_ADDRESS"}

if [ "$CASSANDRA_BROADCAST_ADDRESS" = 'auto' ]; then
	CASSANDRA_BROADCAST_ADDRESS="$(hostname --ip-address)"
fi
: ${CASSANDRA_BROADCAST_RPC_ADDRESS:=$CASSANDRA_BROADCAST_ADDRESS}

if [ -n "${CASSANDRA_NAME:+1}" ]; then
	: ${CASSANDRA_SEEDS:="cassandra"}
fi
: ${CASSANDRA_SEEDS:="$CASSANDRA_BROADCAST_ADDRESS"}

sed -ri 's/(- seeds:) "127.0.0.1"/\1 "'"$CASSANDRA_SEEDS"'"/' "$CASSANDRA_CONFIG/cassandra.yaml"

echo 'JVM_OPTS="$JVM_OPTS -Djava.rmi.server.hostname='$(hostname --ip-address)'"' >> "$CASSANDRA_CONFIG/cassandra-env.sh"

for yaml in \
broadcast_address \
broadcast_rpc_address \
cluster_name \
endpoint_snitch \
listen_address \
num_tokens \
; do
	var="CASSANDRA_${yaml^^}"
	val="${!var}"
	if [ "$val" ]; then
		sed -ri 's/^(# )?('"$yaml"':).*/\2 '"$val"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
	fi
done

for rackdc in dc rack; do
	var="CASSANDRA_${rackdc^^}"
	val="${!var}"
	if [ "$val" ]; then
		sed -ri 's/^('"$rackdc"'=).*/\1 '"$val"'/' "$CASSANDRA_CONFIG/cassandra-rackdc.properties"
	fi
done

echo "stomp_interface: opscenter" >> /var/lib/datastax-agent/conf/address.yaml
echo "use_ssl: 0" >> /var/lib/datastax-agent/conf/address.yaml

exec "$@"
