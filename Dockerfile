FROM registry.access.redhat.com/ubi8/ubi-minimal:8.3

LABEL name="MinIO" \
      vendor="MinIO Inc <dev@min.io>" \
      maintainer="MinIO Inc <dev@min.io>" \
      version="v4.0.0" \
      release="v4.0.0" \
      summary="MinIO Operator brings native support for MinIO, Console, and Encryption to Kubernetes." \
      description="MinIO object storage is fundamentally different. Designed for performance and the S3 API, it is 100% open-source. MinIO is ideal for large, private cloud environments with stringent security requirements and delivers mission-critical availability across a diverse range of workloads."

COPY LICENSE /licenses/LICENSE
COPY logsearchapi /usr/bin/logsearchapi

RUN \
    microdnf update --nodocs && \
    # microdnf install postgresql --nodocs && \
    microdnf install curl ca-certificates shadow-utils --nodocs && \
    curl -s -q -L https://github.com/minio/console/releases/download/v0.6.0/console-linux-amd64 -o /usr/bin/console && \
    microdnf clean all && \
    chmod +x /usr/bin/console && \
    chmod +x /usr/bin/logsearchapi
    # mkdir -p /var/lib/pgsql/data && \
    # /usr/libexec/fix-permissions /var/lib/pgsql && \ 
    # /usr/libexec/fix-permissions /var/run/postgresql

EXPOSE 9090

ENTRYPOINT ["console","server"]
