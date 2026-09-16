ARG BASE_IMAGE=gvenzl/oracle-free:latest
FROM ${BASE_IMAGE}

USER root

# Install dependencies for downloading and extracting APEX
RUN if command -v microdnf &> /dev/null; then \
        microdnf install -y unzip wget && microdnf clean all; \
    elif command -v dnf &> /dev/null; then \
        dnf install -y unzip wget && dnf clean all; \
    else \
        apt-get update && apt-get install -y unzip wget && rm -rf /var/lib/apt/lists/*; \
    fi

# Create directory and download APEX
RUN mkdir -p /opt/oracle/apex && \
    cd /tmp && \
    wget -q https://download.oracle.com/otn_software/apex/apex-latest.zip -O apex-latest.zip && \
    unzip -q apex-latest.zip -d /opt/oracle/ && \
    rm apex-latest.zip && \
    chown -R oracle:oinstall /opt/oracle/apex

# Copy the initialization script that installs APEX
COPY install-apex.sh /container-entrypoint-initdb.d/01-install-apex.sh
COPY install-apex.sh /opt/oracle/scripts/setup/01-install-apex.sh

RUN chmod +x /container-entrypoint-initdb.d/01-install-apex.sh /opt/oracle/scripts/setup/01-install-apex.sh && \
    chown oracle:oinstall /container-entrypoint-initdb.d/01-install-apex.sh /opt/oracle/scripts/setup/01-install-apex.sh

USER oracle
