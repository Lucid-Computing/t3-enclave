# syntax=docker/dockerfile:1.6
#
# Pathfinder confidential dev box. systemd-based Ubuntu workspace with SSH,
# modelled on tinfoilsh/confidential-ubuntu. The base is digest-pinned; the
# release workflow pins the resulting image digest into tinfoil-config.yml.
ARG BASE_IMAGE=docker.io/library/ubuntu:24.04@sha256:224a1869083a311ef3f13648a154ba79832fbef6364d31493642ca03082da254

FROM ${BASE_IMAGE}
ENV container=docker LANG=en_US.UTF-8

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg git less vim-tiny tmux rsync htop jq unzip \
      ripgrep build-essential pkg-config \
      python3 python3-venv python3-pip nodejs npm \
      openssh-server iproute2 procps dnsutils iputils-ping util-linux \
      systemd systemd-sysv dbus dbus-user-session libpam-systemd \
      bash-completion locales \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
         > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && locale-gen en_US.UTF-8 \
    && rm -f /usr/sbin/policy-rc.d \
    && rm -f /etc/ssh/ssh_host_* \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 entrypoint.sh /entrypoint
COPY rootfs/ /
RUN chmod 0755 /healthcheck.sh /usr/local/bin/* \
    && for script in /entrypoint /healthcheck.sh /usr/local/bin/workspace-bootstrap; do bash -n "$script" || exit 1; done

RUN systemctl disable ssh.socket \
    && systemctl enable ssh.service \
    && systemctl mask systemd-udevd.service systemd-udevd-control.socket systemd-udevd-kernel.socket \
         systemd-networkd.service systemd-networkd.socket systemd-networkd-wait-online.service \
         systemd-resolved.service systemd-timesyncd.service console-getty.service \
    && systemctl set-default multi-user.target \
    && rm -f /etc/machine-id /var/lib/dbus/machine-id \
    && touch /etc/machine-id \
    && ln -s /etc/machine-id /var/lib/dbus/machine-id

EXPOSE 22
STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/entrypoint"]
