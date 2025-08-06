pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonar-token')
        NEXUS_CREDENTIALS = credentials('nexus-creds')
        SONARQUBE = 'SONARQUBE'
        PROJECT_DIR = 'hello-world-maven/hello-world'
        ARTIFACT_ID = 'hello-world'
        VERSION = '1.0-SNAPSHOT'
        GROUP_ID = 'com.example'
        DOCKER_IMAGE = "65.2.127.21:32247/${ARTIFACT_ID}:${VERSION}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📥 Checking out code..."
                checkout scm
            }
        }

        stage('Build & Package WAR') {
            steps {
                echo "⚙️ Building the Maven project..."
                dir("${PROJECT_DIR}") {
                    sh "mvn clean package -DskipTests"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "🔎 Running SonarQube scan..."
                withSonarQubeEnv("${SONARQUBE}") {
                    dir("${PROJECT_DIR}") {
                        sh """
                            mvn clean verify sonar:sonar \
                              -Dsonar.projectKey=${ARTIFACT_ID} \
                              -Dsonar.token=$SONAR_TOKEN
                        """
                    }
                }
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                echo "📦 Uploading WAR to Nexus..."
                dir("${PROJECT_DIR}") {
                    sh """
                        mvn deploy \
                          -DaltDeploymentRepository=nexus::default::http://65.2.127.21:32247/repository/maven-snapshots/ \
                          -DskipTests
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh "docker build -t ${DOCKER_IMAGE} ."
            }
        }

        stage('Push Docker Image to Nexus Docker Registry') {
            steps {
                echo "🚀 Pushing Docker image to Nexus..."
                sh """
                    echo "${NEXUS_CREDENTIALS_PSW}" | docker login 65.2.127.21:32247 --username ${NEXUS_CREDENTIALS_USR} --password-stdin
                    docker push ${DOCKER_IMAGE}
                """
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed."
        }
    }
}
