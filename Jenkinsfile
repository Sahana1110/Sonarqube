pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to build')
    }

    tools {
        maven 'Maven 3'
    }

    environment {
        SONAR_URL = 'http://<your-sonarqube-url>' // Replace if needed
        SONAR_TOKEN = credentials('sonar-token')
        NEXUS_CREDS = credentials('nexus-creds')
        NEXUS_URL = 'http://65.2.127.21:32247'
        GROUP_ID = 'com/example'
        ARTIFACT_ID = 'hello-world'
        VERSION = '1.0-SNAPSHOT'
        WAR_NAME = 'hello-world.war'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: "${params.BRANCH_NAME}", url: 'https://github.com/Sahana1110/Sonarqube.git'
            }
        }

        stage('SonarQube Code Analysis') {
            steps {
                dir('Sonarqube/hello-world-maven/hello-world') {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
    mvn clean verify sonar:sonar \
    -Dsonar.projectKey=hello-world \
    -Dsonar.host.url=http://13.201.228.76:30007 \
    -Dsonar.login=$SONAR_TOKEN
'''

                    }
                }
            }
        }

        stage('Build WAR') {
            steps {
                dir('Sonarqube/hello-world-maven/hello-world') {
                    sh 'mvn clean package'
                }
            }
        }

        stage('Upload WAR to Nexus') {
            steps {
                dir('Sonarqube/hello-world-maven/hello-world') {
                    sh """
                        mvn deploy -DskipTests \
                        -DaltDeploymentRepository=snapshot-repo::default::${NEXUS_URL}/repository/maven-snapshots/ \
                        -Dusername=${NEXUS_CREDS_USR} \
                        -Dpassword=${NEXUS_CREDS_PSW}
                    """
                }
            }
        }

        stage('Create Dockerfile') {
            steps {
                writeFile file: 'Dockerfile', text: """\
FROM tomcat:9.0
ENV WAR_URL=${NEXUS_URL}/repository/maven-snapshots/${GROUP_ID}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.war
ADD \$WAR_URL /usr/local/tomcat/webapps/${ARTIFACT_ID}.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
"""
                sh 'cat Dockerfile'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "${ARTIFACT_ID}:${VERSION}".toLowerCase()
                    sh "docker build -t ${imageName} ."
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                script {
                    def imageName = "${ARTIFACT_ID}:${VERSION}".toLowerCase()
                    def nexusDockerUrl = "${NEXUS_URL}/repository/docker-hosted/"
                    sh """
                        echo "${NEXUS_CREDS_PSW}" | docker login ${NEXUS_URL} -u "${NEXUS_CREDS_USR}" --password-stdin
                        docker tag ${imageName} ${NEXUS_URL}/hello-world:${VERSION}
                        docker push ${NEXUS_URL}/hello-world:${VERSION}
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
