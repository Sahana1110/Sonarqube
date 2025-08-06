pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQube'
        SONARQUBE_TOKEN = credentials('sonar-token')
        TOMCAT_KEY = credentials('tomcat-ec2-key')
        MAVEN_HOME = tool 'Maven 3'
        NEXUS_URL = 'http://65.2.127.21:32247'
        NEXUS_SNAPSHOT_REPO = "${NEXUS_URL}/repository/maven-snapshots/"
        GROUP_ID = 'com.example'
        ARTIFACT_ID = 'hello-world'
        VERSION = '1.0-SNAPSHOT'
        WAR_NAME = "${ARTIFACT_ID}-${VERSION}.war"
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

        stage('Build & Deploy Artifact to Nexus') {
            steps {
                dir('hello-world-maven/hello-world') {
                    sh """
                        ${MAVEN_HOME}/bin/mvn deploy -DskipTests -DuniqueVersion=false
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('hello-world-maven/hello-world') {
                    script {
                        def warPath = "${NEXUS_SNAPSHOT_REPO}${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/${WAR_NAME}"
                        def imageTag = "${ARTIFACT_ID}:latest"

                        writeFile file: 'Dockerfile', text: """
                        FROM tomcat:9.0
                        ADD ${warPath} /usr/local/tomcat/webapps/${ARTIFACT_ID}.war
                        EXPOSE 8080
                        CMD ["catalina.sh", "run"]
                        """

                        sh "docker build -t ${imageTag} ."
                    }
                }
            }
        }

        stage('Push Docker Image to Nexus Registry') {
            steps {
                script {
                    def registry = '65.2.127.21:32247'
                    def imageName = "${registry}/${ARTIFACT_ID}:latest"

                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                            docker login ${registry} -u ${NEXUS_USER} -p ${NEXUS_PASS}
                            docker tag ${ARTIFACT_ID}:latest ${imageName}
                            docker push ${imageName}
                        """
                    }
                }
            }
        }

        stage('Deploy to Tomcat EC2') {
            steps {
                script {
                    def warPath = "${NEXUS_SNAPSHOT_REPO}${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/${WAR_NAME}"
                    def serverIP = '65.0.176.83'

                    sh """
                    ssh -o StrictHostKeyChecking=no -i ${TOMCAT_KEY} ec2-user@${serverIP} << EOF
                        wget -O /tmp/${WAR_NAME} ${warPath}
                        sudo mv /tmp/${WAR_NAME} /usr/local/tomcat/webapps/${ARTIFACT_ID}.war
                        sudo systemctl restart tomcat
                    EOF
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
