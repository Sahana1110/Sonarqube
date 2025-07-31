pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to build')
    }

    tools {
        maven 'Maven 3'
    }

    environment {
        SONARQUBE = 'SonarQube'
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
                withSonarQubeEnv("${SONARQUBE}") {
                    sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=hello-world'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo "🛡️ Waiting for Quality Gate..."
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build') {
            steps {
                echo "🔨 Building the Maven project..."
                sh 'mvn package'
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: Code scanned and built on branch ${params.BRANCH_NAME}"
        }
        failure {
            echo "❌ FAILURE: Issue in scan or build"
        }
    }
}
