install:
    #!/usr/bin/env bash
    INSTALL_LOCATION="$HOME/.config"
    if [ "$(id -u)" == "0" ] ; then
        INSTALL_LOCATION="/etc"
    fi
    mkdir -p "${INSTALL_LOCATION}/containers/systemd/"
    cp -f ./*.network "${INSTALL_LOCATION}/containers/systemd" || true
    cp -f ./*.pod "${INSTALL_LOCATION}/containers/systemd" || true
    cp -f ./*.container "${INSTALL_LOCATION}/containers/systemd" || true

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
        app="$(basename ${PWD})"
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
