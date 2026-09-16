#!/bin/bash
set -e

echo "Starting Oracle APEX Installation..."

# Fallback for official Oracle images which use ORACLE_PWD instead of ORACLE_PASSWORD
ORACLE_PASSWORD="${ORACLE_PASSWORD:-$ORACLE_PWD}"

# Dynamically find the PDB name (works for FREEPDB1 or ORCLPDB1)
PDB_NAME=$(echo -e "SET PAGESIZE 0\nSET HEADING OFF\nSELECT name FROM v\$pdbs WHERE name != 'PDB\$SEED' AND ROWNUM = 1;" | sqlplus -s / as sysdba 2>/dev/null | xargs || true)

if [ -z "$PDB_NAME" ]; then
    echo "Could not detect a Pluggable Database! Defaulting to FREEPDB1."
    PDB_NAME="FREEPDB1"
fi

echo "Targeting Pluggable Database: $PDB_NAME"

cd /opt/oracle/apex

echo "Executing @apexins.sql (this will take 15-30 minutes)..."
sqlplus -s / as sysdba <<EOF
ALTER SESSION SET CONTAINER = $PDB_NAME;
@apexins.sql SYSAUX SYSAUX TEMP /i/
EOF

echo "Configuring APEX REST..."
sqlplus -s / as sysdba <<EOF
ALTER SESSION SET CONTAINER = $PDB_NAME;
@apex_rest_config_core.sql @ "$ORACLE_PASSWORD" "$ORACLE_PASSWORD"
EOF

echo "Unlocking APEX accounts and setting ADMIN password..."
sqlplus -s / as sysdba <<EOF
ALTER SESSION SET CONTAINER = $PDB_NAME;
ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK;
ALTER USER APEX_REST_PUBLIC_USER ACCOUNT UNLOCK;
ALTER USER APEX_LISTENER ACCOUNT UNLOCK;
ALTER USER APEX_PUBLIC_USER IDENTIFIED BY "$ORACLE_PASSWORD";
ALTER USER APEX_REST_PUBLIC_USER IDENTIFIED BY "$ORACLE_PASSWORD";
ALTER USER APEX_LISTENER IDENTIFIED BY "$ORACLE_PASSWORD";

-- Setup the INTERNAL Workspace ADMIN password
BEGIN
    APEX_UTIL.set_security_group_id( 10 );
    APEX_UTIL.create_user(
        p_user_name       => 'ADMIN',
        p_email_address   => 'admin@localhost',
        p_web_password    => '$ORACLE_PASSWORD',
        p_developer_privs => 'ADMIN' );
    APEX_UTIL.set_security_group_id( null );
    COMMIT;
END;
/
EOF

echo "APEX Installation Completed Successfully!"
