just := just_executable()

install $app="":
    #!/usr/bin/env bash
    set -x
    INSTALL_LOCATION="$HOME/.config"
    if [ "$(id -u)" == "0" ] ; then
        INSTALL_LOCATION="/etc"
    fi
    mkdir -p "${INSTALL_LOCATION}/containers/systemd/"

    if [ "${app}" == "" ] ; then
        app="."
    fi

    find "${app}" \
        '(' \
        -name '*.container' \
        -or -name '*.pod' \
        -or -name '*.network' \
        ')' -print0 | \
    while IFS= read -r -d '' line; do 
        echo "${INSTALL_LOCATION}/containers/systemd/${line}"
        envsubst < "${line}" > "${INSTALL_LOCATION}/containers/systemd/${line}"
    done

kill $app="":
    #!/usr/bin/env bash
    set -x
    INSTALL_LOCATION="$HOME/.config"
    if [ "$(id -u)" == "0" ] ; then
        INSTALL_LOCATION="/etc"
    fi
    if [ "${app}" == "" ] ; then
        app="$(basename "${PWD}")"
    fi

    if [ "$(id -u)" == "0" ] ; then
        systemctl stop $app*.service
    else
        systemctl --user stop $app*.service
    fi
    rm -f $INSTALL_LOCATION/containers/systemd/$app*
    podman ps -a -q | grep "${app}" | xargs -n1 podman stop || true
    podman ps -a -q | grep "${app}" | xargs -n1 podman rm || true
    {{ just }} daemon-reload

read-secret $SECRET="":
    set -x
    podman run --rm -it --secret "${SECRET},type=env,target=ENVSEC" docker.io/library/busybox:latest sh -c 'echo $ENVSEC'

gen-random-key $PODMAN_SECRET="":
    set -x
    openssl rand 128 | openssl base64 | xargs | podman secret create --replace "${PODMAN_SECRET}" -

setup-system:
    set -x
    systemctl enable --now podman.socket
    systemctl enable --user --now podman.socket
    sudo setsebool -P container_use_dri_devices 1

clean $app="":
    #!/usr/bin/env bash
    set -x
    if [ "${app}" == "" ] ; then
        app="$(basename "${PWD}")"
    fi
    {{ just }} kill $app
    podman volume ls -q | grep "${app}" | xargs -n1 podman volume rm
    podman network ls -q | grep "${app}" | xargs -n1 podman network rm || true
    {{ just }} daemon-reload

daemon-reload:
    #!/usr/bin/env bash
    set -x
    if [ "$(id -u)" == "0" ] ; then
        systemctl daemon-reload
    fi
    systemctl --user daemon-reload

debug: deploy
    set -x
    /usr/libexec/podman/quadlet -dryrun -user | "${EDITOR}"

deploy: install daemon-reload

start $app="":
    #!/usr/bin/env bash
    set -x
    if [ "${app}" == "" ] ; then
        app="$(basename "${PWD}")"
    fi
    if [ "$(id -u)" == "0" ] ; then
        systemctl start $app.service
    else
        systemctl --user start $app.service
    fi

firewalld-xml $app="":
    #!/bin/sh
    if [ "${app}" == "" ] ; then
        app="$(basename "${PWD}")"
    fi
    printf "%s\n" '<?xml version="1.0" encoding="utf-8"?>'
    printf "%s\n" '<service>'
    printf "\t%s\n" "<short>$app</short>"
    printf "\t%s\n" "<description>$(grep -E 'Description=.*' "./${app}/${app}.container" | cut -d'=' -f2)</description>"
    grep -oP 'PublishPort=.*' "./${app}/${app}.container" | \
        cut -d'=' -f2 | \
        uniq | \
        xargs -I{} printf "%s\0" "{}," | \
        while IFS= read -r -d '' line; do 
            printf "\t%s\n" "<port protocol=\"$(cut -f2 -d/ <<< $line | tr -d ',')\" port=\"$(cut -f1 -d: <<< $line | tr -d ',')\"/>"
        done
    printf "%s\n" '</service>'

firewall $app="":
    #!/usr/bin/env bash
    if [ "${app}" == "" ] ; then
        app="$(basename "${PWD}")"
    fi
    {{ just }} firewalld-xml "${app}" | tee "/etc/firewalld/services/${app}.xml"
