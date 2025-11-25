pipeline {
    agent any

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
                    junit '**/target/surefire-reports/*.xml'
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
    }

    post {
        success {
            echo '✅ Build successful!'
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
        }
        failure {
            echo '❌ Build failed! Check logs.'
        }
    }
}