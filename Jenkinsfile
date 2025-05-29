pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo "Building Maven project..."
                dir('Maven/hello-world-maven/hello-world') {
                    sh 'mvn clean package'
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploying WAR file to Tomcat server..."

                // SCP command with full path in Jenkins workspace
                sh '''
                    scp Maven/hello-world-maven/hello-world/target/hello-world.war ec2-user@65.2.3.46:/opt/tomcat/webapps/
                '''

                // SSH command to restart Tomcat on remote server
                sh '''
                    ssh ec2-user@65.2.3.46 'sudo systemctl restart tomcat'
                '''
            }
        }

        stage('Test') {
            steps {
                echo "Testing deployed application..."

                // Wait for Tomcat to load WAR
                sh 'sleep 15'

                // Curl test URL to confirm deployment success
                sh '''
                    curl --fail http://65.2.3.46:8080/hello-world/index.jsp
                '''
            }
        }
    }

    post {
        success {
            mail to: 'sahanams031@gmail.com',
                 subject: 'SUCCESS: hello-world deployed',
                 body: '''\
Hello,

Your 'hello-world' app has been successfully deployed on Tomcat (172.31.10.50).

Access it here: http://65.2.3.46:8080/hello-world/index.jsp

Regards,
Jenkins
'''
        }

        failure {
            mail to: 'your-email@example.com',
                 subject: 'FAILURE: hello-world deployment',
                 body: '''\
Hello,

Deployment or test failed for 'hello-world' on Tomcat (172.31.10.50).

Please check Jenkins logs.

Regards,
Jenkins
'''
        }
    }
}
