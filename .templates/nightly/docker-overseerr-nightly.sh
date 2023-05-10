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
APPLINK="https://api.github.com/repos/sct/overseerr"
NEWVERSION=$(curl -sX GET "https://api.github.com/repos/sct/overseerr/commits?sha=${APPBRANCH}" | jq -r 'first(.[] | select(.commit.message | contains("[skip ci]") | not)) | .sha')
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION#*release-}"
NEWVERSION="${NEWVERSION}"

HEADLINE="$(cat ./.templates/headline.txt)"
DESCRIPTION="$(curl -u $USERNAME:$TOKEN -sX GET "$APPLINK" | jq -r '.description')"
BASEIMAGE="ghcr.io/dockserver/docker-alpine-v3:latest"

INSTCOMMAND="apk add -U --update --no-cache"
PACKAGES="jq yarn curl wget tar"
VIRTUEL="--virtual=build-dependencies build-base python3"
YARN="cd /app/overseerr && \\
    export NODE_OPTIONS=--max_old_space_size=2048 && \\
    CYPRESS_INSTALL_BINARY=0 yarn --frozen-lockfile --network-timeout 1000000 && \\
    yarn build && yarn install --production --ignore-scripts --prefer-offline && \\
    yarn cache clean"

LEFTOVER="rm -rf /app/overseerr/src /app/overseerr/server /app/overseerr/Dockerfile"
LINK2="rm -rf /app/overseerr/config && \\
    ln -s /config /app/overseerr/config && \\
    touch /config/DOCKER"

CLEANUP="apk del --purge build-dependencies && \\
    rm -rf /root/.cache /tmp/* /app/overseerr/.next/cache/*"

PICTURE="./images/$APP.png"
APPFOLDER="./$FOLDERNIGHTLY/$APPNIGHTLY"
PORT="EXPOSE 5055"
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
   "user": "dockserver image update[bot]"
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

ENV HOME="'"/config"'"

RUN \
  echo "'"**** install packages ****"'" && \
    '"${INSTCOMMAND}"' '"${VIRTUEL}"' && \
  echo "'"**** install runtime packages ****"'" && \
    '"${INSTCOMMAND}"' '"${PACKAGES}"' && \
    export COMMIT_TAG="${VERSION}" && \
  echo "'"**** install '"${APP}"' ****"'" && \
    mkdir -p /app/overseerr && \
    curl -fsSL "'"https://github.com/sct/overseerr/archive/"'${VERSION}'".tar.gz"'" | tar xzf - -C /app/overseerr --strip-components=1 && \
    '"${YARN}"' && \
    '"${LEFTOVER}"' && \
  echo "{\"commitTag\": \"${COMMIT_TAG}\"}" > committag.json && \
    '"${LINK2}"' && \
  echo "'"**** cleanup ****"'" && \
    '"${CLEANUP}"'

COPY --chown=abc '"${APPFOLDER}"'/root/ /

'"${PORT}"'
'"${VOLUMEN}"'
##EOF' > ./$FOLDER/$APP/Dockerfile
