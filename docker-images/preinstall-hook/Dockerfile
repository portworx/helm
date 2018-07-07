# Utils image which contains jq and curl.
FROM alpine

RUN apk update \
 && apk add --update curl \
 && apk add jq \
 && apk add --update bash \
 && rm -rf /var/cache/apk/*

COPY etcdStatus.sh /usr/bin

ENTRYPOINT ["etcdStatus.sh"]
CMD [ ]