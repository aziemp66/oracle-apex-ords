#!/bin/bash
set -e

APEX_DIR="/opt/oracle/apex"
APEX_VERSION="${APEX_VERSION:-26.2}"

# Check if APEX images directory exists
if [ -d "${APEX_DIR}/images" ]; then
    echo "Using existing APEX images at ${APEX_DIR}/images."
else
    echo "APEX images not found in ${APEX_DIR}/images. Falling back to downloading APEX version ${APEX_VERSION}..."
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

    echo "Extracting APEX to ${APEX_DIR}..."
    if unzip -q -o apex.zip -d /opt/oracle/ 2>/dev/null; then
        echo "Successfully extracted APEX to /opt/oracle/apex"
    else
        echo "Extracting to fallback directory..."
        mkdir -p /tmp/apex_extracted
        unzip -q -o apex.zip -d /tmp/apex_extracted
        cp -rn /tmp/apex_extracted/apex/* "${APEX_DIR}/" 2>/dev/null || true
        if [ ! -d "${APEX_DIR}/images" ] && [ -d /tmp/apex_extracted/apex/images ]; then
            mkdir -p /tmp/apex
            cp -rn /tmp/apex_extracted/apex/* /tmp/apex/
            export APEX_HOME=/tmp/apex
            export APEXI=/tmp/apex/images
        fi
        rm -rf /tmp/apex_extracted
    fi
    rm -f /tmp/apex.zip
fi

# Execute the official ORDS entrypoint
exec /usr/bin/docker-entrypoint.sh "$@"
