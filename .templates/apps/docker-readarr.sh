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

APPBRANCH="nightly"
APPLINK="https://api.github.com/repos/readarr/r3adarr"
NEWVERSION=$(curl -sX GET "https://readarr.servarr.com/v1/update/${APPBRANCH}/changes?runtime=netcore&os=linuxmusl" | jq -r '.[0].version')
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION#*release-}"
NEWVERSION="${NEWVERSION}"

DESCRIPTION="$(curl -u $USERNAME:$TOKEN -sX GET "$APPLINK" | jq -r '.description')"
HEADLINE="$(cat ./.templates/headline.txt)"
BASEIMAGE="ghcr.io/dockserver/docker-alpine-v3:latest"

INSTCOMMAND="apk add -U --update --no-cache"
PACKAGES="chromaprint jq tar curl libintl sqlite-libs icu-libs"
CLEANUP="rm -rf /app/readarr/bin/Readarr.Update"

PICTURE="./images/$APP.png"
APPFOLDER="./$FOLDER/$APP"
PORT="EXPOSE 8787"
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

ARG VERSION="'"${NEWVERSION}"'"
ARG BRANCH="'"${APPBRANCH}"'"
ENV XDG_CONFIG_HOME="'"/config/xdg"'"

RUN \
  echo "'"**** install packages ****"'" && \
    '"${INSTCOMMAND}"' '"${PACKAGES}"' && \
  echo "'"**** install '"${APP}"' ****"'" && \
    mkdir -p /app/readarr/bin && \
    curl -fsSL "'"https://readarr.servarr.com/v1/update/"'${BRANCH}'"/updatefile?version="'${VERSION}'"&os=linuxmusl&runtime=netcore&arch=x64"'" | tar xzf - -C /app/readarr/bin --strip-components=1 && \
  echo -e "'"UpdateMethod=docker\nBranch="'${BRANCH}'"\nPackageVersion="'${VERSION}'"\nPackageAuthor=[dockserver.io](https://dockserver.io)"'" > /app/readarr/package_info && \
  echo "'"**** cleanup ****"'" && \
    '"${CLEANUP}"'

COPY --chown=abc '"${APPFOLDER}"'/root/ /

'"${PORT}"'

'"${VOLUMEN}"'
##EOF' > ./$FOLDER/$APP/Dockerfile
