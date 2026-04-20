FROM docker.io/library/maven:3.9-eclipse-temurin-17 AS builder
ADD https://github.com/gbif/ipt/archive/7996efeec2fd8dbe1145c72f8d41e11a458c2ed5.tar.gz /src.tar.gz
RUN mkdir /build && tar xzf /src.tar.gz --strip-components=1 -C /build
WORKDIR /build
RUN --mount=type=cache,target=/root/.m2 mvn package -DskipTests -q

# --- from upstream ---
FROM docker.io/library/tomcat:11.0.20-jdk17-temurin

ENV IPT_DATA_DIR=/srv/ipt
ENV TOMCAT_GROUP=tomcat
ENV TOMCAT_USER=tomcat

RUN groupadd -r $TOMCAT_GROUP && useradd -r -g $TOMCAT_GROUP -m $TOMCAT_USER && \
    chown -R $TOMCAT_GROUP:$TOMCAT_USER /usr/local/tomcat && \
    chmod -R 755 /usr/local/tomcat && \
    mkdir -p $IPT_DATA_DIR && \
    chown -R $TOMCAT_GROUP:$TOMCAT_USER $IPT_DATA_DIR

RUN sed -i 's/maxParameterCount="1000"/maxParameterCount="10000"/g' /usr/local/tomcat/conf/server.xml
# --- end upstream ---

# --- NINA customizations ---
ADD ca-certificates /usr/local/share/ca-certificates/
RUN update-ca-certificates && \
    for f in /usr/local/share/ca-certificates/*.crt; do \
        keytool -import -noprompt -trustcacerts -storepass changeit \
            -keystore /opt/java/openjdk/lib/security/cacerts \
            -alias "$(basename $f .crt)" \
            -file "$f"; \
    done

COPY --from=builder --chown=$TOMCAT_GROUP:$TOMCAT_USER /build/target/ipt-*/ /usr/local/tomcat/webapps/ROOT/
COPY ROOT /usr/local/tomcat/webapps/ROOT

# --- from upstream ---
VOLUME $IPT_DATA_DIR
EXPOSE 8080
# --- end upstream ---

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
