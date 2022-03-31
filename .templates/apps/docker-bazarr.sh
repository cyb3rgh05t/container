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
APPLINK="https://api.github.com/repos/morpheus65535/bazarr"
NEWVERSION=$(curl -u $USERNAME:$TOKEN -sX GET "https://api.github.com/repos/morpheus65535/bazarr/releases/latest" | jq --raw-output '.tag_name')
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION#*release-}"
NEWVERSION="${NEWVERSION}"

HEADLINE="$(cat ./.templates/headline.txt)"
DESCRIPTION="$(curl -u $USERNAME:$TOKEN -sX GET "$APPLINK" | jq -r '.description')"
BASEIMAGE="ghcr.io/dockserver/docker-alpine:latest"
BUILDDATE="$(date +%Y-%m-%d)"

INSTCOMMAND="apk add -U --update --no-cache"
PACKAGES="curl ffmpeg libxml2 libxslt py3-pip python3 unzip"
VIRTUEL="--virtual=build-dependencies build-base cargo g++ gcc jq libffi-dev libxml2-dev libxslt-dev python3-dev"
APPSPEC="--repository http://dl-cdn.alpinelinux.org/alpine/v3.14/main unrar"

PYTHON3="pip3 install -U --no-cache-dir pip && \\
    pip install lxml --no-binary :all: && \\
    pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine/ -r /app/bazarr/bin/requirements.txt"

CLEANUP="apk del --purge build-dependencies && \\
   rm -rf /root/.cache /root/.cargo /tmp/"
PICTURE="./images/$APP.png"
APPFOLDER="./$FOLDER/$APP"
PORT="EXPOSE 6767"
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

ENV TZ="'"Etc/UTC"'"

RUN \
  echo "'"**** install packages ****"'" && \
    '"${INSTCOMMAND}"' '"${PACKAGES}"' && \
    '"${INSTCOMMAND}"' '"${VIRTUEL}"' && \
    '"${INSTCOMMAND}"' '"${APPSPEC}"' && \
  echo "'"**** install '"${APP}"' ****"'" && \
     curl -o /tmp/bazarr.zip -L "'"https://github.com/morpheus65535/bazarr/releases/download/"'${VERSION}'"/bazarr.zip"'' && \
     mkdir -p /app/bazarr/bin && \
     unzip /tmp/bazarr.zip -d /app/bazarr/bin && \
     rm -Rf /app/bazarr/bin/bin && \
     echo -e "'"UpdateMethod=docker\nBranch="'${BRANCH}'"\nPackageVersion="'${VERSION}'"\nPackageAuthor=[dockserver.io](https://dockserver.io)"'" > /app/bazarr/package_info && \
  echo "'"**** Install requirements ****"'" && \
   '"${PYTHON3}"' && \
  echo "'"**** cleanup ****"'" && \
    '"${CLEANUP}"'

COPY --chown=abc '"${APPFOLDER}"'/root/ /

'"${PORT}"'

'"${VOLUMEN}"'
##EOF' > ./$FOLDER/$APP/Dockerfile
