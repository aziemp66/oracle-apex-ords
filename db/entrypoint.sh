#!/bin/bash
set -e

# If APEX directory is missing apexins.sql, ensure oracle user has permission to write/extract to it
if [ ! -f /opt/oracle/apex/apexins.sql ]; then
    mkdir -p /opt/oracle/apex
    chown -R oracle:oinstall /opt/oracle/apex 2>/dev/null || true
    chmod -R u+rwx,g+rwx,o+rx /opt/oracle/apex 2>/dev/null || true
fi

# If no arguments provided, default to the base image run command
if [ $# -eq 0 ]; then
    set -- /bin/sh -c 'exec $ORACLE_BASE/$RUN_FILE'
fi

# Execute command as oracle user using setpriv
exec setpriv --reuid=oracle --regid=oinstall --init-groups "$@"
