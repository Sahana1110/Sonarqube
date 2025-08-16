pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQube'               // Jenkins -> Configure System -> SonarQube server name
        SONARQUBE_TOKEN = credentials('sonar-token') // SonarQube token credential
        MAVEN_HOME = tool 'Maven 3'                  // Maven tool configured in Jenkins

        // Nexus URLs
        NEXUS_URL = 'http://13.235.74.86:30937'
        NEXUS_SNAPSHOT_REPO = "${NEXUS_URL}/repository/maven-snapshots/"

        // Artifact details
        GROUP_ID = 'com.example'
        ARTIFACT_ID = 'hello-world'
        VERSION = '1.0-SNAPSHOT'
        WAR_NAME = "${ARTIFACT_ID}-${VERSION}.war"
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
                        sh '''
                            ${MAVEN_HOME}/bin/mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=hello-world \
                            -Dsonar.host.url=http://3.110.224.10:30017 \
                            -Dsonar.login=$SONARQUBE_TOKEN
                        '''
                    }
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build & Deploy Artifact to Nexus') {
            steps {
                dir('hello-world-maven/hello-world') {
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh '''
                            ${MAVEN_HOME}/bin/mvn clean deploy \
                            -DaltDeploymentRepository=snapshot-repo::default::http://13.235.74.86:30937/repository/maven-snapshots/ \
                            -DskipTests \
                            -Dmaven.deploy.username=$NEXUS_USER \
                            -Dmaven.deploy.password=$NEXUS_PASS
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('hello-world-maven/hello-world') {
                    script {
                        def warUrl = "${NEXUS_SNAPSHOT_REPO}${GROUP_ID.replace('.', '/')}/${ARTIFACT_ID}/${VERSION}/${WAR_NAME}"
                        def imageTag = "${ARTIFACT_ID}:${env.BUILD_NUMBER}"

                        writeFile file: 'Dockerfile', text: """
                        FROM tomcat:9.0
                        ADD ${warUrl} /usr/local/tomcat/webapps/${ARTIFACT_ID}.war
                        EXPOSE 8080
                        CMD ["catalina.sh", "run"]
                        """

                        sh "docker build -t ${imageTag} ."
                        env.IMAGE_TAG = imageTag
                    }
                }
            }
        }

        stage('Push Docker Image to Nexus Registry') {
            steps {
                script {
                    def registry = '13.235.74.86:30578'   // Nexus Docker registry NodePort
                    def imageName = "${registry}/${ARTIFACT_ID}:${env.BUILD_NUMBER}"

                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                            docker login ${registry} -u $NEXUS_USER -p $NEXUS_PASS
                            docker tag ${ARTIFACT_ID}:${env.BUILD_NUMBER} ${imageName}
                            docker push ${imageName}
                        """
                    }
                    env.FINAL_IMAGE = imageName
                }
            }
        }

        stage('Deploy via ArgoCD') {
            steps {
                script {
                    // Assumes ArgoCD is already configured in Jenkins
                    def appName = "hello-world-app"
                    def argoServer = "http://13.235.74.86:31304"

                    sh """
                        argocd login ${argoServer} --username admin --password YOUR_ARGO_PASS --insecure
                        argocd app create ${appName} \
                          --repo https://github.com/Sahana1110/Sonarqube.git \
                          --path k8s-manifests \
                          --dest-server https://kubernetes.default.svc \
                          --dest-namespace default \
                          --sync-policy automated \
                          --self-heal \
                          --upsert
                        
                        argocd app set ${appName} --parameter image.tag=${env.BUILD_NUMBER}
                        argocd app sync ${appName}
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
