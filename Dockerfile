FROM tomcat:9.0

# Clean default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR from Nexus and rename to ROOT.war so it auto-deploys
ADD http://admin:sms@65.2.127.21:32247/repository/maven-snapshots/com/example/hello-world/1.0-SNAPSHOT/hello-world-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
