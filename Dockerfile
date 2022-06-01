# NB: Our `base_centos` image is a pure copy of the `centos` image available on
#     Docker hub. More information available
#     [here](https://arkcase.atlassian.net/wiki/spaces/AANTA/pages/1558446081/Process+for+updating+our+base+image+base+centos).
FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/base_centos:7-20210630

#
# Basic Parameters
#
ARG ARCH="amd64"
ARG OS="linux"
ARG VER="5.16.2"
ARG JMX_VER="0.17.0"
ARG PKG="activemq"
ARG AMQ_USER="${PKG}"

LABEL ORG="Armedia LLC"
LABEL MAINTAINER="Armedia Devops Team <devops@armedia.com>"
LABEL APP="ActiveMQ"
LABEL VERSION="${VER}"

# Environment variables: tarball stuff
ENV ACTIVEMQ="apache-activemq-${VER}"
ENV ACTIVEMQ_TARBALL="${ACTIVEMQ}-bin.tar.gz"
ENV JMX_PROMETHEUS_AGENT_JAR="jmx_prometheus_javaagent-${JMX_VER}.jar"
# Environment variables: ActiveMQ directories
ENV ACTIVEMQ_HOME="/app/activemq"
ENV ACTIVEMQ_BASE="/app/activemq"
ENV ACTIVEMQ_CONF="/app/conf"
ENV ACTIVEMQ_DATA="/app/data"
ENV ACTIVEMQ_TMP="/app/tmp"
# Activate the Prometheus JMX exporter
ENV ACTIVEMQ_SUNJMX_START="-javaagent:/app/jmx_prometheus_javaagent-${JMX_VER}.jar=9100:/app/jmx-prometheus-config.yaml"
# Environment variables: system stuff
ENV DEBIAN_FRONTEND="noninteractive"
ENV AMQ_USER="${AMQ_USER}"
# Environment variables: Java stuff
ENV JAVA_HOME="/usr/lib/jvm/jre-11-openjdk"

WORKDIR /app

#
# Create the required user
#
RUN useradd --no-create-home --user-group --home-dir /app/home "${AMQ_USER}"

#
# Update local packages
#
RUN yum -y update \
    && yum -y install java-11-openjdk \
    && yum clean all

#
# Download the missing artifacts
#
RUN curl \
        -L "https://www.apache.org/dyn/closer.cgi?filename=/${PKG}/${VER}/${ACTIVEMQ_TARBALL}&action=download" \
        -o - | tar -xzf -
RUN curl \
        -L "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_VER}/${JMX_PROMETHEUS_AGENT_JAR}" \
        -o "/app/jmx_prometheus_javaagent-${JMX_VER}.jar"

#
# Install the remaining files
#
COPY activemqrc /app/home/.activemqrc
COPY jmx-prometheus-config.yaml startup.sh ./

#
# Final file organization
#
RUN ln -s "/app/${ACTIVEMQ}" "/app/${PKG}" \
    && cd "${PKG}" \
    && rm bin/activemq-diag bin/env bin/wrapper.jar activemq-all-5.16.2.jar conf/*.ts conf/*.ks \
    && rm -r bin/linux-x86-32 bin/linux-x86-64 bin/macosx data docs examples webapps-demo \
    && mkdir -p /app/home "${ACTIVEMQ_CONF}" "${ACTIVEMQ_DATA}" "${ACTIVEMQ_TMP}" \
    && chown -R "${AMQ_USER}:" /app/home "${ACTIVEMQ_CONF}" "${ACTIVEMQ_DATA}" "${ACTIVEMQ_TMP}" \
    && cd "/app/${PKG}/conf" \
    && find . | cpio -pumadv "${ACTIVEMQ_CONF}"

#
# Launch as root, but the startup script should exec into an activemq-owned process
#
USER root
EXPOSE 1883 5672 8161 9100 61613 61614 61616
VOLUME [ "/app/data", "/app/conf" ]
ENTRYPOINT [ "/app/startup.sh" ]
