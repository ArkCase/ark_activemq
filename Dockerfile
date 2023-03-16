###########################################################################################################
#
# How to build:
#
# docker build -t ${BASE_REGISTRY}/arkcase/activemq:latest .
# docker push ${BASE_REGISTRY}/arkcase/activemq:latest
#
# How to run: (Helm)
#
# helm repo add arkcase https://arkcase.github.io/ark_helm_charts/
# helm install ark-activemq arkcase/ark-activemq
# helm uninstall ark-activemq
#
# How to run: (Docker)
#
# docker run --name ark_activemq -p 8161:8161  -d ${BASE_REGISTRY}/arkcase/activemq:latest 
# docker exec -it ark_activemq /bin/bash
# docker stop ark_activemq
# docker rm ark_activemq
#
# How to run: (Kubernetes)
#
# kubectl create -f pod_ark_activemq.yaml
# kubectl --namespace default port-forward activemq 8080:8161 --address='0.0.0.0'
# kubectl exec -it pod/activemq -- bash
# kubectl delete -f pod_ark_activemq.yaml
#
###########################################################################################################

ARG BASE_REGISTRY
ARG BASE_REPO="arkcase/base"
ARG BASE_TAG="8.7.0"

FROM "${BASE_REGISTRY}/${BASE_REPO}:${BASE_TAG}"

#
# Basic Parameters
#
ARG ARCH="amd64"
ARG OS="linux"
#ARG VER="5.16.2"
ARG VER="5.17.3"
ARG JMX_VER="0.17.0"
ARG PKG="activemq"
ARG APP_UID="1998"
ARG APP_GID="${APP_UID}"
ARG APP_USER="${PKG}"
ARG APP_GROUP="${APP_USER}"

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
ENV APP_UID="${APP_UID}"
ENV APP_GID="${APP_GID}"
ENV APP_USER="${APP_USER}"
ENV APP_GROUP="${APP_GROUP}"
# Environment variables: Java stuff
ENV JAVA_HOME="/usr/lib/jvm/jre-11-openjdk"
ENV USER="${APP_USER}"

WORKDIR /app

#
# Update local packages
#
RUN yum -y update && \
    yum -y install java-11-openjdk-devel && \
    yum clean all

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
# Create the required user/group
#
RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}"
RUN useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --no-create-home --home-dir /app/home "${APP_USER}"

#
# Final file organization
#
#RUN ln -s "/app/${ACTIVEMQ}" "/app/${PKG}" \
RUN mv  "/app/${ACTIVEMQ}" "/app/${PKG}" && \
    cd "/app/${PKG}" && \
    rm bin/activemq-diag bin/env bin/wrapper.jar "activemq-all-${VER}.jar" conf/*.ts conf/*.ks && \
    rm -r bin/linux-x86-32 bin/linux-x86-64 bin/macosx data docs examples webapps-demo && \
    mkdir -p /app/home "${ACTIVEMQ_CONF}" "${ACTIVEMQ_DATA}" "${ACTIVEMQ_TMP}" && \
    chown -R "${APP_USER}:" /app/home "${ACTIVEMQ_CONF}" "${ACTIVEMQ_DATA}" "${ACTIVEMQ_TMP}" && \
    cd "/app/${PKG}/conf" && \
    find . | cpio -pumadv "${ACTIVEMQ_CONF}"

#
# Launch as the application's user
#
USER "${APP_USER}"
EXPOSE 1883 5672 8161 9100 61613 61614 61616
VOLUME [ "/app/data", "/app/conf" ]
ENTRYPOINT [ "/app/startup.sh" ]
