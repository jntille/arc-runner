# -----------------------------------------------------------------------------
# minimal arc runner image
# based on https://github.com/actions/runner/blob/main/images/Dockerfile
# -----------------------------------------------------------------------------
FROM docker.io/ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_MANUALLY_TRAP_SIG=1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1
ENV ImageOS=ubuntu24

# dependicies from the official base image
# https://www.kenmuse.com/blog/building-base-images-for-arc/
RUN apt update -y \
    && echo "official dependencies" \
    && apt install -y --no-install-recommends \
        ca-certificates \
        curl \
        gpg-agent \
        jq \
        lsb-release \
        software-properties-common \
        sudo \
        unzip \
    && add-apt-repository ppa:git-core/ppa && apt install -y git \
    && echo "custom dependencies" \
    && apt install -y --no-install-recommends \
        gettext-base \
        mawk \
        openssl \
        parallel \
        tar \
        vim \
        wget \
        zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# init
# https://github.com/yelp/dumb-init?tab=readme-ov-file#why-you-need-an-init-system
ARG DUMB_INIT_VERSION="1.2.5"
RUN curl -L https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 -o dumb-init \
    && chmod +x ./dumb-init && mv ./dumb-init /usr/local/bin/dumb-init

# create (non-root) user for runner
ENV RUNNER_USER=runner
ARG RUNNER_UID=1001
ARG RUNNER_GID=${RUNNER_UID}
ENV XDG_RUNTIME_DIR=/run/user/${RUNNER_UID}

RUN echo "Add non-root user" \
    && groupadd --gid $RUNNER_GID $RUNNER_USER \
    && useradd --uid $RUNNER_UID --gid $RUNNER_GID -m $RUNNER_USER --create-home --shell /bin/bash \
    && echo "(optional) Create XDG_RUNTIME_DIR" \
    && mkdir -p -m 0700 "${XDG_RUNTIME_DIR}" && chown $RUNNER_USER:$RUNNER_USER "${XDG_RUNTIME_DIR}" \
    && echo "(optional) Add user to sudoers" \
    && usermod -aG sudo ${RUNNER_USER} \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

# switch user
WORKDIR /home/runner
USER runner 

# arc runner essentials 
# https://github.com/actions/runner/blob/main/images/Dockerfile
ARG RUNNER_ARCH="x64"
ARG RUNNER_VERSION="2.327.1"
ARG RUNNER_CONTAINER_HOOKS_VERSION="0.7.0"

RUN echo "Get runner binaries" \
    && curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && echo "Get container hooks" \
    && curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm runner-container-hooks.zip

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/home/runner/run.sh"]

# -----------------------------------------------------------------------------
# extend base with specific cli tools
# -----------------------------------------------------------------------------
FROM base AS custom-cli

USER root

# ansible
RUN add-apt-repository --yes --update ppa:ansible/ansible \
    && apt install -y ansible-core \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# various
ARG AWS_CLI_VERSION="2.15.26"
ARG GH_CLI_VERSION="2.39.0"
ARG HELM_VERSION="v3.16.4"
ARG KUBECTL_VERSION="v1.30.8"
ARG KYVERNO_VERSION="v1.13.2"
ARG TRIVY_VERSION="0.58.1"
ARG VELERO_VERSION="v1.15.1"
ARG YQ_VERSION="v4.45.1"

WORKDIR /home/runner
RUN mkdir /home/runner/tmp-tools && cd /home/runner/tmp-tools \
    && echo "Gh" \
        && curl -L https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/gh_${GH_CLI_VERSION}_linux_amd64.tar.gz -o ghcli.tar.gz \
        && tar -xzf ghcli.tar.gz \
        && mv gh_${GH_CLI_VERSION}_linux_amd64/bin/gh /usr/local/bin/gh \
    && echo "Helm" \
        && curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz \
        && tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz \
        && mv linux-amd64/helm /usr/local/bin/helm \
    && echo "Kubectl" \
        && curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
        && chmod +x kubectl \
        && mv ./kubectl /usr/local/bin/kubectl \
    && echo "Kyverno" \
        && curl -LO https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/kyverno-cli_${KYVERNO_VERSION}_linux_x86_64.tar.gz \
        && tar -xvf kyverno-cli_${KYVERNO_VERSION}_linux_x86_64.tar.gz \
        && mv ./kyverno /usr/local/bin/kyverno \
    && echo "Trivy" \
        && curl -LO https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz \
        && tar -xvf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz \
        && mv ./trivy /usr/local/bin/trivy \
    && echo "Velero" \
        && curl -L https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz -o velero.tar.gz \
        && tar -xzf velero.tar.gz \
        && mv ./velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/velero \
    && echo "YQ" \
        && curl -LO https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64.tar.gz \
        && tar -xzf yq_linux_amd64.tar.gz \
        && mv ./yq_linux_amd64 /usr/local/bin/yq \
    && cd .. && rm -rf ./tmp-tools

