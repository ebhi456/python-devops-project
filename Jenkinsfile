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
        
        stage('Start Application') {
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
                            nohup uvicorn app.main:app \
                                --host 0.0.0.0 \
                                --port 8000 \
                                > app.log 2>&1 &
                        echo $! > app.pid
                        
                        sleep 2
                        
                        cat app.log
                    '''
                }
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

                        sleep 2
                    done

                    echo "Application failed to start."
                    echo "===== Application logs ====="
                    cat app.log || true

                    exit 1
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