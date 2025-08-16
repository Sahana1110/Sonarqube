pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQube'
        SONARQUBE_TOKEN = credentials('sonar-token')
        MAVEN_HOME = tool 'Maven 3'

        NEXUS_URL = 'http://13.235.74.86:30937'
        NEXUS_SNAPSHOT_REPO = "${NEXUS_URL}/repository/maven-snapshots/"
        NEXUS_DOCKER_REGISTRY = '13.235.74.86:30578'

        GROUP_ID = 'com.example'
        ARTIFACT_ID = 'hello-world'
        VERSION = '1.0-SNAPSHOT'
    }

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to build')
    }

    stages {

        stage('Checkout SCM') {
            steps {
                git branch: "${params.BRANCH_NAME}", url: 'https://github.com/Sahana1110/Sonarqube.git'
            }
        }

        stage('SonarQube Scan') {
            steps {
                dir('hello-world-maven/hello-world') {
                    withSonarQubeEnv("${SONARQUBE_SERVER}") {
                        sh """
                        ${MAVEN_HOME}/bin/mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=${ARTIFACT_ID} \
                        -Dsonar.login=${SONARQUBE_TOKEN} \
                        -Dsonar.host.url=http://3.110.224.10:30017
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build & Deploy Artifact to Nexus') {
            steps {
                dir('hello-world-maven/hello-world') {
                    sh """
                    ${MAVEN_HOME}/bin/mvn clean deploy -DskipTests
                    """
                }
            }
        }

        stage('Build Docker Image') {
        steps {
        script {
            def metadataUrl = "${NEXUS_SNAPSHOT_REPO}${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/maven-metadata.xml"
            sh "curl -u admin:sms10 -o maven-metadata.xml ${metadataUrl}"

            // Extract timestamped snapshot version
            def snapshotVersion = sh(script: "grep -oPm1 '(?<=<value>)[^<]+' maven-metadata.xml", returnStdout: true).trim()
            def warFile = "${ARTIFACT_ID}-${snapshotVersion}.war"
            def warUrl = "${NEXUS_SNAPSHOT_REPO}${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/${warFile}"
            def imageTag = "${NEXUS_DOCKER_REGISTRY}/${ARTIFACT_ID}:${BUILD_NUMBER}"

            writeFile file: 'Dockerfile', text: """
            FROM tomcat:9.0
            ADD ${warUrl} /usr/local/tomcat/webapps/${ARTIFACT_ID}.war
            EXPOSE 8080
            CMD ["catalina.sh", "run"]
            """

            sh """
            docker build -t ${imageTag} .
            """
        }
    }
}


        stage('Push Docker Image to Nexus Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds',
                    usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                    docker login ${NEXUS_DOCKER_REGISTRY} -u $NEXUS_USER -p $NEXUS_PASS
                    docker push ${NEXUS_DOCKER_REGISTRY}/${ARTIFACT_ID}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Deploy to ArgoCD') {
    steps {
        withCredentials([usernamePassword(credentialsId: 'argo-cd', usernameVariable: 'ARGO_USER', passwordVariable: 'ARGO_PASS')]) {
            sh """
            argocd login 13.235.74.86:31304 --username $ARGO_USER --password $ARGO_PASS --insecure
            argocd app sync my-k8s-app
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
