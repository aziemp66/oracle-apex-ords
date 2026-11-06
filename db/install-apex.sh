#!/bin/bash
set -e

ORACLE_PASSWORD="${ORACLE_PASSWORD:-$ORACLE_PWD}"

echo "Starting Oracle APEX Installation..."

# Dynamically find the PDB name (works for FREEPDB1 or ORCLPDB1)
PDB_NAME=$(echo -e "SET PAGESIZE 0\nSET HEADING OFF\nSELECT name FROM v\$pdbs WHERE name != 'PDB\$SEED' AND ROWNUM = 1;" | sqlplus -s / as sysdba 2>/dev/null | xargs || true)

if [ -z "$PDB_NAME" ]; then
    echo "Could not detect a Pluggable Database! Defaulting to ${ORACLE_PDB:-ORCLPDB1}."
    PDB_NAME="${ORACLE_PDB:-ORCLPDB1}"
fi

echo "Targeting Pluggable Database: $PDB_NAME"

APEX_DIR="/opt/oracle/apex"
APEX_VERSION="${APEX_VERSION:-26.2}"

# Check if APEX directory contains installation files
if [ -f "${APEX_DIR}/apexins.sql" ]; then
    echo "Using existing APEX folder at ${APEX_DIR} (apexins.sql found)."
else
    echo "APEX not found in ${APEX_DIR}. Falling back to downloading APEX version ${APEX_VERSION}..."
    mkdir -p "${APEX_DIR}"
    cd /tmp

    APEX_URL="https://download.oracle.com/otn_software/apex/apex_${APEX_VERSION}.zip"
    if [ "${APEX_VERSION}" = "latest" ]; then
        APEX_URL="https://download.oracle.com/otn_software/apex/apex-latest.zip"
    fi

    echo "Downloading APEX from ${APEX_URL}..."
    if command -v curl &> /dev/null; then
        curl -sSL "$APEX_URL" -o apex.zip
    elif command -v wget &> /dev/null; then
        wget -q "$APEX_URL" -O apex.zip
    else
        echo "Error: Neither curl nor wget is available to download APEX!"
        exit 1
    fi

    echo "Extracting APEX to /opt/oracle/..."
    if unzip -q -o apex.zip -d /opt/oracle/ 2>/dev/null; then
        echo "Successfully extracted APEX to /opt/oracle/apex"
    else
        echo "Extracting to fallback directory..."
        mkdir -p /tmp/apex_extracted
        unzip -q -o apex.zip -d /tmp/apex_extracted
        cp -rn /tmp/apex_extracted/apex/* "${APEX_DIR}/" 2>/dev/null || true
        if [ ! -f "${APEX_DIR}/apexins.sql" ]; then
            APEX_DIR="/tmp/apex_extracted/apex"
        fi
        rm -rf /tmp/apex_extracted
    fi
    rm -f /tmp/apex.zip
fi

cd "$APEX_DIR"

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
ALTER USER APEX_PUBLIC_USER IDENTIFIED BY "$ORACLE_PASSWORD";
ALTER USER APEX_REST_PUBLIC_USER IDENTIFIED BY "$ORACLE_PASSWORD";

-- Setup the INTERNAL Workspace ADMIN password
BEGIN
    APEX_UTIL.set_security_group_id( 10 );
    BEGIN
        APEX_UTIL.create_user(
            p_user_name       => 'ADMIN',
            p_email_address   => 'admin@localhost',
            p_web_password    => '$ORACLE_PASSWORD',
            p_developer_privs => 'ADMIN' );
    EXCEPTION
        WHEN OTHERS THEN
            APEX_UTIL.edit_user(
                p_user_id      => APEX_UTIL.get_user_id('ADMIN'),
                p_user_name    => 'ADMIN',
                p_web_password => '$ORACLE_PASSWORD' );
    END;
    APEX_UTIL.set_security_group_id( null );
    COMMIT;
END;
/
EOF

echo "APEX Installation Completed Successfully!"
