# Jenkins CI/CD Pipeline with Nexus and SonarQube Integration

## Table of Contents

Prerequisites

Installation Guide

Jenkins Setup

Nexus Repository Setup

SonarQube Setup

Pipeline Configuration

Notification Setup

Troubleshooting



### Prerequisites <a name="prerequisites"></a>

1. AWS EC2 instance (Ubuntu 20.04/22.04 recommended)

2. Security groups configured to allow:

SSH (port 22)

Jenkins web interface (port 8080)

Nexus (port 8081)

SonarQube (port 9000)

Nginx (port 80)

3. Basic Linux command line knowledge

4. GitHub repository with Java/Maven project


### Installation Guide <a name="installation-guide"></a>

Jenkins Setup <a name="jenkins-setup"></a>

Check installation-scripts for Jenkins installation script.

Access Jenkins at http://<EC2_PUBLIC_IP>:8080 and complete the setup wizard.


Nexus Repository Setup <a name="nexus-repository-setup"></a>

Check installation-scripts for Nexus installation script.

Access Nexus at http://<EC2_PUBLIC_IP>:8081. The admin password can be found at:

```bash
    sudo cat /opt/sonatype-work/nexus3/admin.password
```

SonarQube Setup <a name="sonarqube-setup"></a>

Check installation-scripts for SonarQube installation script.

### Pipeline Configuration <a name="pipeline-configuration"></a>

Required Jenkins Plugins

1. Nexus Artifact Uploader

2. SonarQube Scanner

3. Git

4. Pipeline Maven Integration

5. Build Timestamp

6. Pipeline Utility Steps

7. Slack Notification


### Notification Setup <a name="notification-setup"></a>


### Slack Integration

Install the "Slack Notification" plugin in Jenkins

Configure Slack in Jenkins:

1. Go to "Manage Jenkins" → "Configure System"

2. Find "Slack" section

3. Add your Slack workspace URL (e.g., https://your-team.slack.com)

4. Add Slack app credentials (bot token)

5. Test connection and save


### SonarQube Webhook

Access SonarQube at http://<sonar-ip>:9000

Go to Administration → Configuration → Webhooks

Create new webhook:

Name: Jenkins Webhook

URL: http://<jenkins-ip>:8080/sonarqube-webhook/

Save the webhook


Troubleshooting <a name="troubleshooting"></a>

Common Issues

Jenkins not starting:

Check Java version: java -version

Check Jenkins logs: sudo journalctl -u jenkins -f


Nexus not accessible:

Verify service is running: sudo systemctl status nexus

Check firewall rules

Verify admin password exists: sudo cat /opt/sonatype-work/nexus3/admin.password


SonarQube analysis fails:

Check SonarQube logs: sudo journalctl -u sonarqube -f

Verify database connection in sonar.properties

Check memory settings in sonar.properties


Pipeline failures:

Always check "Console Output" in Jenkins for detailed error messages

Verify all required plugins are installed

Check credentials and permissions


Log Locations

Jenkins: /var/log/jenkins/jenkins.log

Nexus: /opt/nexus/sonatype-work/nexus3/log/nexus.log

SonarQube: /opt/sonarqube/logs/

Nginx: /var/log/nginx/



