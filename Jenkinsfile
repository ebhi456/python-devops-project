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
                    python -m pip install --upgrade pip
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
                    )
                ]) {
                    sh '''
                        . jenkins-venv/bin/activate

                        DB_HOST=localhost \
                        DB_PORT=5432 \
                        DB_NAME=employee_db \
                        pytest
                    '''
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t employee-api:${BUILD_NUMBER} .
                    docker tag employee-api:${BUILD_NUMBER} employee-api:latest
                '''
            }
        }
        stage('Deploy Docker') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'employee-db-credentials',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        docker stop $(docker ps -q --filter "name=employee-api") || true
                        docker rm $(docker ps -a -q --filter "name=employee-api") || true
                        
                        docker run -d --name employee-api \
                            -p 8000:8000 \
                            -e DB_USER=$DB_USER \
                            -e DB_PASSWORD=$DB_PASSWORD \
                            -e DB_HOST=db \
                            -e DB_PORT=5432 \
                            -e DB_NAME=employee_db \
                            employee-api:${BUILD_NUMBER}
                    '''
                }
            }
        }
        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for the application to start..."
                    # Wait for a few seconds to allow the application to start
                    sleep 10
                    curl -f http://localhost:8000/health || exit 1
                    echo "Health check passed!"
                '''
            }
        }
    }
    post {
        success {
            echo 'CI Pipeline completed successfully!'
        }

        failure {
            echo 'CI Pipeline failed!'
        }

        always {
            echo 'Pipeline execution completed.'
        }
    }
}