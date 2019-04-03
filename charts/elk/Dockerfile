ARG ELASTIC_VERSION=6.6.2
ARG LOGTRAIL_VERSION=0.1.31
FROM docker.elastic.co/kibana/kibana:${ELASTIC_VERSION}

ARG ELASTIC_VERSION
ARG LOGTRAIL_VERSION

RUN set -x \
    && kibana-plugin install https://github.com/sivasamyk/logtrail/releases/download/v${LOGTRAIL_VERSION}/logtrail-${ELASTIC_VERSION}-${LOGTRAIL_VERSION}.zip