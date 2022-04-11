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
APPLINK="https://api.github.com/duplicati/duplicati"

## FOR DOCKER RELEASE NUMBER
NEWVERSION="$(curl -u $USERNAME:$TOKEN -sX GET "https://api.github.com/repos/duplicati/duplicati/releases" | jq -r '. | first(.[] | select(.tag_name)) | .tag_name' | sed -r 's/.{28}$//')"
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION#*release-}"
NEWVERSION="${NEWVERSION}"

## FOR INSTALL APP
APPVERSION="$(curl -u $USERNAME:$TOKEN -sX GET "https://api.github.com/repos/duplicati/duplicati/releases" | jq -r 'first(.[] | select(.tag_name | contains("beta"))) | .tag_name')"
APPVERSION="${APPVERSION#*v}"
APPVERSION="${APPVERSION#*release-}"
APPVERSION="${APPVERSION}"

DESCRIPTION="$(curl -u $USERNAME:$TOKEN -sX GET "$APPLINK" | jq -r '.description')"
HEADLINE="$(cat ./.templates/headline.txt)"
BASEIMAGE="ghcr.io/dockserver/docker-alpine:latest"

INSTCOMMAND="apk add -U --update --no-cache"
PACKAGES="unzip jq openssl curl tar sqlite-libs"
APPSPEC="--repository http://dl-cdn.alpinelinux.org/alpine/edge/testing mono libgdiplus terminus-font"
APPSPEC2="--repository http://dl-cdn.alpinelinux.org/alpine/v3.14/main unrar"
CLEANUP="rm -rf /tmp/* /var/tmp/*"

PICTURE="./images/$APP.png"
APPFOLDER="./$FOLDER/$APP"
PORT="EXPOSE 8200"
VOLUMEN="VOLUME /config"

### RELEASE SETTINGS ###

echo '{
   "appname": "'${APP}'",
   "apppic": "'${PICTURE}'",
   "appfolder": "./'$FOLDER'/'$APP'",
   "newversion": "'${NEWVERSION}'",
   "appbranch": "'${APPBRANCH}'",
   "baseimage": "'${BASEIMAGE}'",
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

ARG VERSION="'"${APPVERSION}"'"
ARG BRANCH="'"${APPBRANCH}"'"

ENV XDG_CONFIG_HOME="'"/config"'"

RUN \
  echo "'"**** install packages ****"'" && \
    '"${INSTCOMMAND}"' '"${PACKAGES}"' && \
    '"${INSTCOMMAND}"' '"${APPSPEC}"' && \
    '"${INSTCOMMAND}"' '"${APPSPEC2}"' && \
  echo "'"**** install '"${APP}"' ****"'" && \
    mkdir -p /app/duplicati && \
    curl -o /tmp/duplicati.zip -L "$(curl -s https://api.github.com/repos/duplicati/duplicati/releases/tags/v'"${APPVERSION}"' | jq -r '.assets[].browser_download_url' | grep zip | grep -v signatures)" && \
    unzip /tmp/duplicati.zip -d /app/duplicati && \
  echo "'"**** cleanup ****"'" && \
    '"${CLEANUP}"'

COPY --chown=abc '"${APPFOLDER}"'/root/ /

'"${PORT}"'
'"${VOLUMEN}"'
##EOF' > ./$FOLDER/$APP/Dockerfile
