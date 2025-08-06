pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to build')
    }

    tools {
        maven 'Maven 3' // Make sure this matches the name in Jenkins -> Global Tool Configuration
    }

    environment {
        SONARQUBE = 'SonarQube' // Jenkins SonarQube server config name
        SONAR_TOKEN = credentials('sonar-token') // Add your token in Jenkins credentials
        NEXUS_CREDS = credentials('nexus-creds') // Replace with Jenkins ID for Nexus user:pass
        NEXUS_URL = "http://65.2.127.21:32247/repository/maven-snapshots"
        NEXUS_DOCKER_REPO = "65.2.127.21:32247"
        IMAGE_NAME = "sonarqube-app"
        REPO_NAME = "Sonarqube"
        PROJECT_PATH = "hello-world-maven/hello-world"
    }

    stages {
        stage('SCM Checkout') {
            steps {
                echo "📥 Cloning branch: ${params.BRANCH_NAME}"
                git branch: "${params.BRANCH_NAME}", url: 'https://github.com/Sahana1110/Sonarqube.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "🔍 Running SonarQube analysis..."
                dir("${PROJECT_PATH}") {
                    withSonarQubeEnv("${SONARQUBE}") {
                        sh """
                            mvn clean verify sonar:sonar \
                                -Dsonar.projectKey=sonarqube-app \
                                -Dsonar.login=$SONAR_TOKEN
                        """
                    }
                }
            }
        }

        stage('Build WAR Artifact') {
            steps {
                echo "🏗 Building WAR file..."
                dir("${PROJECT_PATH}") {
                    sh 'mvn clean package'
                }
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                echo "📦 Uploading WAR to Nexus..."
                dir("${PROJECT_PATH}") {
                    sh """
                        mvn deploy -DaltDeploymentRepository=nexus::default::${NEXUS_URL} \
                            -DskipTests \
                            -Dusername=${NEXUS_CREDS_USR} \
                            -Dpassword=${NEXUS_CREDS_PSW}
                    """
                }
            }
        }

        stage('Build Docker Image from Nexus WAR') {
            steps {
                echo "🐳 Building Docker image using WAR from Nexus..."
                sh """
                    docker build -t ${IMAGE_NAME}:latest .
                """
            }
        }

        stage('Push Docker Image to Nexus Registry') {
            steps {
                echo "📤 Pushing Docker image to Nexus Docker Registry..."
                sh """
                    echo ${NEXUS_CREDS_PSW} | docker login ${NEXUS_DOCKER_REPO} -u ${NEXUS_CREDS_USR} --password-stdin
                    docker tag ${IMAGE_NAME}:latest ${NEXUS_DOCKER_REPO}/${IMAGE_NAME}:latest
                    docker push ${NEXUS_DOCKER_REPO}/${IMAGE_NAME}:latest
                """
            }
        }
    }
}
