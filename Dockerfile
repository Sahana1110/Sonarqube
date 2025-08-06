# Base image
FROM tomcat:9.0

# Environment variables (set version and Nexus info)
ENV APP_NAME=hello-world
ENV WAR_VERSION=1.0-SNAPSHOT
ENV NEXUS_URL=http://65.2.127.21:32247/repository/maven-snapshots/com/example/hello-world
ENV WAR_FILE=${APP_NAME}-${WAR_VERSION}.war

# Download the WAR file from Nexus
ADD ${NEXUS_URL}/${WAR_VERSION}/${WAR_FILE} /usr/local/tomcat/webapps/${APP_NAME}.war

# Expose port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
