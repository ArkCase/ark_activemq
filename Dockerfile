FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_base_java11:latest

LABEL   ORG="Armedia LLC" \
        APP="ActiveMQ" \
        VERSION="1.0" \
        IMAGE_SOURCE="https://github.com/ArkCase/ark_activemq" \
        MAINTAINER="Armedia LLC"

# Environment variables: version
ENV ACTIVEMQ_VERSION="5.16.2"

# Environment variables: tarball stuff
ENV ACTIVEMQ="apache-activemq-$ACTIVEMQ_VERSION" \
    ACTIVEMQ_SHA512="27bb26786640f74dcf404db884bedffc0af4bfb2a0248c398044ac9a13e19ff097c590b79eb1404e0b04d17a8f85a8f7de87186a96744e19162d70b3c7a9bdde" \
# Environment variables: ActiveMQ directories
    ACTIVEMQ_HOME="/app/activemq" \
    ACTIVEMQ_BASE="/app/activemq" \
    ACTIVEMQ_CONF="/app/conf" \
    ACTIVEMQ_DATA="/app/data" \
    ACTIVEMQ_TMP="/app/tmp" \
# Activate the Prometheus JMX exporter
    ACTIVEMQ_SUNJMX_START="-javaagent:/app/jmx_prometheus_javaagent.jar=5556:/app/jmx-prometheus-config.yaml" \
# Environment variables: system stuff
    DEBIAN_FRONTEND="noninteractive"

WORKDIR /app
COPY activemqrc /app/home/.activemqrc
COPY jmx-prometheus-config.yaml .

RUN curl -fsSLo activemq.tgz "https://archive.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/${ACTIVEMQ}-bin.tar.gz" \
        && checksum=$(sha512sum activemq.tgz | awk '{ print $1 }') \
        && if [ $checksum != $ACTIVEMQ_SHA512 ]; then \
                echo "Unexpected SHA512 checksum; possible man-in-the-middle-attack"; \
                exit 1; \
            fi \
        && tar xf activemq.tgz \
        && rm activemq.tgz \
        && ln -s "/app/$ACTIVEMQ" /app/activemq \
        && curl -fsSLo jmx_prometheus_javaagent.jar https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.15.0/jmx_prometheus_javaagent-0.15.0.jar \
        && cd activemq \
        && rm bin/activemq-diag bin/env bin/wrapper.jar \
            activemq-all-5.16.2.jar conf/*.ts conf/*.ks \
        && rm -r bin/linux-x86-32 bin/linux-x86-64 bin/macosx \
            data docs examples webapps-demo \
        && useradd --system --no-create-home --home-dir /app/home activemq \
        && mkdir -p /app/home "$ACTIVEMQ_CONF" "$ACTIVEMQ_DATA" "$ACTIVEMQ_TMP" \
        && chown -R activemq:activemq /app/home "$ACTIVEMQ_CONF" "$ACTIVEMQ_DATA" "$ACTIVEMQ_TMP"

USER activemq
CMD ["/app/activemq/bin/activemq", "console"]
