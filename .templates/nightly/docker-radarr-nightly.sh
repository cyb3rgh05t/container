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

APPBRANCH="nightly"
APPLINK="https://api.github.com/repos/radarr/radarr"
NEWVERSION=$(curl -u $USERNAME:TOKEN -sX GET https://api.github.com/repos/linuxserver/docker-radarr/releases | jq -r 'first(.[] | select(.target_commitish | contains("nightly") )) | .tag_name' 

#####select(.prerelease==true )) | .tag_name')

NEWVERSION="${NEWVERSION}"
DESCRIPTION="$(curl -u $USERNAME:$TOKEN -sX GET "$APPLINK" | jq -r '.description')"
PICTURE="./images/$APP.png"
APPFOLDER="./$FOLDERNIGHTLY/$APPNIGHTLY"

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
FROM lscr.io/linuxserver/radarr:'"${NEWVERSION}"'
COPY --chown=abc '"${APPFOLDER}"'/root/ /
##EOF' > ./$FOLDER/$APP/Dockerfile
