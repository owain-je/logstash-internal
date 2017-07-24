FROM centos:7

ARG ELASTIC_VERSION
ARG LOGSTASH_DOWNLOAD_URL

# Install curl for downloading, Java for running Logstash/JRuby, and netbase
# to resolve a warning from JRuby (https://github.com/jruby/jruby/issues/3955).
RUN yum update -y && \
    yum install -y netbase java-1.8.0-openjdk-headless && \
    yum clean all 

# Add Logstash itself.
RUN curl -Lso - ${LOGSTASH_DOWNLOAD_URL} | \
    tar zxf - -C /usr/share && \
    mv /usr/share/logstash-${ELASTIC_VERSION} /usr/share/logstash && \
    ln -s /usr/share/logstash /opt/logstash
ENV PATH=/usr/share/logstash/bin:$PATH

# Provide a minimal configuration, so that simple invocations will provide
# a good experience.
ADD config/logstash.yml /usr/share/logstash/config/
ADD config/log4j2.properties /usr/share/logstash/config/

# Ensure Logstash has a UTF-8 locale available.
RUN localedef -c -f UTF-8 -i en_GB en_GB.UTF-8
ENV LANG='en_GB.UTF-8' LC_ALL='en_GB.UTF-8'
ENV JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk
# Provide a non-root user to run the process.
RUN chown --recursive 1000:1000 /usr/share/logstash && \
    groupadd --gid 1000 logstash && \
    useradd --uid=1000 --gid=1000 --home /usr/share/logstash logstash

RUN /opt/logstash/bin/logstash-plugin install logstash-input-beats

USER logstash

ADD pipeline/default.conf /usr/share/logstash/pipeline/logstash.conf

CMD ["logstash", "-f", "/usr/share/logstash/pipeline/"]


