pipeline {
    agent any

    environment {
    SONARQUBE_SERVER = 'SonarQube' // name in Jenkins > Configure System > SonarQube server config
    SONARQUBE_TOKEN = credentials('sonar-token') // Jenkins credential id
    NEXUS_CREDS = credentials('nexus-creds') // Nexus username & password
    TOMCAT_KEY = credentials('tomcat-ec2-key') // SSH key
    NEXUS_URL = 'http://65.2.127.21:32247'
    NEXUS_SNAPSHOT_REPO = "${NEXUS_URL}/repository/maven-snapshots/"
    GROUP_ID = 'com.example'
    ARTIFACT_ID = 'hello-world'
    VERSION = '1.0-SNAPSHOT'
    WAR_NAME = "${ARTIFACT_ID}-${VERSION}.war"
    MAVEN_HOME = tool 'Maven 3'
}

parameters {
    string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to build')
}

stages {
    stage('Checkout') {
        steps {
            git branch: "${params.BRANCH_NAME}", url: 'https://github.com/Sahana1110/Sonarqube.git'
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

    stage('Build and Deploy to Nexus') {
        steps {
            dir('hello-world-maven/hello-world') {
                sh """
                    ${MAVEN_HOME}/bin/mvn clean deploy -DaltDeploymentRepository=snapshot-repo::default::${NEXUS_SNAPSHOT_REPO} \
                        -DskipTests \
                        -Dmaven.deploy.username=${NEXUS_CREDS_USR} \
                        -Dmaven.deploy.password=${NEXUS_CREDS_PSW}
                """
            }
        }
    }

    stage('Build Docker Image') {
        steps {
            script {
                def imageTag = "${ARTIFACT_ID}:latest"
                def warDownloadUrl = "${NEXUS_SNAPSHOT_REPO}${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/${WAR_NAME}"

                writeFile file: 'Dockerfile', text: """
                FROM tomcat:9.0
                ADD ${warDownloadUrl} /usr/local/tomcat/webapps/${ARTIFACT_ID}.war
                EXPOSE 8080
                CMD ["catalina.sh", "run"]
                """

                sh "docker build -t ${imageTag} ."
            }
        }
    }

    stage('Push Docker Image to Nexus Registry') {
        steps {
            script {
                def registry = '65.2.127.21:32247'
                def imageName = "${registry}/${ARTIFACT_ID}:latest"

                sh """
                    docker login ${registry} -u ${NEXUS_CREDS_USR} -p ${NEXUS_CREDS_PSW}
                    docker tag ${ARTIFACT_ID}:latest ${imageName}
                    docker push ${imageName}
                """
            }
        }
    }

    stage('Deploy to Tomcat Server') {
        steps {
            script {
                def warUrl = "${NEXUS_SNAPSHOT_REPO}${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/${WAR_NAME}"
                def serverIP = '65.0.176.83' // Update if needed

                sh """
                ssh -o StrictHostKeyChecking=no -i ${TOMCAT_KEY} ec2-user@${serverIP} << EOF
                    wget -O /tmp/${WAR_NAME} ${warUrl}
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
