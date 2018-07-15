#!groovy

pipeline {
    // construct global env values
    environment {
        ERROR_OCCURED = false  // used to verify buildStatus during every stage
        SLACK_CHANNEL = '#builds'
        COMMIT_MESSAGE = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
        COMMIT_AUTHOR = sh(returnStdout: true, script: 'git --no-pager show -s --format=%an').trim()
        PRODUCTION_BRANCH = 'master'
        DEVELOPMENT_BRANCH = 'dev'
    }
    agent any
    stages {
        stage('Start') {
            steps {
                // send 'BUILD STARTED' notification
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
                    } catch (e) { if (!ERROR_OCCURED) {ERROR_OCCURED = "Failing Tests Detected"} }
                }
            }
            post {
                always {
                    // publish junit test results
                    junit testResults: 'junit.xml', allowEmptyResults: true
                    // publish clover.xml and html(if generated) test coverge report
                    step([
                        $class: 'CloverPublisher',
                        cloverReportDir: 'coverage',
                        cloverReportFileName: 'clover.xml',
                        failingTarget: [methodCoverage: 75, conditionalCoverage: 75, statementCoverage: 75]
                    ])
                    script {
                        if (!ERROR_OCCURED && currentBuild.resultIsWorseOrEqualTo('UNSTABLE')) {
                            ERROR_OCCURED = "Insufficent Test Coverage"
                        }
                    }
                }
            }
        }
        stage ('Build') {
            when {
                expression {
                    return !ERROR_OCCURED;
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
            notifySlack()
            cleanWs()
        }
    }
}