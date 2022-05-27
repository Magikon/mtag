FROM node:12-alpine3.15
LABEL "repository"="https://github.com/Magikon/mtag"
LABEL "homepage"="https://github.com/Magikon/mtag"
LABEL "maintainer"="Mikayel Galyan"

COPY entrypoint.sh /entrypoint.sh

RUN apk update && apk add bash git curl jq && npm install -g semver && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
