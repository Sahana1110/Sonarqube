pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to build')
    }

    tools {
        maven 'Maven 3'
    }

    environment {
        SONARQUBE = 'SonarQube'                     // Name from Jenkins Sonar config
        SONAR_TOKEN = credentials('sonar-token')    // Secret text credential ID
    }

    stages {
        stage('Checkout') {
            steps {
                echo "📦 Checking out branch: ${params.BRANCH_NAME}"
                git url: 'https://github.com/Sahana1110/mywebapp.git', branch: "${params.BRANCH_NAME}"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "🔎 Running SonarQube Scan"
                withSonarQubeEnv("${SONARQUBE}") {
                    sh """
                        mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=mywebapp \
                        -Dsonar.token=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo "⏳ Waiting for Quality Gate result"
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build & Package') {
            steps {
                echo "🔨 Building project"
                sh 'mvn package'
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo "📁 Archiving build output"
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: Build and scan completed for ${params.BRANCH_NAME}"
        }
        failure {
            echo "❌ FAILED: Something went wrong in pipeline"
        }
    }
}
