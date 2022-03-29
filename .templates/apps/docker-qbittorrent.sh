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

### APP SETTINGS ###

APPBRANCH="master"
APPLINK="https://api.github.com/repos/ludviglundgren/qbittorrent-cli"

NEWVERSION=$(curl -fsSL "http://dl-cdn.alpinelinux.org/alpine/edge/community/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp && awk '/^P:qbittorrent-nox$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://')
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION#*release-}"
NEWVERSION="${NEWVERSION}"

QBT_VERSION=$(curl -u $USERNAME:$TOKEN -sX GET "https://api.github.com/repos/ludviglundgren/qbittorrent-cli/releases/latest" | jq --raw-output '.tag_name')
QBT_VERSION="${QBT_VERSION#*v}"
QBT_VERSION="${QBT_VERSION#*release-}"
QBT_VERSION="${QBT_VERSION}"

HEADLINE="$(cat ./.templates/headline.txt)"

DESCRIPTION="$(curl -u $USERNAME:$TOKEN -sX GET "$APPLINK" | jq -r '.description')"
BASEIMAGE="ghcr.io/linuxserver/baseimage-alpine:edge"

INSTCOMMAND="apk add -U --update --no-cache"
PACKAGES="bash jq tar curl python3"
UPCOMMAND="apk --quiet --no-cache --no-progress update && \\
    apk --quiet --no-cache --no-progress upgrade"
MOVE="mv /tmp/qbt /usr/bin"
LINKED="ln -s /usr/bin/python3 /usr/bin/python"

CLEANUP="rm -rf /tmp/* /var/cache/apk/*"

PICTURE="./images/$APP.png"
APPFOLDER="./$FOLDER/$APP"
PORT="EXPOSE 8080 6881 6881/udp"
VOLUMEN="VOLUME /config"

### RELEASE SETTINGS ###

echo '{
   "appname": "'${APP}'",
   "apppic": "'${PICTURE}'",
   "appfolder": "./'$FOLDER'/'$APP'",
   "newversion": "'${NEWVERSION}'",
   "appversion": "'${QBT_VERSION}'",
   "appbranch": "'${APPBRANCH}'",
   "baseimage": "'${BASEIMAGE}'",
   "description": "'${DESCRIPTION}'",
   "body": "Upgrading '${APP}' to '${NEWVERSION}' with '${QBT_VERSION}'",
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
ARG QBT_VERSION="'"${QBT_VERSION}"'"
ARG BRANCH="'"${APPBRANCH}"'"

ENV HOME="'"/config"'" \
    XDG_CONFIG_HOME="'"/config"'" \
    XDG_DATA_HOME="'"/config"'"

RUN \
  echo "'"**** update packages ****"'" && \
    '"${UPCOMMAND}"' && \
  echo "'"**** install packages ****"'" && \
    '"${INSTCOMMAND}"' '"${PACKAGES}"' qbittorrent-nox && \
  echo "'"**** symlink python3 for compatibility ****"'" && \
    '"${LINKED}"' && \
  echo "'"**** install '"${APP}"' ****"'" && \
    case $TARGETPLATFORM in \
      '"'linux/amd64'"') curl -fsSL "'"https://github.com/ludviglundgren/qbittorrent-cli/releases/download/v"'${QBT_VERSION}'"/qbittorrent-cli_"'${QBT_VERSION}'"_linux_amd64.tar.gz"'" | tar xzf - -C /tmp;; \
      '"'linux/arm64'"') curl -fsSL "'"https://github.com/ludviglundgren/qbittorrent-cli/releases/download/v"'${QBT_VERSION}'"/qbittorrent-cli_"'${QBT_VERSION}'"_linux_arm64.tar.gz"'" | tar xzf - -C /tmp;; \
      '"'linux/aarch64'"') curl -fsSL "'"https://github.com/ludviglundgren/qbittorrent-cli/releases/download/v"'${QBT_VERSION}'"/qbittorrent-cli_"'${QBT_VERSION}'"_linux_arm64.tar.gz"'" | tar xzf - -C /tmp;; \
    esac \
    && \
    '"${MOVE}"' && \
  echo "'"**** cleanup ****"'" && \
    '"${CLEANUP}"'

COPY --chown=abc '"${APPFOLDER}"'/root/ /

'"${PORT}"'
'"${VOLUMEN}"'
##EOF' > ./$FOLDER/$APP/Dockerfile
