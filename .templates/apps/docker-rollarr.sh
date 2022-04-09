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

APPLINK="https://github.com/TheHumanRobot/Rollarr"

NEWVERSION=$(curl -sX GET "https://registry.hub.docker.com/v1/repositories/library/ubuntu/tags" \
   | jq --raw-output '.[] | select(.name | contains(".")) | .name' \
   | sort -t "." -k1,1n -k2,2n -k3,3n | tail -n1)
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION#*release-}"
NEWVERSION="${NEWVERSION}"

HEADLINE="$(cat ./.templates/headline.txt)"
DESCRIPTION="This is the new and improved Automatic Pre-roll script with a GUI for Plex now called Rollarr!"

BASEIMAGE="ubuntu"

ENCOPY="ENV LANG=C.UTF-8 \\
    TZ=UTC \\
    PUID=1000 \\
    PGID=1000 \\
    DEBIAN_FRONTEND=noninteractive \\
    PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

APPFOLDER="./$FOLDER/$APP"
PICTURE="./images/$APP.png"
APPFOLDER="./$FOLDER/$APP"
PORT="EXPOSE 3100"

ADDRUN="RUN \\
    chmod 755 /rollarr/* && \\
    ./rollarr/install.sh && \\
    rm -rf /rollarr/install.sh &>/dev/null"

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
FROM '"${BASEIMAGE}"':'"${NEWVERSION}"'

LABEL org.opencontainers.image.source="'"https://github.com/dockserver/container"'"

ARG TARGETPLATFORM
ARG BUILDPLATFORM

'"${ENCOPY}"'

CMD [ "'"bash"'" ]
COPY '"${APPFOLDER}"'/root/ /

'"${ADDRUN}"'

'"${FINALCMD}"'

'"${PORT}"'

'"${VOLUMEN}"'

CMD [ "'"./rollarr/run.sh"'" ]
##EOF' > ./$FOLDER/$APP/Dockerfile
