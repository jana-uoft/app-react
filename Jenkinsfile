#!groovy

def errorOccured = false

pipeline {
    // construct global env values used by notifySlack()
    environment {
        CHANNEL = '#builds'
        COMMIT_MESSAGE = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
        AUTHOR = sh(returnStdout: true, script: 'git --no-pager show -s --format=%an').trim()
    }
    agent any
    stages {
        stage('Start') {
            steps {
                // send build started notifications
                notifySlack()
            }
        }
        stage ('Install Packages') {
            steps {
                // install required packages
                nodejs(nodeJSInstallationName: '10.6.0') {
                    sh 'yarn'
                }
            }
        }
        stage ('Test') {
            steps {
                // test
                script {
                    try {
                        nodejs(nodeJSInstallationName: '10.6.0') {
                            sh 'yarn test'
                        }
                    } catch (e) { if (!errorOccured) {errorOccured = e.message} }
                }
            }
            post {
                always {
                    // publish junit test results
                    junit testResults: 'junit.xml', allowEmptyResults: true
                    // publish html coverge report
                    publishHTML target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: 'coverage/lcov-report',
                        reportFiles: 'index.html',
                        reportName: 'Test Coverage Report'
                    ]
                }
            }
        }
        stage ('Build') {
            when {
                expression {
                    return errorOccured == false;
                }
            }
            steps {
                // build
                nodejs(nodeJSInstallationName: '10.6.0') {
                    sh 'yarn build'
                }
            }
            post {
                success {
                    // Archive the built artifacts
                    echo "Archive and upload to brickyard"
                }
            }
        }
    }
    post {
        always {
            notifySlack(errorOccured)
            cleanWs()
        }
    }
}