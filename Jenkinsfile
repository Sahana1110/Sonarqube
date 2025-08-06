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
        SONAR_TOKEN = credentials('sonar-token')  // Jenkins credentials
        TOMCAT_USER = 'ec2-user'
        TOMCAT_HOST = '15.206.164.80' // Replace with your Tomcat EC2 public IP
        TOMCAT_WEBAPPS = '/opt/tomcat/webapps'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "📦 Checking out branch: ${params.BRANCH_NAME}"
                git branch: "${params.BRANCH_NAME}", url: 'https://github.com/Sahana1110/mywebapp.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "🔎 Running SonarQube scan..."
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
                echo "🛡️ Waiting for Quality Gate..."
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build WAR') {
            steps {
                echo "🔨 Building the WAR file..."
                sh 'mvn clean package'
                archiveArtifacts artifacts: 'target/*.war', fingerprint: true
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                echo "🚀 Deploying to remote Tomcat server..."
                sh """
                    scp -i ~/.ssh/id_rsa target/*.war ${TOMCAT_USER}@${TOMCAT_HOST}:${TOMCAT_WEBAPPS}/hello-world.war
                    ssh -i ~/.ssh/id_rsa ${TOMCAT_USER}@${TOMCAT_HOST} 'sudo systemctl restart tomcat'
                """
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
