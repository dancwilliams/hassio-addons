FROM erlang:20-alpine

RUN apk add --no-cache --virtual build-deps git make wget nodejs-npm && \
    git clone --depth 1 --branch v0.6.7 https://github.com/gotthardp/lorawan-server.git && \
    cd lorawan-server && \
    make release install && \
    cd .. && \
    rm -rf lorawan-server && \
    apk del build-deps

# volume for the mnesia database and logs
RUN mkdir /storage
VOLUME /storage

# data from port_forwarders
# EXPOSE 1680/udp
# admin interface
# EXPOSE 8080/tcp

ENV LORAWAN_HOME=/storage
WORKDIR /usr/lib/lorawan-server
CMD bin/lorawan-server