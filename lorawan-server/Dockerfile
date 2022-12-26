ARG BUILD_FROM
FROM $BUILD_FROM

ARG ERLANG_VERSION
ARG LORAWAN_SERVER_VERSION

RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
RUN dpkg -i erlang-solutions_1.0_all.deb
RUN apt-get update
RUN apt-get install esl-erlang=${ERLANG_VERSION}
RUN wget https://github.com/gotthardp/lorawan-server/releases/download/v${LORAWAN_SERVER_VERSION}/lorawan-server_${LORAWAN_SERVER_VERSION}_all.deb
RUN dpkg -i lorawan-server-${LORAWAN_SERVER_VERSION}.deb
RUN systemctl enable lorawan-server
RUN systemctl enable lorawan-server