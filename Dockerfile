# Dockerfile

# Use Tomcat base image
FROM tomcat:9.0

# Set environment variables
ENV APP_NAME=hello-world
ENV WAR_VERSION=1.0-SNAPSHOT
ENV NEXUS_BASE_URL=http://65.2.127.21:32247/repository
ENV ARTIFACT_PATH=maven-snapshots/com/example/${APP_NAME}/${WAR_VERSION}
ENV WAR_NAME=${APP_NAME}-${WAR_VERSION}.war

# Download WAR from Nexus
ADD ${NEXUS_BASE_URL}/${ARTIFACT_PATH}/${WAR_NAME} /usr/local/tomcat/webapps/${APP_NAME}.war

# Expose default port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]

