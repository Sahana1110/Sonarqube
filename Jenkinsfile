pipeline {
    agent any
    
    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to build')
    }

    environment {
        SONARQUBE = 'SonarQube'                     // Jenkins SonarQube server name
        SONAR_TOKEN = credentials('sonar-token')    // Jenkins Credentials ID
        PROJECT_DIR = 'hello-world-maven/hello-world'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "📦 Checking out branch: ${params.BRANCH_NAME}"
                git branch: "${params.BRANCH_NAME}", url: 'https://github.com/Sahana1110/Sonarqube.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "🔎 Running SonarQube scan..."
                dir("${PROJECT_DIR}") {
                    withSonarQubeEnv("${SONARQUBE}") {
                        sh """
                            mvn clean verify sonar:sonar \\
                            -Dsonar.projectKey=mywebapp \\
                            -Dsonar.token=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo "⏳ Waiting for Quality Gate result..."
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build') {
            steps {
                echo "🔨 Building the Maven project..."
                dir("${PROJECT_DIR}") {
                    sh 'mvn package'
                }
            }
        }

        stage('Archive Artifact') {
            steps {
                echo "📦 Archiving WAR file..."
                dir("${PROJECT_DIR}") {
                    archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully on branch ${params.BRANCH_NAME}"
        }
        failure {
            echo "❌ Pipeline failed during one of the stages"
        }
    }
}
