pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to build')
    }

    tools {
        maven 'Maven 3'
    }

    environment {
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
                dir('hello-world-maven/hello-world') {
                    withSonarQubeEnv('SonarQube') {
                        sh 'mvn clean verify sonar:sonar'
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
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USR', passwordVariable: 'NEXUS_PSW')]) {
                        sh """
                            mvn deploy -DskipTests \
                            -DaltDeploymentRepository=snapshot-repo::default::${NEXUS_URL}/repository/maven-snapshots/ \
                            -Dusername=$NEXUS_USR \
                            -Dpassword=$NEXUS_PSW
                        """
                    }
                }
            }
        }

        stage('Create Dockerfile') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USR', passwordVariable: 'NEXUS_PSW')]) {
                    script {
                        def warUrl = "${NEXUS_URL}/repository/maven-snapshots/${GROUP_ID}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.war"
                        writeFile file: 'Dockerfile', text: """\
FROM tomcat:9.0
RUN apt-get update && apt-get install -y wget
ADD ${warUrl} /usr/local/tomcat/webapps/${ARTIFACT_ID}.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
"""
                        sh 'cat Dockerfile'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "${ARTIFACT_ID.toLowerCase()}:${VERSION}"
                    sh "docker build -t ${imageName} ."
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USR', passwordVariable: 'NEXUS_PSW')]) {
                    script {
                        def imageName = "${ARTIFACT_ID.toLowerCase()}:${VERSION}"
                        def fullImage = "65.2.127.21:32247/hello-world:${VERSION}"
                        sh """
                            echo "$NEXUS_PSW" | docker login 65.2.127.21:32247 -u "$NEXUS_USR" --password-stdin
                            docker tag ${imageName} ${fullImage}
                            docker push ${fullImage}
                        """
                    }
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
