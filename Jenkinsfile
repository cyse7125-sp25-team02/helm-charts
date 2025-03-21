pipeline {
    agent any

    // Environment variables for the pipeline
    environment {
        GITHUB_TOKEN = credentials('github-token') // Store your GitHub token in Jenkins credentials
        CHART_NAME = 'api-server' // From your Chart.yaml
        CHART_PATH = '.' // Root of the chart
    }

    stages {
        // Stage 1: Run checks on Pull Request
        stage('PR Checks') {
            when {
                expression { env.CHANGE_ID != null } // Runs only for pull requests
            }
            steps {
                script {
                    // Install Helm if not already installed
                    sh 'curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'

                    // Run helm lint
                    sh "helm lint ${CHART_PATH}"

                    // Run helm template
                    sh "helm template ${CHART_NAME} ${CHART_PATH}"
                }
            }
            post {
                failure {
                    // Notify GitHub of the failure
                    script {
                        currentBuild.result = 'FAILURE'
                        // Update PR status (requires GitHub plugin in Jenkins)
                        step([
                            $class: 'GitHubCommitStatusSetter',
                            reposSource: [$class: "ManuallyEnteredRepositorySource", url: "https://github.com/<your-org>/<your-repo>"],
                            contextSource: [$class: "ManuallyEnteredCommitContextSource", context: "ci/helm-checks"],
                            errorHandlers: [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
                            statusResultSource: [$class: "ConditionalStatusResultSource", results: [[$class: "AnyBuildResult", message: "Helm checks failed", state: "FAILURE"]]]
                        ])
                    }
                }
                success {
                    script {
                        // Update PR status to success
                        step([
                            $class: 'GitHubCommitStatusSetter',
                            reposSource: [$class: "ManuallyEnteredRepositorySource", url: "https://github.com/<your-org>/<your-repo>"],
                            contextSource: [$class: "ManuallyEnteredCommitContextSource", context: "ci/helm-checks"],
                            statusResultSource: [$class: "ConditionalStatusResultSource", results: [[$class: "AnyBuildResult", message: "Helm checks passed", state: "SUCCESS"]]]
                        ])
                    }
                }
            }
        }

        // Stage 2: Build and Release on Merge to Master
        stage('Build and Release') {
            when {
                branch 'master' // Runs only on the master branch
            }
            steps {
                script {
                    // Install Helm
                    sh 'curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'

                    // Install Node.js and semantic-release
                    sh '''
                        curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
                        apt-get install -y nodejs
                        npm install -g semantic-release @semantic-release/git @semantic-release/changelog @semantic-release/exec
                    '''

                    // Run semantic-release to determine the new version
                    sh '''
                        npx semantic-release --no-ci
                    '''

                    // Package the Helm chart (creates a .tgz file)
                    sh "helm package ${CHART_PATH} --dependency-update"

                    // Create a GitHub release (semantic-release handles this if configured)
                    // The packaged chart will be attached to the release automatically by semantic-release
                }
            }
        }
    }

    post {
        always {
            // Clean up workspace
            cleanWs()
        }
    }
}