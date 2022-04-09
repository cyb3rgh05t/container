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

APPLINK="https://api.github.com/repos/dockserver/dockserver"
BUILDVERSION=$(curl -sX GET "https://registry.hub.docker.com/v1/repositories/library/alpine/tags" \
   | jq --raw-output '.[] | select(.name | contains(".")) | .name' \
   | sort -t "." -k1,1n -k2,2n -k3,3n | tail -n1)
BUILDVERSION="${BUILDVERSION#*v}"
BUILDVERSION="${BUILDVERSION#*release-}"
BUILDVERSION="${BUILDVERSION}"

BUILDIMAGE="ghcr.io/dockserver/docker-alpine-v3"
ALPINEVERSION="${BUILDVERSION}"

HEADLINE="$(cat ./.templates/headline.txt)"
PICTURE="./images/$APP.png"
APPFOLDER="./$FOLDER/$APP"

INSTCOMMAND="apk add -U --update --no-cache --quiet"
CLEAN="apk del --purge --quiet"
VOLUMEN="VOLUME /system"
EPOINT="ENTRYPOINT /init"

UPCOMMAND="apk --quiet --no-cache --no-progress update && \\
    apk --quiet --no-cache --no-progress upgrade"

INSTCOMMAND="apk add -U --update --no-cache"
PACKAGES="bash ca-certificates shadow musl findutils linux-headers coreutils apk-tools busybox"

CLEANUP="apk del --quiet --clean-protected --no-progress && \\
    rm -f /var/cache/apk/*"

## S6 FIX
find ./$FOLDER/$APP/root/ -mindepth 1 -type f | while read rename; do
    sed -i 's|/usr/bin|/command|g' ${rename}
done

## RELEASE SETTINGS ###

echo '{
   "appname": "'${APP}'",
   "apppic": "'${PICTURE}'",
   "appfolder": "./'$FOLDER'/'$APP'",
   "newversion": "'${BUILDVERSION}'",
   "baseimage": "'${BUILDIMAGE}'",
   "baseversion": "'${ALPINEVERSION}'",
   "s6_stage": "'${S6_STAGE_VERSION}'",
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
FROM '"${BUILDIMAGE}"':v'"${BUILDVERSION}"'
LABEL org.opencontainers.image.source="'"https://github.com/dockserver/container"'"

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN \
  echo "'"**** update packages ****"'" && \
    '"${UPCOMMAND}"' && \
  echo "'"**** install build packages ****"'" && \
    '"${INSTCOMMAND}"' '"${PACKAGES}"' && \
  echo "'"**** set alpine version ****"'" && \
    echo -e "'"${BUILDVERSION}"'" > /etc/alpine-release && \
  echo "'"*** cleanup system ****"'" && \
    '"${CLEANUP}"'

COPY '"${APPFOLDER}"'/root/ /

'"${VOLUMEN}"'
'"${EPOINT}"'
##EOF' > ./$FOLDER/$APP/Dockerfile
