#!groovy

pipeline {
    agent any
    stages {
        stage('Start') {
            steps {
                // send build started notifications
                notifySlack 'STARTED'
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
                nodejs(nodeJSInstallationName: '10.6.0') {
                    sh 'yarn test'
                }
            }
            post {
                success {
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
        success {
            notifySlack 'SUCCESS'
        }

        failure {
            notifySlack 'FAILED'
        }
    }
}