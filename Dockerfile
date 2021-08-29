FROM alpine
RUN apk add --no-cache bash curl bind-tools
COPY ddns.sh /
CMD /bin/bash /ddns.sh