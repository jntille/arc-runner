#!/usr/bin/env bash

# create tap device for rootless networking
sudo mkdir /dev/net
sudo mknod /dev/net/tun c 10 200
sudo chmod 0666 /dev/net/tun

# dynamic configuration
echo "Render registries.conf"
envsubst < $HOME/.config/containers/registries.conf.template >> $HOME/.config/containers/registries.conf \
  && rm -f $HOME/.config/containers/registries.conf.template

# Enable a listening service for API access to Podman commands.
# https://github.com/containers/podman/blob/main/docs/tutorials/socket_activation.md
# https://docs.podman.io/en/latest/markdown/podman-system-service.1.html
echo "Start Podman Socket ..."
podman system service --time=0 &

wait_for_podman() {
  local retries=5
  local count=0

  while [[ $count -lt $retries ]]; do
    if curl --silent --unix-socket $XDG_RUNTIME_DIR/podman/podman.sock http://localhost/_ping > /dev/null; then
      echo "Up and running."
      return 0
    fi
    count=$((count + 1))
    echo "Not ready yet. Retrying... ($count/$retries)"
    sleep 1
  done

  echo "Failed to start within retry limit."
  exit 1
}

echo "Wait until Podman socket is ready ..."
wait_for_podman

echo "Podman Info"
podman info
