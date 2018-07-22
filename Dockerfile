FROM mhart/alpine-node:10

RUN apk add --update curl && \
    rm -rf /var/cache/apk/*