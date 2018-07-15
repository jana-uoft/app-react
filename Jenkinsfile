#!groovy

def errorOccured = false // used to verify buildStatus during every stage

pipeline {
    // construct global env values
    environment {
        SLACK_CHANNEL = '#builds'
        COMMIT_MESSAGE = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
        COMMIT_AUTHOR = sh(returnStdout: true, script: 'git --no-pager show -s --format=%an').trim()

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
                    } catch (e) { if (!errorOccured) {errorOccured = e.message} }
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
                        healthyTarget: [methodCoverage: 80, conditionalCoverage: 80, statementCoverage: 80], // optional, default is: method=70, conditional=80, statement=80
                    ])
                    echo currentBuild.currentResult
                }
            }
        }
        stage ('Build') {
            when {
                expression {
                    return errorOccured==false && currentBuild.currentResult=='SUCCESS';
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