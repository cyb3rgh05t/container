## This file is automatically generated (based on release.json)
##
## Do not changes any lines here
##
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
FROM alpine:3.21.3

LABEL org.opencontainers.image.source="https://github.com/dockserver/container"

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN \
  echo "**** update packages ****" && \
    apk --quiet --no-cache --no-progress update && \
  apk --quiet --no-cache --no-progress upgrade && \
  echo "**** install build packages ****" && \
    apk add -U --update --no-cache bash ca-certificates shadow musl findutils coreutils && \
  echo "*** cleanup system ****" && \
    apk del --quiet --clean-protected --no-progress && \
  rm -f /var/cache/apk/*

COPY ./apps/docker-dockupdate/root/start.sh /start.sh

ENTRYPOINT ["/bin/bash", "/start.sh"]
##EOF
