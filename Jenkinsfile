pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQube'                       // Jenkins -> SonarQube server config name
        SONARQUBE_TOKEN  = credentials('sonar-token')        // Jenkins credential for SonarQube
        MAVEN_HOME       = tool 'Maven 3'                    // Maven tool in Jenkins
        NEXUS_URL        = 'http://13.235.74.86:30937'
        NEXUS_SNAPSHOT_REPO = "${NEXUS_URL}/repository/maven-snapshots/"
        GROUP_ID         = 'com.example'
        ARTIFACT_ID      = 'hello-world'
        VERSION          = '1.0-SNAPSHOT'
        WAR_NAME         = "${ARTIFACT_ID}-${VERSION}.war"
    }

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Branch to build')
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git branch: "${params.BRANCH_NAME}", url: 'https://github.com/Sahana1110/Sonarqube.git'
            }
        }

        stage('SonarQube Scan') {
            steps {
                dir('Sonarqube/hello-world-maven/hello-world') {
                    withSonarQubeEnv("${SONARQUBE_SERVER}") {
                        sh """
                        ${MAVEN_HOME}/bin/mvn clean verify sonar:sonar \
                        -Dsonar.login=${SONARQUBE_TOKEN} \
                        -Dsonar.host.url=http://3.110.224.10:30017
                        """
                    }
                }
            }
        }

        stage('Build & Deploy Artifact to Nexus') {
            steps {
                dir('Sonarqube/hello-world-maven/hello-world') {
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds',
                                                      usernameVariable: 'NEXUS_USER',
                                                      passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                        ${MAVEN_HOME}/bin/mvn clean deploy \
                        -DaltDeploymentRepository=snapshot-repo::default::${NEXUS_SNAPSHOT_REPO} \
                        -DskipTests \
                        -Dmaven.deploy.username=${NEXUS_USER} \
                        -Dmaven.deploy.password=${NEXUS_PASS}
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('Sonarqube/hello-world-maven/hello-world') {
                    script {
                        def warUrl   = "${NEXUS_SNAPSHOT_REPO}${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/${WAR_NAME}"
                        def imageTag = "${ARTIFACT_ID}:${env.BUILD_NUMBER}"

                        writeFile file: 'Dockerfile', text: """
                        FROM tomcat:9.0
                        ADD ${warUrl} /usr/local/tomcat/webapps/${ARTIFACT_ID}.war
                        EXPOSE 8080
                        CMD ["catalina.sh", "run"]
                        """

                        sh "docker build -t ${imageTag} ."
                        sh "docker tag ${imageTag} 13.235.74.86:30578/${imageTag}"
                    }
                }
            }
        }

        stage('Push Docker Image to Nexus Registry') {
            steps {
                script {
                    def registry  = '13.235.74.86:30578'
                    def imageName = "${registry}/${ARTIFACT_ID}:${env.BUILD_NUMBER}"

                    withCredentials([usernamePassword(credentialsId: 'nexus-creds',
                                                      usernameVariable: 'NEXUS_USER',
                                                      passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                        docker login ${registry} -u ${NEXUS_USER} -p ${NEXUS_PASS}
                        docker push ${imageName}
                        """
                    }
                }
            }
        }

        stage('Deploy to ArgoCD') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'argo-cd',
                                                  usernameVariable: 'ARGO_USER',
                                                  passwordVariable: 'ARGO_PASS')]) {
                    sh """
                    argocd login 13.235.74.86:31304 --username ${ARGO_USER} --password ${ARGO_PASS} --insecure
                    argocd app set myapp --revision ${env.BUILD_NUMBER}
                    argocd app sync myapp
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
