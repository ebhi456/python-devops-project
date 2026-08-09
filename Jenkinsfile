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