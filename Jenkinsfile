pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'oussema17/students-management'
        DOCKER_CREDS = credentials('dockerhub-credentials')
        K8S_NAMESPACE = 'devops'
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
         stage('SonarQube Analysis') {
    steps {
        echo '🔍 Running SonarQube analysis...'
        withSonarQubeEnv('SonarQube') {   // doit correspondre au Name que tu as mis dans Jenkins
            sh '''
              mvn sonar:sonar \
              -Dsonar.projectKey=students-management \
              -Dsonar.projectName=StudentsManagement \
              -Dsonar.java.binaries=target/classes
            '''
        }
    }
}

        stage('Deploy to Kubernetes') {
            steps {
                echo '☸️ Deploying to Kubernetes cluster...'
                script {
                    // Verify namespace exists
                    sh """
                        kubectl get namespace ${K8S_NAMESPACE} || kubectl create namespace ${K8S_NAMESPACE}
                    """
                    
                    // Deploy MySQL (check if files exist first)
                    sh """
                        echo '📊 Deploying MySQL...'
                        if [ -f k8s/mysql-pv.yaml ]; then
                            kubectl apply -f k8s/mysql-pv.yaml
                        fi
                        if [ -f k8s/mysql-pvc.yaml ]; then
                            kubectl apply -f k8s/mysql-pvc.yaml
                        fi
                        kubectl apply -f k8s/mysql-deployment.yaml
                        kubectl apply -f k8s/mysql-service.yaml
                    """
                    
                    // Wait for MySQL
                    sh """
                        echo '⏳ Waiting for MySQL to be ready...'
                        kubectl wait --for=condition=ready pod -l app=mysql -n ${K8S_NAMESPACE} --timeout=300s || true
                    """
                    
                    // Deploy Spring Boot
                    sh """
                        echo '🚀 Deploying Spring Boot Application...'
                        kubectl apply -f k8s/spring-deployment.yaml -n ${K8S_NAMESPACE}
                        
                        # Only apply spring-service if students-service doesn't exist
                        if ! kubectl get svc students-service -n ${K8S_NAMESPACE} &> /dev/null; then
                            if [ -f k8s/spring-service.yaml ]; then
                                kubectl apply -f k8s/spring-service.yaml -n ${K8S_NAMESPACE}
                            fi
                        else
                            echo '✅ Service students-service already exists, skipping spring-service'
                        fi
                    """
                    
                    // Update to latest image
                    sh """
                        echo '🔄 Updating to build ${BUILD_NUMBER}...'
                        kubectl set image deployment/students-management \
                            students-management=${DOCKER_IMAGE}:${BUILD_NUMBER} \
                            -n ${K8S_NAMESPACE}
                    """
                    
                    // Wait for rollout
                    sh """
                        echo '⏳ Waiting for rollout to complete...'
                        kubectl rollout status deployment/students-management -n ${K8S_NAMESPACE} --timeout=5m
                    """
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '🔍 Verifying deployment...'
                script {
                    sh """
                        echo ''
                        echo '═══════════════════════════════════════════════════'
                        echo '✅ Deployment Information:'
                        echo '═══════════════════════════════════════════════════'
                        echo ''
                        echo '📋 Pods Status:'
                        kubectl get pods -n ${K8S_NAMESPACE} -o wide
                        echo ''
                        echo '🔗 Services:'
                        kubectl get svc -n ${K8S_NAMESPACE}
                        echo ''
                        echo '📦 Deployments:'
                        kubectl get deployments -n ${K8S_NAMESPACE}
                        echo '═══════════════════════════════════════════════════'
                    """
                    
                    // Get service URL
                    def serviceUrl = sh(
                        script: "minikube service students-service -n ${K8S_NAMESPACE} --url 2>/dev/null || echo 'http://192.168.49.2:30089'",
                        returnStdout: true
                    ).trim()
                    
                    echo "🌐 Application URL: ${serviceUrl}"
                    
                    // Test application
                    sh """
                        echo ''
                        echo '🏥 Testing application endpoint...'
                        sleep 10
                        curl -f -s '${serviceUrl}/students/getAllStudents' | head -20 || echo '⚠️  Endpoint not ready yet'
                        echo ''
                    """
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo '🧹 Cleaning up Docker credentials...'
                sh 'docker logout'
            }
        }
    }

    post {
        success {
            echo ''
            echo '═══════════════════════════════════════════════════'
            echo '✅ PIPELINE SUCCESSFUL!'
            echo '═══════════════════════════════════════════════════'
            echo ''
            script {
                def serviceUrl = sh(
                    script: "minikube service students-service -n ${K8S_NAMESPACE} --url 2>/dev/null || echo 'http://192.168.49.2:30089'",
                    returnStdout: true
                ).trim()
                
                echo "📦 Docker Image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                echo '✅ Pipeline successful! Artifacts deployed to Nexus and Docker image pushed.'
                echo "☸️  Namespace: ${K8S_NAMESPACE}"
                echo "🌐 Application: ${serviceUrl}"
                echo ""
                echo "📌 Quick Tests:"
                echo "   curl ${serviceUrl}/students/getAllStudents"
                echo "   curl -X POST ${serviceUrl}/students/createStudent -H 'Content-Type: application/json' -d '{\"firstName\":\"Test\",\"lastName\":\"User\",\"email\":\"test@esprit.tn\"}'"
            }
            echo '═══════════════════════════════════════════════════'
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
        }
        failure {
            echo '❌ Pipeline failed!'
            script {
                sh """
                    echo ''
                    echo '📋 Debugging Information:'
                    echo ''
                    echo 'Pods Status:'
                    kubectl get pods -n ${K8S_NAMESPACE} -o wide || true
                    echo ''
                    echo 'Recent Logs:'
                    kubectl logs -n ${K8S_NAMESPACE} -l app=students-management --tail=30 || true
                    echo ''
                    echo 'Events:'
                    kubectl get events -n ${K8S_NAMESPACE} --sort-by='.lastTimestamp' | tail -10 || true
                """
            }
        }
        always {
            echo '🔚 Pipeline execution completed.'
        }
    }
}
