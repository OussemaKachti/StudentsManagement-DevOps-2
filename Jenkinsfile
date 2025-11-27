pipeline {
    agent any

    environment {
        // Définition du nom de l'image (votre_user/nom_repo)
        DOCKER_IMAGE = 'oussema17/students-management'
        // L'ID des credentials qu'on vient de créer dans Jenkins
        DOCKER_CREDS = credentials('dockerhub-credentials')
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

        stage('Docker Build') {
            steps {
                echo '🐳 Building Docker Image...'
                // Construit l'image avec le tag du numéro de build Jenkins (ex: :5)
                sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
                // Ajoute aussi le tag 'latest'
                sh "docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest"
            }
        }

        stage('Docker Push') {
            steps {
                echo '🚀 Pushing Image to DockerHub...'
                // Se connecte à DockerHub en utilisant les variables username/password des credentials
                sh "echo $DOCKER_CREDS_PSW | docker login -u $DOCKER_CREDS_USR --password-stdin"
                
                // Pousse la version spécifique et la version latest
                sh "docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                sh "docker push ${DOCKER_IMAGE}:latest"
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline successful! Image pushed to DockerHub.'
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
        }
        failure {
            echo '❌ Pipeline failed! Check logs.'
        }
        always {
            // Nettoyage pour éviter de saturer le disque du serveur Jenkins
            echo '🧹 Cleaning up Docker images...'
            sh "docker logout"
            // Optionnel : supprimer l'image locale après le push
            // sh "docker rmi ${DOCKER_IMAGE}:${BUILD_NUMBER}"
            // sh "docker rmi ${DOCKER_IMAGE}:latest"
        }
    }
}