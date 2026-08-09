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

        stage('Create Docker Network') {
            steps {
                sh '''
                    set -e

                    echo "Creating Docker network..."

                    docker network inspect employee-network >/dev/null 2>&1 || \
                    docker network create employee-network

                    echo "Docker network ready."
                '''
            }
        }

        stage('Start PostgreSQL') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'employee-db-credentials',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "Checking PostgreSQL container..."

                        if docker inspect db >/dev/null 2>&1; then
                            echo "PostgreSQL container already exists."

                            docker start db 2>/dev/null || true

                            docker network connect employee-network db 2>/dev/null || true
                        else
                            echo "Creating PostgreSQL container..."

                            docker run -d \
                                --name db \
                                --network employee-network \
                                --restart unless-stopped \
                                -e POSTGRES_USER="$DB_USER" \
                                -e POSTGRES_PASSWORD="$DB_PASSWORD" \
                                -e POSTGRES_DB="employee_db" \
                                postgres:18
                        fi

                        echo "Waiting for PostgreSQL..."

                        i=1

                        while [ "$i" -le 30 ]; do

                            if docker exec db pg_isready \
                                -U "$DB_USER" \
                                -d employee_db >/dev/null 2>&1; then

                                echo "PostgreSQL is ready!"
                                exit 0
                            fi

                            echo "Waiting for PostgreSQL... Attempt $i/30"

                            sleep 2

                            i=$((i + 1))
                        done

                        echo "PostgreSQL failed to start."

                        docker logs db || true

                        exit 1
                    '''
                }
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

                        export DB_USER="$DB_USER"
                        export DB_PASSWORD="$DB_PASSWORD"
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
                    set -e

                    docker build \
                        -t employee-api:${BUILD_NUMBER} \
                        -t employee-api:latest \
                        .

                    docker images | grep employee-api
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'employee-db-credentials',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "Stopping old employee-api container..."

                        docker stop employee-api 2>/dev/null || true
                        docker rm employee-api 2>/dev/null || true

                        echo "Starting employee-api..."

                        docker run -d \
                            --name employee-api \
                            --network employee-network \
                            --restart unless-stopped \
                            -p 8000:8000 \
                            -e DB_USER="$DB_USER" \
                            -e DB_PASSWORD="$DB_PASSWORD" \
                            -e DB_HOST="db" \
                            -e DB_PORT="5432" \
                            -e DB_NAME="employee_db" \
                            employee-api:${BUILD_NUMBER}

                        echo "Application container started."

                        docker ps
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for application..."

                    i=1

                    while [ "$i" -le 30 ]; do

                        if curl -fs http://localhost:8000/health; then
                            echo ""
                            echo "Application is healthy!"
                            exit 0
                        fi

                        echo "Waiting... Attempt $i/30"

                        sleep 2

                        i=$((i + 1))
                    done

                    echo "Application failed to start."

                    echo "===== Containers ====="
                    docker ps -a

                    echo "===== Application Logs ====="
                    docker logs employee-api || true

                    exit 1
                '''
            }
        }

        stage('Application Verification') {
            steps {
                sh '''
                    set -e

                    echo "Testing /health..."

                    curl -fs http://localhost:8000/health

                    echo ""
                    echo "Testing /employees..."

                    curl -fs http://localhost:8000/employees

                    echo ""
                    echo "Application verification successful!"
                '''
            }
        }
    }

    post {

        success {
            echo 'CI/CD Pipeline completed successfully!'

            sh '''
                echo "===== Running Containers ====="
                docker ps

                echo "===== Docker Network ====="
                docker network inspect employee-network
            '''
        }

        failure {
            echo 'CI/CD Pipeline failed!'

            sh '''
                echo "===== All Containers ====="
                docker ps -a || true

                echo "===== API Logs ====="
                docker logs employee-api 2>/dev/null || true

                echo "===== Database Logs ====="
                docker logs db 2>/dev/null || true
            '''
        }

        always {
            echo 'Pipeline execution completed.'
        }
    }
}