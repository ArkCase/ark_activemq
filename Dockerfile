FROM openjdk:11-jre

# Environment variables: version and tarball stuff
ENV ACTIVEMQ_VERSION 5.16.2
ENV ACTIVEMQ         apache-activemq-$ACTIVEMQ_VERSION
ENV ACTIVEMQ         apache-activemq-$ACTIVEMQ_VERSION
ENV ACTIVEMQ_SHA512  27bb26786640f74dcf404db884bedffc0af4bfb2a0248c398044ac9a13e19ff097c590b79eb1404e0b04d17a8f85a8f7de87186a96744e19162d70b3c7a9bdde

# Environment variables: ActiveMQ directories
ENV ACTIVEMQ_HOME /app/activemq
ENV ACTIVEMQ_BASE $ACTIVEMQ_HOME
ENV ACTIVEMQ_CONF /app/conf
ENV ACTIVEMQ_DATA /app/data
ENV ACTIVEMQ_TMP  /app/tmp

# Environment variables: system stuff
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /app
# XXX remove the next line (it's for dev only)
#COPY activemq.tgz .

#RUN if false; then curl -fsSLo activemq.tgz "https://archive.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/${ACTIVEMQ}-bin.tar.gz"; fi 
RUN curl -fsSLo activemq.tgz "https://archive.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/${ACTIVEMQ}-bin.tar.gz" \
        && checksum=$(sha512sum activemq.tgz | awk '{ print $1 }') \
        && if [ $checksum != $ACTIVEMQ_SHA512 ]; then \
                echo "Unexpected SHA512 checksum; possible man-in-the-middle-attack"; \
                exit 1; \
            fi \
        && tar xf activemq.tgz \
        && rm activemq.tgz \
        && ln -s "/app/$ACTIVEMQ" /app/activemq \
        && cd activemq \
        && rm bin/activemq-diag bin/env bin/wrapper.jar \
            activemq-all-5.16.2.jar conf/*.ts conf/*.ks \
        && rm -r bin/linux-x86-32 bin/linux-x86-64 bin/macosx \
            data docs examples webapps-demo \
        && useradd --system --no-create-home --home-dir /app/home activemq \
        && mkdir -p /app/home "$ACTIVEMQ_CONF" "$ACTIVEMQ_DATA" "$ACTIVEMQ_TMP" \
        && chown -R activemq:activemq "$ACTIVEMQ_CONF" "$ACTIVEMQ_DATA" "$ACTIVEMQ_TMP"

USER activemq
COPY activemqrc /app/home/.activemqrc

CMD ["/app/activemq/bin/activemq", "console"]