RUN curl -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip \
    && unzip awscliv2.zip && ./aws/install \
    && rm -rf awscliv2.zip aws \
    && curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" \
    && dpkg -i session-manager-plugin.deb \
    && rm -f session-manager-plugin.deb

# switch back
USER runner

# -----------------------------------------------------------------------------
# add container runtime
# based on: https://github.com/containers/image_build/blob/main/podman/Containerfile
# docs:
# https://github.com/containers/image/blob/main/docs/containers-registries.conf.5.md
# https://github.com/containers/common/blob/main/docs/containers.conf.5.md
# https://github.com/containers/storage/blob/main/docs/containers-storage.conf.5.md
# -----------------------------------------------------------------------------
FROM custom-cli AS ubuntu-podman

# private registry (with pull-through mirror)
ENV CUSTOM_REGISTRY=""

# point testcontainers to podman
# https://java.testcontainers.org/supported_docker_environment/
ENV DOCKER_HOST="unix:///run/user/1001/podman/podman.sock"
ENV TESTCONTAINERS_RYUK_DISABLED=true

USER root

# install podman (with docker alias)
RUN apt update -y \
    && apt install -y --no-install-recommends \
        containers-storage \
        podman \
        podman-compose \
        podman-docker \
        uidmap \
        passt \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# configure podman

# fix uidmap binaries and assign user namespaces
# https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md#etcsubuid-and-etcsubgid-configuration
RUN setcap cap_setuid+ep /usr/bin/newuidmap && setcap cap_setgid+ep /usr/bin/newgidmap \
    && chmod u-s /usr/bin/newuidmap /usr/bin/newgidmap \
    && echo -n "" > /etc/subuid && echo -n "" > /etc/subgid \
    && usermod --add-subuids 1002-65535 --add-subgids 1002-65535 runner

# containers.conf
# https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md#containersconf
COPY --chown=runner:runner ./containers.conf /etc/containers/containers.conf
COPY --chown=runner:runner ./podman-containers.conf /home/runner/.config/containers/containers.conf
RUN mkdir -p /home/runner/.local/share/containers && \
    chmod 644 /etc/containers/containers.conf

# edit registries.conf for private registry mirror (rendered in entrypoint)
# https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md#registries
COPY --chown=runner:runner ./registries.conf /home/runner/.config/containers/registries.conf.template

# auth
# https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md#authorization-files

# edit storage.conf to use vfs as storgage driver
# https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md#storageconf
RUN cp /usr/share/containers/storage.conf /etc/containers/storage.conf \
    && sed -i '/^mount_program =/d' /etc/containers/storage.conf \
    && sed -i '/^mountopt =/d' /etc/containers/storage.conf \
    && sed -i 's|driver = "overlay"|driver = "vfs"|' /etc/containers/storage.conf

RUN chown runner:runner -R /home/runner

# Note VOLUME options must always happen after the chown call above
# RUN commands can not modify existing volumes
VOLUME /var/lib/containers
VOLUME /home/runner/.local/share/containers

RUN mkdir -p \
        /var/lib/shared/overlay-images \
        /var/lib/shared/overlay-layers \
        /var/lib/shared/vfs-images \
        /var/lib/shared/vfs-layers \
    && touch /var/lib/shared/overlay-images/images.lock \
    && touch /var/lib/shared/overlay-layers/layers.lock \
    && touch /var/lib/shared/vfs-images/images.lock \
    && touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED="" \
    BUILDAH_ISOLATION=chroot

# execute before starting runner
COPY --chown=runner:runner ./pre-start.sh /home/runner/pre-start.sh

USER runner
WORKDIR /home/runner

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["bash", "-c", "/home/runner/pre-start.sh && exec /home/runner/run.sh"]

# -----------------------------------------------------------------------------
# Squash layers
# -----------------------------------------------------------------------------
# FROM scratch AS final
# COPY --from=... / /
