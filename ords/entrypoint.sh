#!/bin/bash
set -e

export ORDS_CONFIG=/opt/oracle/ords-config
export PATH=/opt/oracle/ords/bin:$PATH

if [ ! -d "$ORDS_CONFIG/databases" ]; then
  echo "Waiting for Oracle Database and APEX to be fully initialized..."
  
  while true; do
    echo "Attempting ORDS installation... (Will retry if DB/APEX is not ready)"
    
    # Temporarily disable exit-on-error for the loop
    set +e
    ords --config $ORDS_CONFIG install \
         --admin-user SYS \
         --db-hostname ${DB_HOST:-oracle-db} \
         --db-port ${DB_PORT:-1521} \
         --db-servicename ${DB_SERVICE:-FREEPDB1} \
         --feature-db-api true \
         --feature-rest-enabled-sql true \
         --feature-sdw true \
         --gateway-mode proxied \
         --gateway-user APEX_PUBLIC_USER \
         --password-stdin <<EOF
${ORACLE_PASSWORD}
${ORACLE_PASSWORD}
${ORACLE_PASSWORD}
${ORACLE_PASSWORD}
EOF
    INSTALL_RESULT=$?
    set -e
    
    if [ $INSTALL_RESULT -eq 0 ]; then
      echo "ORDS successfully configured!"
      break
    fi
    
    echo "Database or APEX not ready yet. Retrying in 20 seconds..."
    # Wipe corrupted config directory so the next attempt starts fresh
    rm -rf $ORDS_CONFIG/*
    sleep 20
  done

  echo "Ensuring PL/SQL Gateway is enabled for APEX..."
  ords --config $ORDS_CONFIG config set plsql.gateway.mode proxied

  echo "Mapping APEX static assets to /i/..."
  ords --config $ORDS_CONFIG config set standalone.static.path /opt/oracle/apex/images
  ords --config $ORDS_CONFIG config set standalone.static.context.path /i
else
  echo "ORDS is already configured."
fi

echo "Starting ORDS Web Server..."
exec ords --config $ORDS_CONFIG serve
