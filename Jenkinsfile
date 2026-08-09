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

        stage('Run Tests') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'employee-db-credentials',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASSWORD'
                    ),
                    string(
                        credentialsId: 'DB_NAME',
                        variable: 'DB_NAME'
                    )
                ]) {
                    sh '''
                        . jenkins-venv/bin/activate

                        export DB_HOST=localhost
                        export DB_PORT=5432

                        pytest
                    '''
                }
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'employee-db-credentials',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASSWORD'
                    ),
                    string(
                        credentialsId: 'DB_NAME',
                        variable: 'DB_NAME'
                    )
                ]) {
                    sh '''
                        echo "Stopping existing Compose deployment..."

                        docker compose down --remove-orphans || true

                        echo "Starting application and database..."

                        docker compose up -d --build

                        echo "Deployment status:"

                        docker compose ps
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for application..."
                    sleep 10

                    echo "Checking health endpoint..."

                    curl -f http://localhost:8000/health

                    echo ""
                    echo "Application is healthy!"
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

            sh '''
                docker compose ps || true
                docker compose logs --tail=50 || true
            '''
        }

        always {
            echo 'Pipeline execution completed.'
        }
    }
}