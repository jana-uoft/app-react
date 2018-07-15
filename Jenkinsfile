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
                        failingTarget: [methodCoverage: 70, conditionalCoverage: 70, statementCoverage: 70]
                    ])
                    script {
                        if (currentBuild.resultIsWorseOrEqualTo('UNSTABLE')) {
                            errorOccured = "Insufficent Test Coverage\n Minimum required: methods: 75%, conditionals: 75%, statements: 75%"
                        }
                    }
                }
            }
        }
        stage ('Build') {
            when {
                expression {
                    return !errorOccured;
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