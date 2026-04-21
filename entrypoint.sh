#!/bin/sh -x
if [ "$(stat -c %u /srv/ipt 2>/dev/null)" = "0" ]
then
  chown -R tomcat:tomcat /srv/ipt
fi
exec su -s /bin/sh tomcat -c "PATH=$PATH catalina.sh run"
