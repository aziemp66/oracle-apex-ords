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
ENV APEX_VERSION=${APEX_VERSION}

# Create directory for APEX with oracle ownership
RUN mkdir -p /opt/oracle/apex && \
    chown -R oracle:oinstall /opt/oracle/apex

# Copy the initialization scripts and entrypoint
RUN mkdir -p /container-entrypoint-initdb.d /opt/oracle/scripts/setup /opt/oracle/scripts/startup
COPY entrypoint.sh /opt/oracle/entrypoint.sh
COPY install-apex.sh /container-entrypoint-initdb.d/01-install-apex.sh
COPY install-apex.sh /opt/oracle/scripts/setup/01-install-apex.sh
COPY startup-listener.sh /opt/oracle/scripts/startup/01-startup-listener.sh

RUN chmod +x /opt/oracle/entrypoint.sh \
             /container-entrypoint-initdb.d/01-install-apex.sh \
             /opt/oracle/scripts/setup/01-install-apex.sh \
             /opt/oracle/scripts/startup/01-startup-listener.sh && \
    chown oracle:oinstall /opt/oracle/entrypoint.sh \
                          /container-entrypoint-initdb.d/01-install-apex.sh \
                          /opt/oracle/scripts/setup/01-install-apex.sh \
                          /opt/oracle/scripts/startup/01-startup-listener.sh

ENTRYPOINT ["/opt/oracle/entrypoint.sh"]
