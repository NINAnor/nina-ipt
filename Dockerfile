FROM docker.io/gbif/ipt:2.7.6

ADD ca-certificates /usr/local/share/ca-certificates/
RUN update-ca-certificates && \
    for f in /usr/local/share/ca-certificates/*.crt; do \
        keytool -import -noprompt -trustcacerts -storepass changeit \
            -keystore /opt/java/openjdk/jre/lib/security/cacerts \
            -alias "$(basename $f .crt)" \
            -file "$f"; \
    done

COPY ROOT /usr/local/tomcat/webapps/ROOT
