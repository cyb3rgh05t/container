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

APPLINK="https://api.github.com/repos/alpinelinux/docker-alpine"
NEWVERSION=$(curl -sX GET "https://registry.hub.docker.com/v2/repositories/library/alpine/tags" \
   | jq -r 'select(.results != null) | .results[]["name"]' \
   | sort -t "." -k1,1n -k2,2n -k3,3n | tail -n1)
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION#*release-}"
NEWVERSION="${NEWVERSION}"
HEADLINE="$(cat ./.templates/headline.txt)"
DESCRIPTION="$(curl -u $USERNAME:$TOKEN -sX GET "$APPLINK" | jq -r '.description')"
BASEIMAGE="alpine"
INSTCOMMAND="apk add -U --update --no-cache"
PACKAGES="git bash ca-certificates shadow"

GITAPP="git clone --quiet https://github.com/Xarritomi/auto-replyarr.git /app"
CLEANUP="rm -rf /app/*.md /app/Dockerfile docker-compose.yml"

## FINALIMAGE
FINALIMAGE="node:16-alpine3.14"
BUILDSTAGE="--from=buildstage /app /app"
PACKAGESBUILD="ca-certificates bash"
NPMINSTALL="npm install -g npm@8.5.0 && \\
   npm install -g ts-node && \\
   npm install"

APPFOLDER="./$FOLDER/$APP"
VOLUMEN="VOLUME /config"


### RELEASE SETTINGS ###

echo '{
   "appname": "'${APP}'",
   "apppic": "'${PICTURE}'",
   "appfolder": "./'$FOLDER'/'$APP'",
   "newversion": "'${NEWVERSION}'",
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
#####################################
# Original coder Xaritomi -SBOX     #
#####################################
FROM '"${BASEIMAGE}"':'"${NEWVERSION}"' as buildstage

LABEL org.opencontainers.image.source="'"https://github.com/dockserver/container"'"

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN  \
  echo "'"**** install build packages ****"'" && \
    '"${INSTCOMMAND}"' '"${PACKAGES}"' && \
    mkdir -p /app && \
    '"${GITAPP}"' && \
    '"${CLEANUP}"'

FROM '"${FINALIMAGE}"'
ENV DOCKER=true
COPY '"${BUILDSTAGE}"'

WORKDIR /app

RUN  \
  echo "'"**** install final packages ****"'" && \
    '"${INSTCOMMAND}"' '"${PACKAGESBUILD}"' && \
    mkdir -p /app && \
    '"${NPMINSTALL}"'

'"${VOLUMEN}"'

CMD ["'"/bin/bash"'", "'"/app/entrypoint.sh"'"]
##EOF' > ./$FOLDER/$APP/Dockerfile
