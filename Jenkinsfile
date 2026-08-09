```groovy
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

        stage('Start Application') {
            steps {
                sh '''
                    docker compose down || true
                    docker compose up -d --build
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    . jenkins-venv/bin/activate

                    export DB_USER=$DB_USER
                    export DB_PASSWORD=$DB_PASSWORD
                    export DB_HOST=localhost
                    export DB_PORT=5432
                    export DB_NAME=employee_db

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

