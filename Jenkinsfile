pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to build')
    }

    tools {
        maven 'Maven 3'
    }

    environment {
        SONARQUBE = 'SonarQube' // Jenkins SonarQube server config name
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
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh 'mvn clean verify sonar:sonar -Dsonar.proj
