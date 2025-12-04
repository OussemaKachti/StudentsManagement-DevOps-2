pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'oussema17/students-management'
        DOCKER_CREDS = credentials('dockerhub-credentials')
        NEXUS_CREDS = credentials('nexus-credentials')
        NEXUS_USER = "${NEXUS_CREDS_USR}"
        NEXUS_PASS = "${NEXUS_CREDS_PSW}"
    }

    triggers {
        githubPush()
    }

    tools {
        maven 'M2_HOME'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📥 Fetching code from GitHub...'
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: 'main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/OussemaKachti/StudentsManagement-DevOps-2.git',
                        credentialsId: 'github-credentials'
                    ]]
                ])
            }
        }

        stage('Build') {
            steps {
                echo '🔨 Compiling project...'
                sh 'mvn clean compile'
            }
        }

        stage('Test') {
            steps {
                echo '🧪 Running unit tests...'
                sh 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                    jacoco execPattern: '**/target/jacoco.exec'
                }
            }
        }

        stage('Package') {
            steps {
                echo '📦 Packaging JAR...'
                sh 'mvn package -DskipTests'
            }
        }

        stage('Deploy to Nexus') {
            steps {
                echo '📤 Deploying artifacts to Nexus...'
                sh 'mvn deploy -DskipTests -s maven-settings.xml'
            }
        }

        stage('Docker Build') {
            steps {
                echo '🐳 Building Docker Image...'
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
                    sh "docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Docker Push') {
            steps {
                echo '🚀 Pushing Image to DockerHub...'
                script {
                    sh "echo \$DOCKER_CREDS_PSW | docker login -u \$DOCKER_CREDS_USR --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo '🧹 Cleaning up...'
                sh 'docker logout'
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline successful! Artifacts deployed to Nexus and Docker image pushed.'
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
        }
        failure {
            echo '❌ Pipeline failed! Check logs.'
        }
    }
}