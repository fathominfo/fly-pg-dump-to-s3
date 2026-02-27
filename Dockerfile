# https://hub.docker.com/_/alpine/tags
ARG ALPINE_IMAGE_TAG=3.22

FROM alpine:$ALPINE_IMAGE_TAG

LABEL org.opencontainers.image.source=https://github.com/fathominfo/fly-pg-dump-to-s3

RUN apk update && \
    apk add --no-cache \
        bash=5.2.37-r0 \
        curl-8.14.1-r2 \
        aws-cli=2.27.25-r0 \
        pigz=2.8-r1 \
        # Use the metapackage postgresql-client to find the appropriate postgresqlXX-client version
        postgresql17-client-17.8-r0 \
    && \
    curl -L https://fly.io/install.sh | sh

ENV PATH="/root/.fly/bin:$PATH"

COPY ./pg-dump-to-s3.sh ./entrypoint.sh /

CMD [ "/entrypoint.sh" ]
