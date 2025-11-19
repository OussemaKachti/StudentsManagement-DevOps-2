pipeline {
    agent any
    
    tools {
        maven 'M2_HOME'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Récupération du code source depuis Git...'
                git branch: 'main',
                    url: 'https://github.com/OussemaKachti/StudentsManagement-DevOps.git'
            }
        }
        
        stage('Build') {
            steps {
                echo 'Compilation du projet...'
                sh 'mvn clean compile'
            }
        }
        
        stage('Package') {
            steps {
                echo 'Création du package JAR...'
                sh 'mvn package -DskipTests'
            }
        }
    }
    
    post {
        success {
            echo '✅ Build réussi ! Le projet a été compilé et packagé avec succès.'
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
        failure {
            echo '❌ Build échoué ! Consultez les logs pour plus de détails.'
        }
        always {
            echo 'Nettoyage de l\'espace de travail...'
            cleanWs()
        }
    }
}
