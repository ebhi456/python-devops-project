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

                    python3 -m venv jenkins-venv
                    . jenkins-venv/bin/activate

                    python -m pip install --upgrade pip
                    pip install -r requirements.txt
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
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "Building Python DevOps Project Docker image..."
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
                sh '''
                    set -e

                    echo "======================================"
                    echo "Logging in to Amazon ECR..."
                    echo "======================================"

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

        stage('Tag Image') {
            steps {
                sh '''
                    set -e

                    AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                        --query Account \
                        --output text)

                    ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                    echo "======================================"
                    echo "Tagging Docker images..."
                    echo "======================================"

                    docker tag \
                        employee-api:${BUILD_NUMBER} \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}

                    docker tag \
                        employee-api:${BUILD_NUMBER} \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest

                    echo "Image tagging completed."

                    docker images | grep employee-api || true
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh '''
                    set -e

                    AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                        --query Account \
                        --output text)

                    ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                    echo "======================================"
                    echo "Pushing versioned image..."
                    echo "======================================"

                    docker push \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}

                    echo "======================================"
                    echo "Pushing latest image..."
                    echo "======================================"

                    docker push \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest

                    echo "======================================"
                    echo "ECR PUSH SUCCESSFUL"
                    echo "======================================"
                '''
            }
        }

        stage('Verify ECR') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "Checking ECR repository..."
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

                        echo "Checking running containers..."

                        docker compose ps

                        echo "======================================"
                        echo "Running API health check..."
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
                echo "Docker Compose status:"
                docker compose ps || true

                echo "Recent Docker Compose logs:"
                docker compose logs --tail=50 || true

                echo "Employee API Docker images:"
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

                echo "Remaining Docker disk usage:"

                docker system df || true
            '''

            echo '======================================'
            echo 'Pipeline execution completed.'
            echo '======================================'
        }
    }
}