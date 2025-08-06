pipeline {
    agent any
    environment {
        GIT_REPO = 'https://github.com/Sahana1110/Sonarqube.git'
        BRANCH_NAME = 'sahana.developer'
        MAVEN_HOME = '/opt/apache-maven-3.9.6'
        SONARQUBE_URL = 'http://localhost:9000'
        SONARQUBE_AUTH = 'sonartoken'
        SONARQUBE_PROJECT_KEY = 'hello-world'
        ARTIFACT_ID = 'hello-world'
        GROUP_ID = 'com.example'
        VERSION = '1.0-SNAPSHOT'
        NEXUS_SNAPSHOT_REPO = 'http://65.2.127.21:32247/repository/maven-snapshots'
        DOCKER_IMAGE = 'hello-world:latest'
        NEXUS_USERNAME = 'admin'
        NEXUS_PASSWORD = 'sms'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${BRANCH_NAME}", url: "${GIT_REPO}"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    dir('Sonarqube/hello-world-maven/hello-world') {
                        sh "${MAVEN_HOME}/bin/mvn clean verify sonar:sonar -Dsonar.projectKey=${SONARQUBE_PROJECT_KEY} -Dsonar.host.url=${SONARQUBE_URL} -Dsonar.login=${SONARQUBE_AUTH}"
                    }
                }
            }
        }

        stage('Build & Deploy to Nexus') {
            steps {
                dir('Sonarqube/hello-world-maven/hello-world') {
                    sh "${MAVEN_HOME}/bin/mvn deploy"
                }
            }
        }

        stage('Fetch Latest WAR from Nexus') {
            steps {
                script {
                    def metadataUrl = "${NEXUS_SNAPSHOT_REPO}/${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/maven-metadata.xml"
                    echo "Fetching metadata from: ${metadataUrl}"
                    def metadata = sh(script: "curl -s ${metadataUrl}", returnStdout: true).trim()
                    def latestSnapshot = metadata.find(/<value>(.*\.war)<\/value>/) { full, name -> name }
                    if (!latestSnapshot) {
                        error "WAR file not found in Nexus metadata!"
                    }
                    env.WAR_NAME = latestSnapshot
                    echo "Latest WAR: ${env.WAR_NAME}"
                }
            }
        }

        stage('Write Dockerfile') {
            steps {
                writeFile file: 'Dockerfile', text: """
                FROM tomcat:9.0
                ADD ${NEXUS_SNAPSHOT_REPO}/${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/${WAR_NAME} /usr/local/tomcat/webapps/${ARTIFACT_ID}.war
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE} ."
            }
        }

        stage('Push Docker Image to Nexus Docker Registry') {
            steps {
                script {
                    sh "docker tag ${DOCKER_IMAGE} 65.2.127.21:32247/${DOCKER_IMAGE}"
                    sh "docker login 65.2.127.21:32247 -u ${NEXUS_USERNAME} -p ${NEXUS_PASSWORD}"
                    sh "docker push 65.2.127.21:32247/${DOCKER_IMAGE}"
                }
            }
        }
    }
}
