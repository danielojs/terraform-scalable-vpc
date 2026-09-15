FROM mcr.microsoft.com/devcontainers/base:1-ubuntu-24.04

ARG SESSION_MANAGER_VERSION=1.2.835.0
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip jq dnsutils shellcheck \
    && rm -rf /var/lib/apt/lists/*

COPY install-session-manager.sh /tmp/install-session-manager.sh
RUN bash /tmp/install-session-manager.sh "${SESSION_MANAGER_VERSION}" \
    && rm /tmp/install-session-manager.sh
USER vscode
