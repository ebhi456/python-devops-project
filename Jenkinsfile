pipeline {
    agent any

    environment {
        AWS_REGION     = 'us-east-1'
        ECR_REPOSITORY = 'python-devops-project-app'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "Installing Python dependencies..."
                    echo "======================================"

                    python3 -m venv jenkins-venv
                    . jenkins-venv/bin/activate

                    python -m pip install --upgrade pip
                    pip install -r requirements.txt

                    echo "Dependencies installed successfully."
                '''
            }
        }

        stage('Start Database') {
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
                        set -e

                        echo "======================================"
                        echo "Starting PostgreSQL..."
                        echo "======================================"

                        docker compose up -d db

                        echo "Waiting for PostgreSQL..."

                        sleep 10

                        echo "PostgreSQL status:"
                        docker compose ps
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
                    ),
                    string(
                        credentialsId: 'DB_NAME',
                        variable: 'DB_NAME'
                    )
                ]) {
                    sh '''
                        set -e

                        . jenkins-venv/bin/activate

                        export DB_HOST=localhost
                        export DB_PORT=5432

                        echo "======================================"
                        echo "Running Tests..."
                        echo "======================================"

                        pytest

                        echo "Tests completed successfully."
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "Building Docker Image..."
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "======================================"

                    docker build \
                        -t employee-api:${BUILD_NUMBER} \
                        .

                    echo "Docker image created successfully."

                    docker images | grep employee-api || true
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'aws-access-key',
                        variable: 'AWS_ACCESS_KEY_ID'
                    ),
                    string(
                        credentialsId: 'aws-secret-key',
                        variable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "======================================"
                        echo "Logging in to Amazon ECR..."
                        echo "======================================"

                        export AWS_DEFAULT_REGION="${AWS_REGION}"

                        AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                            --query Account \
                            --output text)

                        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                        echo "AWS Account: ${AWS_ACCOUNT_ID}"
                        echo "ECR Registry: ${ECR_REGISTRY}"

                        aws ecr get-login-password \
                            --region "${AWS_REGION}" | \
                        docker login \
                            --username AWS \
                            --password-stdin "${ECR_REGISTRY}"

                        echo "ECR login successful."
                    '''
                }
            }
        }

        stage('Tag Image') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'aws-access-key',
                        variable: 'AWS_ACCESS_KEY_ID'
                    ),
                    string(
                        credentialsId: 'aws-secret-key',
                        variable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        set -e

                        export AWS_DEFAULT_REGION="${AWS_REGION}"

                        AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                            --query Account \
                            --output text)

                        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                        echo "======================================"
                        echo "Tagging Docker Images..."
                        echo "======================================"

                        docker tag \
                            employee-api:${BUILD_NUMBER} \
                            ${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}

                        docker tag \
                            employee-api:${BUILD_NUMBER} \
                            ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest

                        echo "Image tagging completed."

                        echo "Versioned image:"
                        echo "${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"

                        echo "Latest image:"
                        echo "${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                    '''
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'aws-access-key',
                        variable: 'AWS_ACCESS_KEY_ID'
                    ),
                    string(
                        credentialsId: 'aws-secret-key',
                        variable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        set -e

                        export AWS_DEFAULT_REGION="${AWS_REGION}"

                        AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                            --query Account \
                            --output text)

                        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                        echo "======================================"
                        echo "Pushing Versioned Image..."
                        echo "======================================"

                        docker push \
                            ${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}

                        echo "======================================"
                        echo "Pushing Latest Image..."
                        echo "======================================"

                        docker push \
                            ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest

                        echo "======================================"
                        echo "ECR PUSH SUCCESSFUL"
                        echo "======================================"
                    '''
                }
            }
        }

        stage('Verify ECR') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'aws-access-key',
                        variable: 'AWS_ACCESS_KEY_ID'
                    ),
                    string(
                        credentialsId: 'aws-secret-key',
                        variable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        set -e

                        export AWS_DEFAULT_REGION="${AWS_REGION}"

                        echo "======================================"
                        echo "Checking ECR Repository..."
                        echo "======================================"

                        aws ecr describe-images \
                            --repository-name "${ECR_REPOSITORY}" \
                            --region "${AWS_REGION}" \
                            --query 'imageDetails[*].imageTags' \
                            --output table

                        echo "ECR verification completed."
                    '''
                }
            }
        }

        stage('Application Health Check') {
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
                        set -e

                        echo "======================================"
                        echo "Starting Employee API..."
                        echo "======================================"

                        docker compose up -d --force-recreate api

                        echo "Waiting for API..."

                        sleep 10

                        echo "======================================"
                        echo "Running Containers"
                        echo "======================================"

                        docker compose ps

                        echo "======================================"
                        echo "Running API Health Check..."
                        echo "======================================"

                        curl -f http://localhost:8000/health

                        echo ""
                        echo "======================================"
                        echo "Employee API is healthy."
                        echo "======================================"
                    '''
                }
            }
        }
    }

    post {

        success {
            echo '======================================'
            echo 'PIPELINE SUCCESSFUL'
            echo '======================================'
            echo 'Employee API image pushed to ECR.'
            echo "Build Number: ${BUILD_NUMBER}"
            echo '======================================'
        }

        failure {
            echo '======================================'
            echo 'PIPELINE FAILED'
            echo '======================================'

            sh '''
                echo "======================================"
                echo "Docker Compose Status"
                echo "======================================"

                docker compose ps || true

                echo "======================================"
                echo "Recent Docker Compose Logs"
                echo "======================================"

                docker compose logs --tail=50 || true

                echo "======================================"
                echo "Employee API Docker Images"
                echo "======================================"

                docker images | grep employee-api || true
            '''

            echo '======================================'
        }

        always {
            echo '======================================'
            echo 'Cleaning up Docker resources...'
            echo '======================================'

            sh '''
                echo "Stopping Docker Compose services..."

                docker compose down --remove-orphans || true

                echo "Removing dangling Docker images..."

                docker image prune -f || true

                echo "Removing unused Docker build cache..."

                docker builder prune -f || true

                echo "Docker cleanup completed."

                echo "======================================"
                echo "Remaining Docker Disk Usage"
                echo "======================================"

                docker system df || true
            '''

            echo '======================================'
            echo 'Pipeline execution completed.'
            echo '======================================'
        }
    }
}