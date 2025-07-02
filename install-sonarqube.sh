#!/bin/bash

# Update packages and install dependencies
sudo yum update -y
sudo yum install wget unzip java-17-openjdk-devel -y

# Create SonarQube user
sudo useradd sonar

# Download and extract SonarQube
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.3.0.82913.zip
sudo unzip sonarqube-10.3.0.82913.zip
sudo mv sonarqube-10.3.0.82913 sonarqube
sudo chown -R sonar:sonar /opt/sonarqube

# Start SonarQube
sudo su - sonar -c "/opt/sonarqube/bin/linux-x86-64/sonar.sh start"

# Optional: Show logs for confirmation
echo "Wait a few seconds and then run the following to check logs:"
echo "tail -f /opt/sonarqube/logs/sonar.log"
