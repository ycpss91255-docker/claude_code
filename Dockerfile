ARG BASE_IMAGE="node:20-slim"

############################## bats sources ##############################
FROM bats/bats:latest AS bats-src

FROM alpine:latest AS bats-extensions
RUN apk add --no-cache git && \
    git clone --depth 1 -b v0.3.0 \
        https://github.com/bats-core/bats-support /bats/bats-support && \
    git clone --depth 1 -b v2.1.0 \
        https://github.com/bats-core/bats-assert  /bats/bats-assert

############################## sys ##############################
FROM ${BASE_IMAGE} AS sys

ARG USER="initial"
ARG GROUP="initial"
ARG UID="1000"
ARG GID="${UID}"
ARG SHELL="/bin/bash"
ARG GPU_VARIANT="false"
ENV HOME="/home/${USER}"

# Env vars for nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES="all"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,utility,graphics"

SHELL ["/bin/bash", "-x", "-euo", "pipefail", "-c"]

# Setup users and groups
RUN if getent group "${GID}" >/dev/null; then \
        existing_grp="$(getent group "${GID}" | cut -d: -f1)"; \
        if [ "${existing_grp}" != "${GROUP}" ]; then \
            groupmod -n "${GROUP}" "${existing_grp}"; \
        fi; \
    else \
        groupadd -g "${GID}" "${USER}"; \
    fi; \
    \
    if getent passwd "${UID}" >/dev/null; then \
        existing_user="$(getent passwd "${UID}" | cut -d: -f1)"; \
        if [ "${existing_user}" != "${USER}" ]; then \
            usermod -l "${USER}" "${existing_user}"; \
        fi; \
        usermod -g "${GID}" -s "${SHELL}" -d "${HOME}" -m "${USER}"; \
    elif id -u "${USER}" >/dev/null 2>&1; then \
        usermod -u "${UID}" -g "${GID}" -s "${SHELL}" -d "${HOME}" -m "${USER}"; \
    else \
        useradd -u "${UID}" -g "${GID}" -s "${SHELL}" -m "${USER}"; \
    fi; \
    \
    mkdir -p /etc/sudoers.d; \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}"; \
    chmod 0440 "/etc/sudoers.d/${USER}"

# Setup locale and timezone
ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Asia/Taipei"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tzdata \
        locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen "en_US.UTF-8" && \
    update-locale LANG="en_US.UTF-8" && \
    ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

ENV LC_ALL="en_US.UTF-8"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"

# GPU-only: Install Node.js 20 (CUDA base image has no node)
RUN if [ "${GPU_VARIANT}" = "true" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
        apt-get install -y nodejs && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

############################## base ##############################
FROM sys AS base

ARG GPU_VARIANT="false"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        ca-certificates \
        gnupg \
        software-properties-common \
        # Dev tools
        git \
        curl \
        wget \
        tree \
        jq \
        ripgrep \
        # Python
        python3 \
        python3-pip \
        python3-dev \
        python3-setuptools \
        # Build tools
        make \
        g++ \
        cmake \
        # DinD
        docker.io \
        iptables \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# GPU-only: OpenCL + Vulkan
RUN if [ "${GPU_VARIANT}" = "true" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            ocl-icd-opencl-dev opencl-headers clinfo \
            libvulkan1 vulkan-tools && \
        mkdir -p /etc/OpenCL/vendors && \
        echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

############################## devel ##############################
FROM base AS devel

ARG USER
ARG GROUP
ARG ENTRYPOINT_FILE="entrypoint.sh"

# Claude Code only
RUN npm install -g @anthropic-ai/claude-code

# Add user to docker group for DinD
RUN usermod -aG docker "${USER}"

COPY --chmod=0755 "./${ENTRYPOINT_FILE}" "/entrypoint.sh"
COPY --chmod=0755 "./encrypt_env.sh" "/usr/local/bin/encrypt_env.sh"

USER "${USER}"
WORKDIR "${HOME}/work"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

############################## test (ephemeral) ##############################
FROM devel AS test

USER root

# Install bats
COPY --from=bats-src /opt/bats /opt/bats
COPY --from=bats-src /usr/lib/bats /usr/lib/bats
COPY --from=bats-extensions /bats /usr/lib/bats
RUN ln -sf /opt/bats/bin/bats /usr/local/bin/bats

ENV BATS_LIB_PATH="/usr/lib/bats"

COPY smoke_test/ /smoke_test/

ARG USER
USER "${USER}"

RUN bats /smoke_test/
