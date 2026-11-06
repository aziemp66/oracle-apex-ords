ARG BASE_IMAGE=container-registry.oracle.com/database/ords:26.3.1
FROM ${BASE_IMAGE}

USER root

# Install unzip if not present (for APEX extraction if fallback download is needed)
RUN if ! command -v unzip &> /dev/null; then \
        if command -v microdnf &> /dev/null; then \
            microdnf install -y unzip && microdnf clean all; \
        elif command -v dnf &> /dev/null; then \
            dnf install -y unzip && dnf clean all; \
        fi; \
    fi

ARG APEX_VERSION=26.2
ENV APEX_VERSION=${APEX_VERSION}

# Ensure directories exist with oracle user ownership
RUN mkdir -p /opt/oracle/apex /etc/ords/config && \
    chown -R oracle:oinstall /opt/oracle/apex /etc/ords/config

COPY entrypoint.sh /opt/oracle/entrypoint.sh
RUN chmod +x /opt/oracle/entrypoint.sh && chown oracle:oinstall /opt/oracle/entrypoint.sh

USER oracle
WORKDIR /opt/oracle/ords

ENTRYPOINT ["/opt/oracle/entrypoint.sh"]
