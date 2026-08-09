pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    python3 -m venv jenkins-venv
                    . jenkins-venv/bin/activate

                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                withCredentials([
                    string(credentialsId: 'DB_USER', variable: 'DB_USER'),
                    string(credentialsId: 'DB_PASSWORD', variable: 'DB_PASSWORD'),
                    string(credentialsId: 'DB_HOST', variable: 'DB_HOST'),
                    string(credentialsId: 'DB_PORT', variable: 'DB_PORT'),
                    string(credentialsId: 'DB_NAME', variable: 'DB_NAME')
                ]) {
                    sh '''
                        echo "DB_USER is set: ${DB_USER:+YES}"
                        echo "DB_HOST is set: ${DB_HOST:+YES}"
                        echo "DB_PORT is set: ${DB_PORT:+YES}"
                        echo "DB_NAME is set: ${DB_NAME:+YES}"
                        echo "DB_PASSWORD is set: ${DB_PASSWORD:+YES}"

                        docker compose down || true

                        docker compose up -d --build
                    '''
                }
            }
        }

        stage('Verify Containers') {
            steps {
                sh '''
                    docker compose ps
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    . jenkins-venv/bin/activate

                    pytest
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for application..."
                    sleep 10

                    curl -f http://localhost:8000/health
                '''
            }
        }
    }

    post {
        success {
            echo 'CI/CD Pipeline completed successfully!'
        }

        failure {
            echo 'CI/CD Pipeline failed!'
        }
    }
}