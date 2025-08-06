pipeline {
    agent any

    environment {
        SONARQUBE = 'sonarqube-server' // name configured in Jenkins global config
        SONAR_TOKEN = credentials('sonar-token') // store token in Jenkins credentials
        NEXUS_URL = "http://65.2.127.21:32247"
        NEXUS_REPO = "maven-snapshots"
        ARTIFACT_ID = "hello-world"
        GROUP_ID = "com.example"
        VERSION = "1.0-SNAPSHOT"
    }

    stages {
        stage('Pull from SCM') {
            steps {
                echo "📥 Cloning source code from GitHub"
                git branch: "${env.BRANCH_NAME}", url: 'https://github.com/Sahana1110/Sonarqube.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "🔍 Running SonarQube scan..."
                withSonarQubeEnv("${SONARQUBE}") {
                    dir('hello-world-maven/hello-world') {
                        sh "mvn clean verify sonar:sonar -Dsonar.projectKey=Sonarqube -Dsonar.token=${SONAR_TOKEN}"
                    }
                }
            }
        }

        stage('Build Artifact') {
            steps {
                echo "🔧 Building WAR file..."
                dir('hello-world-maven/hello-world') {
                    sh "mvn package"
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                echo "📦 Uploading WAR to Nexus..."
                dir('hello-world-maven/hello-world') {
                    sh """
                        mvn deploy:deploy-file \
                        -DgroupId=${GROUP_ID} \
                        -DartifactId=${ARTIFACT_ID} \
                        -Dversion=${VERSION} \
                        -Dpackaging=war \
                        -Dfile=target/${ARTIFACT_ID}-${VERSION}.war \
                        -DrepositoryId=nexus \
                        -Durl=${NEXUS_URL}/repository/${NEXUS_REPO}
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker Image using WAR from Nexus..."
                sh 'docker build -t hello-world:v1 .'
            }
        }

        stage('Push to Nexus Docker Registry') {
            steps {
                echo "📤 Pushing Docker Image to Nexus Docker Registry..."
                sh """
                    docker tag hello-world:v1 65.2.127.21:32247/hello-world:v1
                    docker push 65.2.127.21:32247/hello-world:v1
                """
            }
        }
    }
}
