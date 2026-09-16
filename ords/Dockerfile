FROM oraclelinux:8

# Install dependencies
RUN dnf install -y java-17-openjdk unzip wget && dnf clean all

# Create directories
RUN mkdir -p /opt/oracle/ords /opt/oracle/ords-config /opt/oracle/apex

# Download ORDS and APEX (we need APEX for the static /images/ folder)
RUN cd /tmp && \
    wget -q https://download.oracle.com/otn_software/java/ords/ords-latest.zip -O ords.zip && \
    unzip -q ords.zip -d /opt/oracle/ords/ && \
    rm ords.zip && \
    wget -q https://download.oracle.com/otn_software/apex/apex-latest.zip -O apex.zip && \
    unzip -q apex.zip -d /opt/oracle/ && \
    rm apex.zip

# Create a non-root user for security
RUN groupadd -g 1000 ords && useradd -u 1000 -g ords -d /opt/oracle -s /bin/bash ords && \
    chown -R ords:ords /opt/oracle

COPY entrypoint.sh /opt/oracle/entrypoint.sh
RUN chmod +x /opt/oracle/entrypoint.sh && chown ords:ords /opt/oracle/entrypoint.sh

USER ords
WORKDIR /opt/oracle

ENTRYPOINT ["/opt/oracle/entrypoint.sh"]
