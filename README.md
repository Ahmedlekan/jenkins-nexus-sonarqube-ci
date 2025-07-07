# Jenkins CI Pipeline with Nexus and SonarQube Integration

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Complete infrastructure-as-code solution for setting up a Jenkins CI/CD pipeline with Nexus artifact repository and SonarQube code quality analysis.

```mermaid
graph LR
    subgraph Developer Environment
        A[Developer Laptop] -->|git push| B[GitHub]
    end

    subgraph AWS Cloud
        B --> C[Jenkins Server\non EC2]
        C --> D[Build]
        D --> E[Unit Tests]
        E --> F{Quality Gate}
        F -->|Pass| G[Nexus OSS\nArtifact Repository]
        F -->|Fail| H[Slack/Email Alert]
        G --> I[Deployment Targets]
        
        C --> J[SonarQube\nAnalysis]
        J --> F
    end

    style A fill:#4CAF50,stroke:#388E3C
    style B fill:#24292e,stroke:#000000
    style C fill:#F6D55C,stroke:#ED553B
    style D fill:#2196F3,stroke:#0D47A1
    style E fill:#2196F3,stroke:#0D47A1
    style F fill:#9C27B0,stroke:#7B1FA2
    style G fill:#607D8B,stroke:#455A64
    style H fill:#F44336,stroke:#D32F2F
    style I fill:#4CAF50,stroke:#388E3C
    style J fill:#84C1FF,stroke:#4285F4
```

## Quick Start

```bash
# Clone repository
git clone https://github.com/Ahmedlekan/jenkins-nexus-sonarqube-ci.git
cd jenkins-nexus-sonarqube-ci

# Run installation scripts
chmod +x installation-scripts/*
./installation-scripts/install_jenkins.sh
./installation-scripts/install_nexus.sh
./installation-scripts/install_sonarqube.sh
```

## Architecture

<img width="1280" height="737" alt="Image" src="https://github.com/user-attachments/assets/adf46a2a-7a95-443f-b35a-6cca5ced91f2" />

## Prerequisites

1. AWS EC2 instance (Ubuntu 20.04/22.04 recommended)

2. Security groups configured to allow:

SSH (port 22)

Jenkins web interface (port 8080)

<img width="1863" height="607" alt="Image" src="https://github.com/user-attachments/assets/e34bf94d-af5a-4b5b-988b-d3eafb3eee06" />

Nexus (port 8081)

<img width="1874" height="645" alt="Image" src="https://github.com/user-attachments/assets/e3790c6b-d811-4c19-b630-576836075aeb" />

SonarQube (port 9000)

<img width="1873" height="645" alt="Image" src="https://github.com/user-attachments/assets/debe5634-26a3-463a-8c8b-7436c2888a2d" />

3. Basic Linux command line knowledge

4. GitHub repository with Java/Maven project


## Installation

See detailed installation instructions in:

- [Jenkins Setup](installation-scripts/install_jenkins.sh)

Access Jenkins at http://<EC2_PUBLIC_IP>:8080 and complete the setup wizard. The password can be found at

```bash
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

- [Nexus Setup](installation-scripts/install_nexus.sh)

Access Nexus at http://<EC2_PUBLIC_IP>:8081. The admin password can be found at:

```bash
    sudo cat /opt/sonatype-work/nexus3/admin.password
```

- [SonarQube Setup](installation-scripts/install_sonarqube.sh)


## Required Jenkins Plugins

1. Nexus Artifact Uploader

2. SonarQube Scanner

3. Git

4. Pipeline Maven Integration

5. Build Timestamp

6. Pipeline Utility Steps

7. Slack Notification


### Slack Integration

Install the "Slack Notification" plugin in Jenkins

Configure Slack in Jenkins:

1. Go to "Manage Jenkins" → "Configure System"

2. Find "Slack" section

3. Add your Slack workspace URL (e.g., https://your-team.slack.com)

4. Add Slack app credentials (bot token)

5. Test connection and save


### SonarQube Webhook

<img width="669" height="712" alt="Image" src="https://github.com/user-attachments/assets/654a3c2e-762e-4917-abf1-ba0e9da08735" />

Go to Administration → Configuration → Webhooks

Create new webhook:

Name: Jenkins Webhook

URL: http://<jenkins-ip>:8080/sonarqube-webhook/

Save the webhook


## Pipeline Features

✔️ Automatic code checkout  

✔️ Maven build and testing  

✔️ SonarQube code analysis  

✔️ Nexus artifact storage  

✔️ Slack notifications  

✔️ Quality gating  

```bash
def COLOR_MAP = [
    "SUCCESS": 'good',
    "FAILURE": 'danger',
    "UNSTABLE": 'warning',
    "ABORTED": 'warning'
]

pipeline {
    agent any

    tools {
        maven "MAVEN3"
        jdk "JDK17"
    }

    environment {
        SCANNER_HOME = tool 'SONAR_SCANNER'
        PROJECT_VERSION = "1.0.${env.BUILD_NUMBER}"
        PROJECT_NAME = "vprofile"
        NEXUS_URL = 'nexus.example.com:8081'
        NEXUS_CREDENTIALS = credentials('nexus-credentials')
    }

    stages {
        stage('Fetch Code') {
            steps {
                git branch: 'main', 
                   url: 'https://github.com/your-repo/your-project.git',
                   credentialsId: 'github-credentials'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean install -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: '**/target/*.war', 
                                    fingerprint: true
                }
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Code Quality Analysis') {
            steps {
                script {
                    withSonarQubeEnv('sonar-server') {
                        sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=${PROJECT_NAME} \
                        -Dsonar.projectName=${PROJECT_NAME} \
                        -Dsonar.projectVersion=${PROJECT_VERSION} \
                        -Dsonar.sources=src/ \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.junit.reportsPath=target/surefire-reports \
                        -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                        -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Deploy to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: NEXUS_URL,
                    groupId: 'com.example',
                    version: "${PROJECT_VERSION}",
                    repository: 'maven-releases',
                    credentialsId: NEXUS_CREDENTIALS,
                    artifacts: [
                        [artifactId: PROJECT_NAME,
                         classifier: '',
                         file: "target/${PROJECT_NAME}.war",
                         type: 'war']
                    ]
                )
            }
        }
    }

    post {
        always {
            script {
                def duration = currentBuild.durationString.replace(' and counting', '')
                def message = """
                *${currentBuild.currentResult}:* Job ${env.JOB_NAME} #${env.BUILD_NUMBER}
                *Duration:* ${duration}
                *Build URL:* ${env.BUILD_URL}
                """.stripIndent()

                slackSend(
                    channel: '#devops-notifications',
                    color: COLOR_MAP[currentBuild.currentResult],
                    message: message
                )
            }
        }
    }
}
```

## Troubleshooting

### Common Issues

Jenkins not starting:

Check Java version: java -version

Check Jenkins logs: sudo journalctl -u jenkins -f


### Nexus not accessible:

Verify service is running: sudo systemctl status nexus

Check firewall rules

Verify admin password exists: sudo cat /opt/sonatype-work/nexus3/admin.password


### SonarQube analysis fails:

Check SonarQube logs: sudo journalctl -u sonarqube -f

Verify database connection in sonar.properties

Check memory settings in sonar.properties


### Pipeline failures:

Always check "Console Output" in Jenkins for detailed error messages

Verify all required plugins are installed

Check credentials and permissions


### Log Locations

Jenkins: /var/log/jenkins/jenkins.log

Nexus: /opt/nexus/sonatype-work/nexus3/log/nexus.log

SonarQube: /opt/sonarqube/logs/


