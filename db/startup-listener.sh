#!/bin/bash
# Ensure listener.ora and tnsnames.ora bind to 0.0.0.0 regardless of container hostname/ID changes
for f in /opt/oracle/oradata/dbconfig/*/*.ora /opt/oracle/product/*/dbhome_*/network/admin/*.ora; do
  if [ -f "$f" ]; then
    sed -i -E 's/\(HOST = [^)]+\)/(HOST = 0.0.0.0)/g' "$f"
  fi
done

# Start the listener if it is not already running
if ! lsnrctl status >/dev/null 2>&1; then
  echo "Starting Oracle TNS Listener..."
  lsnrctl start
fi

# Ensure services are registered with the listener
echo "Registering database services with the listener..."
echo "ALTER SYSTEM REGISTER;" | sqlplus -s / as sysdba >/dev/null 2>&1 || true
