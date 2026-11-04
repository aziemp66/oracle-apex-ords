ARG BASE_IMAGE=container-registry.oracle.com/database/enterprise:23.26.1.0
FROM ${BASE_IMAGE}

USER root

# Install dependencies for downloading and extracting APEX if not present
RUN if ! command -v unzip &> /dev/null || (! command -v wget &> /dev/null && ! command -v curl &> /dev/null); then \
        if command -v microdnf &> /dev/null; then \
            microdnf install -y unzip wget && microdnf clean all; \
        elif command -v dnf &> /dev/null; then \
            dnf install -y unzip wget && dnf clean all; \
        else \
            apt-get update && apt-get install -y unzip wget && rm -rf /var/lib/apt/lists/*; \
        fi; \
    fi

ARG APEX_VERSION=26.2

# Create directory and download APEX
RUN mkdir -p /opt/oracle/apex && \
    cd /tmp && \
    APEX_URL="https://download.oracle.com/otn_software/apex/apex_${APEX_VERSION}.zip"; \
    if [ "${APEX_VERSION}" = "latest" ]; then \
        APEX_URL="https://download.oracle.com/otn_software/apex/apex-latest.zip"; \
    fi && \
    if command -v curl &> /dev/null; then \
        curl -sSL "$APEX_URL" -o apex.zip; \
    else \
        wget -q "$APEX_URL" -O apex.zip; \
    fi && \
    unzip -q apex.zip -d /opt/oracle/ && \
    rm apex.zip && \
    chown -R oracle:oinstall /opt/oracle/apex

# Copy the initialization script that installs APEX
RUN mkdir -p /container-entrypoint-initdb.d /opt/oracle/scripts/setup /opt/oracle/scripts/startup
COPY install-apex.sh /container-entrypoint-initdb.d/01-install-apex.sh
COPY install-apex.sh /opt/oracle/scripts/setup/01-install-apex.sh
COPY startup-listener.sh /opt/oracle/scripts/startup/01-startup-listener.sh

RUN chmod +x /container-entrypoint-initdb.d/01-install-apex.sh \
             /opt/oracle/scripts/setup/01-install-apex.sh \
             /opt/oracle/scripts/startup/01-startup-listener.sh && \
    chown oracle:oinstall /container-entrypoint-initdb.d/01-install-apex.sh \
                          /opt/oracle/scripts/setup/01-install-apex.sh \
                          /opt/oracle/scripts/startup/01-startup-listener.sh

USER oracle
