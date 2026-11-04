#!/bin/bash
set -e

ORACLE_PASSWORD="${ORACLE_PASSWORD:-$ORACLE_PWD}"
export ORDS_CONFIG=/opt/oracle/ords-config
export PATH=/opt/oracle/ords/bin:$PATH

# Check if ORDS has already been configured with proxied gateway
CURRENT_GW_MODE=$(ords --config "$ORDS_CONFIG" config get plsql.gateway.mode 2>/dev/null | tail -n 1 | tr -d '[:space:]' || true)

if [ "$CURRENT_GW_MODE" != "proxied" ]; then
  echo "ORDS is not configured or APEX gateway is not proxied (current: '${CURRENT_GW_MODE}')."
  echo "Waiting for Oracle Database and APEX to be fully initialized..."
  
  while true; do
    echo "Attempting ORDS installation... (Will retry if DB/APEX is not ready)"
    
    # Wipe any previous partial/disabled configuration before trying
    rm -rf "$ORDS_CONFIG"/*

    # Temporarily disable exit-on-error for the loop
    set +e
    ords --config "$ORDS_CONFIG" install \
         --admin-user SYS \
         --db-hostname "${DB_HOST:-oracle-db}" \
         --db-port "${DB_PORT:-1521}" \
         --db-servicename "${DB_SERVICE:-ORCLPDB1}" \
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
    
    GW_MODE=$(ords --config "$ORDS_CONFIG" config get plsql.gateway.mode 2>/dev/null | tail -n 1 | tr -d '[:space:]' || true)

    if [ $INSTALL_RESULT -eq 0 ] && [ "$GW_MODE" = "proxied" ]; then
      echo "ORDS successfully configured with APEX proxied gateway!"
      break
    fi
    
    echo "Database or APEX not fully ready yet (exit code: $INSTALL_RESULT, gateway mode: '$GW_MODE'). Retrying in 15 seconds..."
    rm -rf "$ORDS_CONFIG"/*
    sleep 15
  done

  echo "Mapping APEX static assets to /i/..."
  ords --config "$ORDS_CONFIG" config set standalone.static.path /opt/oracle/apex/images
  ords --config "$ORDS_CONFIG" config set standalone.static.context.path /i
else
  echo "ORDS is already configured with APEX proxied gateway."
fi

echo "Starting ORDS Web Server..."
exec ords --config "$ORDS_CONFIG" serve
