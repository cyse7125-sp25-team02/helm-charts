pipeline {
    agent any

    environment {
        GITHUB_TOKEN = credentials('github-token')
    }

    stages {
        stage('Semantic Git Release') {
            steps {
                script {
                    sh 'npm install'
                    sh 'npx semantic-release'
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
