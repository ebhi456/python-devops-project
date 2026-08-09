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

                        export DB_HOST=localhost
                        export DB_PORT=5432
                        export DB_NAME=employee_db

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

        stage('Docker run') {
            steps {
                sh '''
                    echo "Stopping any existing containers..."

                    docker stop employee-api || true
                    docker rm employee-api || true

                    echo "starting the application using docker container.
                    docker run -d --name employee-api -p 8000:8000 \
                        -e DB_USER=ebinejar_user \
                        -e DB_PASSWORD=Naaga@2506 \
                        -e DB_HOST=db \
                        -e DB_PORT=5432 \
                        -e DB_NAME=employee_db \
                        employee-api:${BUILD_NUMBER} > app.log 2>&1

                    echo "Application started in the background. Logs are being written to app.log"

                    docker ps
                '''
            }
        }
        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for the application to start..."

                    for i in {1..30}; do
                        if curl -fs http://localhost:8000/health; then
                            echo "Application is healthy!"
                            exit 0
                        fi
                        echo "Waiting for the application to become healthy... (Attempt $i/30)"
                        sleep 2
                    done

                    echo "Application failed to start."
                    echo "docker container logs:"
                    docker ps -a

                    echo "===== Application logs ====="
                    docker logs employee-api || true

                    exit 1
                '''
            }
        }
        stage('application verification') {
            steps {
                sh '''
                    echo "Verifying the application..."

                    response=$(curl -s http://localhost:8000/health)
                    echo "Health check response: $response"

                    if [[ "$response" == *"healthy"* ]]; then
                        echo "Application is running and healthy."
                    else
                        echo "Application is not healthy. Response: $response"
                        exit 1
                    fi
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
            sh 'cat app.log || true'
        }

        always {
            echo 'Pipeline execution completed.'
        }
    }
}