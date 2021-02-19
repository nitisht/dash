#!/bin/sh
#
# MinIO Cloud Storage, (C) 2019 MinIO, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

## generate random string
generate_cred() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''
}

setup_env() {
    POSTGRES_DB="minio_logs"
    POSTGRES_USER="postgres"
    POSTGRES_PASSWORD=$(generate_cred)
    export POSTGRES_DB
    export POSTGRES_USER
    export POSTGRES_PASSWORD

    LOGSEARCH_AUDIT_AUTH_TOKEN=$(generate_cred)
    LOGSEARCH_QUERY_AUTH_TOKEN=$(generate_cred)
    LOGSEARCH_PG_CONN_STR="postgres://postgres:$POSTGRES_PASSWORD@localhost:5432/$POSTGRES_DB?sslmode=disable"
    export LOGSEARCH_AUDIT_AUTH_TOKEN
    export LOGSEARCH_QUERY_AUTH_TOKEN
    export LOGSEARCH_PG_CONN_STR
}

## Start Console Server
start_console() {
    console server
}

## Legacy
## Set SSE_MASTER_KEY from docker secrets if provided
docker_sse_encryption_env() {
    SSE_MASTER_KEY_FILE="/run/secrets/$MINIO_SSE_MASTER_KEY_FILE"

    if [ -f "$SSE_MASTER_KEY_FILE" ]; then
        MINIO_SSE_MASTER_KEY="$(cat "$SSE_MASTER_KEY_FILE")"
        export MINIO_SSE_MASTER_KEY
    fi
}

# su-exec to requested user, if service cannot run exec will fail.
docker_switch_user() {
    if [ ! -z "${MINIO_USERNAME}" ] && [ ! -z "${MINIO_GROUPNAME}" ]; then
        if [ ! -z "${MINIO_UID}" ] && [ ! -z "${MINIO_GID}" ]; then
            groupadd -g "$MINIO_GID" "$MINIO_GROUPNAME" && \
                useradd -u "$MINIO_UID" -g "$MINIO_GROUPNAME" "$MINIO_USERNAME"
        else
            groupadd "$MINIO_GROUPNAME" && \
                useradd -g "$MINIO_GROUPNAME" "$MINIO_USERNAME"
        fi
        exec setpriv --reuid="${MINIO_USERNAME}" --regid="${MINIO_GROUPNAME}" --keep-groups "$@"
    else
        exec "$@"
    fi
}

## Set access env from secrets if necessary.
docker_secrets_env_old

## Set access env from secrets if necessary.
docker_secrets_env

## Set kms encryption from secrets if necessary.
docker_kms_encryption_env

## Set sse encryption from secrets if necessary. Legacy
docker_sse_encryption_env

## Switch to user if applicable.
docker_switch_user "$@"