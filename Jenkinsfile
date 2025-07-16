pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Target environment')
    }

    tools {
        maven 'Maven 3'
    }

    environment {
        SONARQUBE = 'SonarQube'
    }

    stages {
        stage('Info') {
            steps {
                echo " Running in environment: ${params.BRANCH_NAME}"
            }
        }

        stage('Build') {
            steps {
                echo " Building Maven project..."
                dir('hello-world-maven/hello-world') {
                    sh 'mvn clean package'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "🔎 Running SonarQube analysis..."
                dir('hello-world-maven/hello-world') {
                    withSonarQubeEnv("${SONARQUBE}") {
                        sh 'mvn sonar:sonar -Dsonar.projectKey=hello-world'
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo "Checking SonarQube quality gate..."
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Deploying WAR file to Tomcat server...'
                sshagent(['tomcat-ec2-key']) {
                    sh 'ssh-keyscan -H 35.154.219.130 >> ~/.ssh/known_hosts'
                    sh 'scp hello-world-maven/hello-world/target/hello-world.war ec2-user@35.154.219.130:/opt/tomcat/webapps/'
                }
            }
        }

        stage('Test') {
            steps {
                echo "🌐 Testing deployed application..."
                sh 'sleep 15'
                sh 'curl --fail http://35.154.219.130:8080/hello-world/index.jsp'
            }
        }
    }

    post {
        success {
            mail to: 'sahanams031@gmail.com',
                 subject: '✅ SUCCESS: hello-world deployed',
                 body: """\
Hello,

Your 'hello-world' app has been successfully deployed on Tomcat (172.31.10.50).

Access it here: http://35.154.219.130:8080/hello-world/index.jsp

Regards,  
Jenkins
"""
        }

        failure {
            mail to: 'sahanams031@gmail.com',
                 subject: '❌ FAILURE: hello-world deployment',
                 body: """\
Hello,

Deployment or test failed for 'hello-world' on Tomcat (172.31.10.50).

Please check Jenkins logs.

Regards,  
Jenkins
"""
        }
    }
}
