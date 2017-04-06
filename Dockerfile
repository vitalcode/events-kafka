FROM openjdk:8

MAINTAINER vitalcode

RUN apt-get update && \
    apt-get -y install jq

ENV KAFKA_VERSION=0.10.2.0
ENV SCALA_VERSION=2.12

ENV KAFKA_FILE="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
ENV KAFKA_ARCHIVE_PATH="/tmp/${KAFKA_FILE}.tgz"
ENV KAFKA_HOME="/opt/kafka"
ENV PATH=${PATH}:${KAFKA_HOME}/bin

RUN APACHE_MIRROR=$(curl --stderr /dev/null https://www.apache.org/dyn/closer.cgi\?as_json\=1 | jq -r ".preferred") && \
    KAFKA_URL="${APACHE_MIRROR}/kafka/${KAFKA_VERSION}/${KAFKA_FILE}.tgz" && \
    wget "${KAFKA_URL}" -O ${KAFKA_ARCHIVE_PATH} && \
    tar xfz ${KAFKA_ARCHIVE_PATH} -C /opt && \
    ln -s /opt/${KAFKA_FILE} ${KAFKA_HOME}

VOLUME ["/kafka"]

ADD start-kafka.sh /usr/bin/
RUN chmod +x /usr/bin/start-kafka.sh

CMD ["start-kafka.sh"]
