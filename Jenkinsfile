pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQube'
        SONARQUBE_TOKEN = credentials('sonar-token')
        TOMCAT_KEY = credentials('tomcat-ec2-key')
        MAVEN_HOME = tool 'Maven 3'

        NEXUS_URL = 'http://65.2.127.21:30937'
        NEXUS_SNAPSHOT_REPO = "${NEXUS_URL}/repository/maven-snapshots"
        NEXUS_DOCKER_REGISTRY = '65.2.127.21:30578'

        GROUP_ID = 'com.example'
        ARTIFACT_ID = 'hello-world'
        VERSION = '1.0-SNAPSHOT'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git branch: 'dev', url: 'https://github.com/Sahana1110/Sonarqube.git'
            }
        }

        stage('SonarQube Scan') {
            steps {
                dir('hello-world-maven/hello-world') {
                    withSonarQubeEnv("${SONARQUBE_SERVER}") {
                        sh "${MAVEN_HOME}/bin/mvn clean verify sonar:sonar -Dsonar.login=${SONARQUBE_TOKEN}"
                    }
                }
            }
        }

        stage('Build & Upload to Nexus') {
            steps {
                dir('hello-world-maven/hello-world') {
                    sh "${MAVEN_HOME}/bin/mvn deploy -DskipTests -DuniqueVersion=true"
                }
            }
        }

        stage('Extract WAR from Nexus') {
            steps {
                script {
                    def metadataUrl = "${NEXUS_SNAPSHOT_REPO}/${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/maven-metadata.xml"
                    def metadata = sh(script: "curl -s ${metadataUrl}", returnStdout: true).trim()

                    def timestamp = metadata.find(/<timestamp>(.*?)<\/timestamp>/) { _, ts -> ts }
                    def buildNumber = metadata.find(/<buildNumber>(.*?)<\/buildNumber>/) { _, bn -> bn }

                    if (!timestamp || !buildNumber) {
                        error "Could not extract timestamp/buildNumber from metadata!"
                    }

                    def versionResolved = "${VERSION.replace('-SNAPSHOT', '')}-${timestamp}-${buildNumber}"
                    def warName = "${ARTIFACT_ID}-${versionResolved}.war"
                    env.WAR_NAME = warName

                    echo "Resolved WAR: ${env.WAR_NAME}"
                }
            }
        }

        stage('Download WAR from Nexus') {
            steps {
                dir('hello-world-maven/hello-world') {
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                            curl -u $NEXUS_USER:$NEXUS_PASS -O ${NEXUS_SNAPSHOT_REPO}/${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/${env.WAR_NAME}
                            mv ${env.WAR_NAME} ${ARTIFACT_ID}.war
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('hello-world-maven/hello-world') {
                    script {
                        writeFile file: 'Dockerfile', text: """
                        FROM tomcat:9.0
                        COPY ${ARTIFACT_ID}.war /usr/local/tomcat/webapps/${ARTIFACT_ID}.war
                        EXPOSE 8080
                        CMD ["catalina.sh", "run"]
                        """

                        sh "docker build -t ${ARTIFACT_ID}:latest ."
                    }
                }
            }
        }

        stage('Push Docker Image to Nexus Registry') {
            steps {
                script {
                    def fullImage = "${NEXUS_DOCKER_REGISTRY}/${ARTIFACT_ID}:latest"

                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                            echo \$NEXUS_PASS | docker login ${NEXUS_DOCKER_REGISTRY} -u \$NEXUS_USER --password-stdin
                            docker tag ${ARTIFACT_ID}:latest ${fullImage}
                            docker push ${fullImage}
                        """
                    }

                    echo "✅ Docker image pushed: ${fullImage}"
                }
            }
        }

        stage('Deploy to Tomcat EC2') {
        steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'tomcat-ec2-key', keyFileVariable: 'TOMCAT_KEY')]) {
            script {
                def tomcatIP = '15.206.164.80'
                def warURL = "http://65.2.127.21:30937/repository/maven-snapshots/com/example/hello-world/1.0-SNAPSHOT/${env.WAR_NAME}"

                sh """
                ssh -o StrictHostKeyChecking=no -i \$TOMCAT_KEY ec2-user@${tomcatIP} '
                    wget -O /tmp/${env.WAR_NAME} ${warURL}
                    sudo mv /tmp/${env.WAR_NAME} /usr/local/tomcat/webapps/hello-world.war
                    sudo systemctl restart tomcat
                '
                """
            }
        }
    }
}


    post {
        always {
            cleanWs()
        }
    }
}
