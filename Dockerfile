FROM node:26-alpine AS builder
RUN apk update && apk add --no-cache git
RUN git clone --depth 1 https://gitlab.wikimedia.org/repos/mediawiki/services/mathoid.git /opt/mathoid
WORKDIR /opt/mathoid
RUN npm install --omit=dev
RUN cp config.dev.yaml config.yaml

FROM builder AS test
RUN npm install
RUN npm run test

FROM builder AS cleanup
RUN find /opt/mathoid -type d -name '.git' | xargs rm -rf {} \;
RUN find /opt/mathoid -type d -name 'test' | xargs rm -rf {} \;

FROM node:26-alpine
WORKDIR /opt/mathoid
RUN apk update && apk add --no-cache librsvg
COPY --from=cleanup /opt/mathoid /opt/mathoid
COPY ./root-fs/opt/init.sh /opt/init.sh

# Build timestamp (UTC, YmdHis)
RUN mkdir -p /image && date -u +%Y%m%d%H%M%S > /image/BUILDINFO

EXPOSE 10044
USER 1001
ENTRYPOINT [ "/opt/init.sh"]
