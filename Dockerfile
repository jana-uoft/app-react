FROM node:10

RUN apk add --update curl && \
    rm -rf /var/cache/apk/*

RUN apk add --update git && \
    rm -rf /var/cache/apk/*