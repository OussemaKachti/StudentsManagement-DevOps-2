pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'oussema17/students-management'
        DOCKER_CREDS = credentials('dockerhub-credentials')
        K8S_NAMESPACE = 'devops'
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

        stage('Deploy to Kubernetes') {
            steps {
                echo '☸️ Deploying to Kubernetes cluster...'
                script {
                    // Check if namespace exists
                    sh """
                        kubectl get namespace ${K8S_NAMESPACE} || kubectl create namespace ${K8S_NAMESPACE}
                    """
                    
                    // Deploy MySQL components
                    sh """
                        echo '📊 Deploying MySQL components...'
                        kubectl apply -f k8s/mysql-pv.yaml
                        kubectl apply -f k8s/mysql-pvc.yaml
                        kubectl apply -f k8s/mysql-deployment.yaml
                        kubectl apply -f k8s/mysql-service.yaml
                    """
                    
                    // Wait for MySQL to be ready
                    sh """
                        echo '⏳ Waiting for MySQL to be ready...'
                        kubectl wait --for=condition=ready pod -l app=mysql -n ${K8S_NAMESPACE} --timeout=300s || true
                    """
                    
                    // Deploy Spring Boot Application
                    sh """
                        echo '🚀 Deploying Spring Boot Application...'
                        kubectl apply -f k8s/spring-configmap.yaml -n ${K8S_NAMESPACE}
                        kubectl apply -f k8s/spring-secret.yaml -n ${K8S_NAMESPACE}
                        kubectl apply -f k8s/spring-deployment.yaml -n ${K8S_NAMESPACE}
                        kubectl apply -f k8s/spring-service.yaml -n ${K8S_NAMESPACE}
                    """
                    
                    // Update image to use the latest build
                    sh """
                        kubectl set image deployment/students-management \
                            students-management=${DOCKER_IMAGE}:${BUILD_NUMBER} \
                            -n ${K8S_NAMESPACE}
                    """
                    
                    // Wait for rollout to complete
                    sh """
                        echo '⏳ Waiting for deployment to complete...'
                        kubectl rollout status deployment/students-management -n ${K8S_NAMESPACE} --timeout=5m
                    """
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '🔍 Verifying deployment...'
                script {
                    // Display deployment info
                    sh """
                        echo '✅ Deployment Information:'
                        echo ''
                        echo '📋 Pods:'
                        kubectl get pods -n ${K8S_NAMESPACE}
                        echo ''
                        echo '🔗 Services:'
                        kubectl get svc -n ${K8S_NAMESPACE}
                        echo ''
                    """
                    
                    // Get service URL
                    def serviceUrl = sh(
                        script: "minikube service students-service -n ${K8S_NAMESPACE} --url 2>/dev/null || echo 'http://192.168.49.2:30089'",
                        returnStdout: true
                    ).trim()
                    
                    echo "🌐 Application URL: ${serviceUrl}"
                    
                    // Test application endpoint
                    sh """
                        echo '🏥 Testing application endpoints...'
                        sleep 15
                        curl -f ${serviceUrl}/students/getAllStudents || echo '⚠️  Warning: Application not ready yet'
                    """
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
            echo '✅ Pipeline successful!'
            echo ''
            echo '═══════════════════════════════════════════════════'
            echo '📦 Docker Image: ${DOCKER_IMAGE}:${BUILD_NUMBER}'
            echo '☸️  Kubernetes Namespace: ${K8S_NAMESPACE}'
            script {
                def serviceUrl = sh(
                    script: "minikube service students-service -n ${K8S_NAMESPACE} --url 2>/dev/null || echo 'http://192.168.49.2:30089'",
                    returnStdout: true
                ).trim()
                echo "🌐 Application URL: ${serviceUrl}"
                echo ''
                echo '📌 Test your application:'
                echo "   curl ${serviceUrl}/students/getAllStudents"
            }
            echo '═══════════════════════════════════════════════════'
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
        }
        failure {
            echo '❌ Pipeline failed! Check logs.'
            script {
                sh """
                    echo ''
                    echo '📋 Kubernetes Status:'
                    kubectl get pods -n ${K8S_NAMESPACE} || true
                    echo ''
                    echo '📋 Recent Application Logs:'
                    kubectl logs -n ${K8S_NAMESPACE} -l app=students-management --tail=50 || true
                """
            }
        }
        always {
            echo '🔚 Pipeline execution completed.'
        }
    }
}