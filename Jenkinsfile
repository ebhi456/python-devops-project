pipeline {
    agent any

    environment {
        AWS_REGION    = 'us-east-1'
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
                    python3 -m venv jenkins-venv
                    . jenkins-venv/bin/activate

                    pip install --upgrade pip
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
                        echo "======================================"
                        echo "Starting PostgreSQL..."
                        echo "======================================"

                        docker compose up -d db

                        echo "Waiting for PostgreSQL..."

                        sleep 10

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
                withCredentials([
                    string(
                        credentialsId: 'AWS_ACCOUNT_ID',
                        variable: 'AWS_ACCOUNT_ID'
                    )
                ]) {
                    sh '''
                        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                        echo "======================================"
                        echo "Logging in to Amazon ECR..."
                        echo "======================================"

                        aws ecr get-login-password \
                            --region ${AWS_REGION} | \
                        docker login \
                            --username AWS \
                            --password-stdin ${ECR_REGISTRY}

                        echo "ECR login successful."
                    '''
                }
            }
        }

        stage('Tag Image') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'AWS_ACCOUNT_ID',
                        variable: 'AWS_ACCOUNT_ID'
                    )
                ]) {
                    sh '''
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
        }

        stage('Push Image to ECR') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'AWS_ACCOUNT_ID',
                        variable: 'AWS_ACCOUNT_ID'
                    )
                ]) {
                    sh '''
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
        }

        stage('Verify ECR') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'AWS_ACCOUNT_ID',
                        variable: 'AWS_ACCOUNT_ID'
                    )
                ]) {
                    sh '''
                        echo "======================================"
                        echo "Checking ECR repository..."
                        echo "======================================"

                        aws ecr describe-images \
                            --repository-name ${ECR_REPOSITORY} \
                            --region ${AWS_REGION} \
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
                # Stop/remove containers created by this Compose project.
                # PostgreSQL volumes are NOT removed.
                docker compose down --remove-orphans || true

                # Remove dangling/unused Docker images.
                docker image prune -f || true

                # Remove unused Docker build cache.
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