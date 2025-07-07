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

