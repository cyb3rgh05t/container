#!/bin/bash
####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
#####################################
# THIS DOCKER IS UNDER LICENSE      #
# NO CUSTOMIZING IS ALLOWED         #
# NO REBRANDING IS ALLOWED          #
# NO CODE MIRRORING IS ALLOWED      #
#####################################
# shellcheck disable=SC2086
# shellcheck disable=SC2046

FOLDER=$1
APP=$2
USERNAME=$3
TOKEN=$4

### NIGHTLY HACK

APPNIGHTLY=$(echo $APP | sed "s#-nightly##g" )
if [[ $FOLDER == "nightly" ]]; then
   FOLDERNIGHTLY=apps
fi

### APP SETTINGS ###

APPBRANCH="develop"
APPLINK="https://api.github.com/repos/sabnzbd/sabnzbd"
NEWVERSION=$(curl -fsSL "https://api.github.com/repos/sabnzbd/sabnzbd/commits/${APPBRANCH}" | jq -r .sha)
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION#*release-}"
NEWVERSION="${NEWVERSION}"

HEADLINE="$(cat ./.templates/headline.txt)"
DESCRIPTION="$(curl -u $USERNAME:$TOKEN -sX GET "$APPLINK" | jq -r '.description')"
BASEIMAGE="ghcr.io/dockserver/docker-alpine:latest"

INSTCOMMAND="apk add -U --update --no-cache"
PACKAGES="jq ffmpeg curl p7zip par2cmdline python3 py3-pip"

VIRTUEL="--virtual=build-dependencies build-base gcc jq libffi-dev openssl-dev python3-dev"
##APPSPEC="--repository http://dl-cdn.alpinelinux.org/alpine/v3.14/main unrar"
UNRAR="cd /tmp/unrar && make && install -v -m755 unrar /usr/local/bin"

PYTHON3="python3 -m pip install --upgrade pip && \\
    pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.15/ wheel apprise pynzb requests && \\
    pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.15/ -r /app/sabnzbd/requirements.txt"

CLEANUP="ln -s /usr/bin/python3 /usr/bin/python && \\
    apk del --purge build-dependencies && \\
    rm -rf /var/cache/apk/* /tmp/* /config/.cache"

PICTURE="./images/$APP.png"
APPFOLDER="./$FOLDERNIGHTLY/$APPNIGHTLY"
PORT="EXPOSE 8080 9090"
VOLUMEN="VOLUME /config"

### RELEASE SETTINGS ###

echo '{
   "appname": "'${APP}'",
   "apppic": "'${PICTURE}'",
   "appfolder": "./'$FOLDER'/'$APP'",
   "newversion": "'${NEWVERSION}'",
   "appbranch": "'${APPBRANCH}'",
   "description": "'${DESCRIPTION}'",
   "body": "Upgrading '${APP}' to '${NEWVERSION}'",
   "user": "github-actions[bot]"
}' > "./$FOLDER/$APP/release.json"

### DOCKER BUILD ###
### GENERATE Dockerfile based on release.json

echo '## This file is automatically generated (based on release.json)
##
## Do not changes any lines here
##
'"${HEADLINE}"'
FROM '"${BASEIMAGE}"'
LABEL org.opencontainers.image.source="'"https://github.com/dockserver/container"'"

ARG TARGETPLATFORM
ARG BUILDPLATFORM

ARG VERSION="'"${NEWVERSION}"'"
ARG BRANCH="'"${APPBRANCH}"'"
ARG UNRAR_VERSION=6.1.4

ENV XDG_CONFIG_HOME="'"/config"'" \
PYTHONIOENCODING=utf-8

RUN \
  echo "'"**** install packages ****"'" && \
    '"${INSTCOMMAND}"' '"${VIRTUEL}"' && \
    '"${INSTCOMMAND}"' '"${PACKAGES}"' && \
  echo "'"**** install unrar ****"'" && \
    mkdir -p /tmp/unrar && \
    curl -fsSL "'"https://www.rarlab.com/rar/unrarsrc-"'"${UNRAR_VERSION}"'".tar.gz"'" | tar xzf - -C /tmp/unrar --strip-components=1 && \
    '"${UNRAR}"' && \
  echo "'"**** install '"${APP}"' ****"'" && \
    mkdir -p /app/sabnzbd && \
    curl -fsSL "'"https://github.com/sabnzbd/sabnzbd/archive/"'"${VERSION}"'".tar.gz"'" | tar xzf - -C /app/sabnzbd --strip-components=1 && \
    '"${PYTHON3}"' && \
  echo "'"**** cleanup ****"'" && \
    '"${CLEANUP}"'

COPY --chown=abc '"${APPFOLDER}"'/root/ /

'"${PORT}"'
'"${VOLUMEN}"'
##EOF' > ./$FOLDER/$APP/Dockerfile
