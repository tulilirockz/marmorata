install:
    #!/usr/bin/env bash
    INSTALL_LOCATION="$HOME/.config"
    if [ "$(id -u)" == "0" ] ; then
        INSTALL_LOCATION="/etc"
    fi
    mkdir -p "${INSTALL_LOCATION}/containers/systemd/"

    find . \
        '(' \
        -name '*.container' \
        -or -name '*.pod' \
        -or -name '*.network' \
        ')' -print0 | \
    while IFS= read -r -d '' line; do 
        envsubst < "${line}" > "${INSTALL_LOCATION}/containers/systemd/${line}"
    done

reinstall $app="": deploy
    #!/usr/bin/env bash
    set -x
    INSTALL_LOCATION="$HOME/.config"
    if [ "$(id -u)" == "0" ] ; then
        INSTALL_LOCATION="/etc"
    fi
    if [ "${app}" == "" ] ; then
        app="$(basename "${PWD}")"
    fi
    systemctl --user stop $app*.service
    rm -f $INSTALL_LOCATION/containers/systemd/$app*
    podman ps -a -q | grep "${app}" | xargs -n1 podman stop
    podman ps -a -q | grep "${app}" | xargs -n1 podman rm

deploy: install
    #!/usr/bin/env bash
    if [ "$(id -u)" == "0" ] ; then
        systemctl daemon-reload
    fi
    systemctl --user daemon-reload

debug: deploy
    /usr/libexec/podman/quadlet -dryrun -user | "${EDITOR}"

clean $app="":
    #!/usr/bin/env bash
    set -x
    INSTALL_LOCATION="$HOME/.config"
    if [ "$(id -u)" == "0" ] ; then
        INSTALL_LOCATION="/etc"
    fi
    if [ "${app}" == "" ] ; then
        app="$(basename "${PWD}")"
    fi
    systemctl --user stop $app*.service
    rm -f $INSTALL_LOCATION/containers/systemd/$app*
    podman ps -a -q | grep "${app}" | xargs -n1 podman stop
    podman volume ls -q | grep "${app}" | xargs -n1 podman volume rm
    podman ps -a -q | grep "${app}" | xargs -n1 podman rm 
    podman network ls -q | grep "${app}" | xargs -n1 podman network rm || true

read-secret $SECRET="":
    podman run --rm -it --secret "${SECRET},type=env,target=ENVSEC" docker.io/library/busybox:latest sh -c 'echo $ENVSEC'

gen-random-key $PODMAN_SECRET="":
    openssl rand 128 | openssl base64 | xargs | podman secret create --replace "${PODMAN_SECRET}" -

setup-system:
    systemctl enable --now podman.socket
    systemctl enable --user --now podman.socket
    sudo setsebool -P container_use_dri_devices 1
