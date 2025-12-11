pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'oussema17/students-management'
        NAMESPACE = "devops"
    }

    triggers {
        githubPush()
    }

    tools {
        maven 'M2_HOME'
    }

    stages {

        stage('1. Checkout') {
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

        stage('2. Cleanup') {
            steps {
                echo '🧹 Cleaning environment...'
                sh '''
                    docker system prune -f || true
                    rm -rf target/ || true
                '''
            }
        }

        stage('3. Project Check') {
            steps {
                echo '🔍 Checking project structure...'
                sh '''
                    echo "=== Project root ==="
                    ls -la

                    echo ""
                    echo "=== Kubernetes files ==="
                    ls -la k8s/
                '''
            }
        }

        stage('4. Maven Build') {
            steps {
                echo '🔨 Compiling project...'
                sh 'mvn clean compile'
            }
        }

        stage('5. Unit Tests') {
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

        stage('6. Package JAR') {
            steps {
                echo '📦 Packaging JAR...'
                sh 'mvn package -DskipTests'
            }
        }

        stage('7. Deploy to Nexus') {
            steps {
                echo '📤 Deploying artifacts to Nexus...'
                sh 'mvn deploy -DskipTests -Djacoco.skip=true -s maven-settings.xml'
            }
        }

        stage('8. Build Docker Image') {
            steps {
                echo '🐳 Building Docker Image...'
                sh """
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest

                    echo ""
                    echo "=== Docker images ==="
                    docker images | grep ${DOCKER_IMAGE}
                """
            }
        }

        stage('9. Push Docker Image') {
            steps {
                echo '📤 Publishing image to Docker Hub...'
                withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE}:latest
                        docker logout
                        echo "✓ Images pushed to Docker Hub"
                    """
                }
            }
        }

        stage('10. Kubernetes Deployment') {
            steps {
                echo '☸️ Deploying to Kubernetes...'
                sh """
                    echo "=== Checking cluster ==="
                    kubectl get nodes

                    echo ""
                    echo "=== Deploy MySQL ==="
                    kubectl apply -f k8s/mysql-pv.yaml
                    kubectl apply -f k8s/mysql-pvc.yaml
                    kubectl apply -f k8s/mysql-deployment.yaml
                    kubectl apply -f k8s/mysql-service.yaml

                    echo ""
                    echo "=== Deploy Spring Boot ==="
                    kubectl apply -f k8s/spring-deployment.yaml
                    kubectl apply -f k8s/spring-service.yaml

                    echo ""
                    echo "=== Waiting for pods ==="
                    kubectl wait --for=condition=ready pod -l app=mysql -n ${NAMESPACE} --timeout=180s || true
                    kubectl wait --for=condition=ready pod -l app=spring-app -n ${NAMESPACE} --timeout=180s || true

                    echo ""
                    echo "=== Deployment status ==="
                    kubectl get pods -n ${NAMESPACE}
                    kubectl get svc -n ${NAMESPACE}
                """
            }
        }
    }

    post {
        success {
            echo '✅ =========================================='
            echo '✅ Pipeline executed successfully!'
            echo '============================================'
            echo "📦 Docker Image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
            echo "☸️ Namespace: ${NAMESPACE}"
            echo ""
            echo "To access your application:"
            echo "1. vagrant ssh"
            echo "2. minikube service spring-service -n devops --url"
            echo ""
            echo "Test endpoint: /department/getAllDepartment"
        }
        failure {
            echo '❌ Pipeline failed. Check logs.'
        }
        always {
            echo '🧹 Final cleanup...'
            sh 'docker system prune -f || true'
        }
    }
}
