#!groovy

def errorOccured = false // Used to check buildStatus during any stage

pipeline {
  // construct global env variables
  environment {
    PRODUCTION_BRANCH = 'master' // Source branch used for production
    DEVELOPMENT_BRANCH = 'dev' // Source branch used for development
    CURRENT_BRANCH = env.GIT_BRANCH.getAt((env.GIT_BRANCH.indexOf('/')+1..-1)) // (eg) origin/master: get string after '/'
    SLACK_CHANNEL = '#builds' // Slack channel to post build notifications
    COMMIT_MESSAGE = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim() // Auto generated
    COMMIT_AUTHOR = sh(returnStdout: true, script: 'git --no-pager show -s --format=%an').trim() // Auto generated
  }
  agent any
  stages {
    stage('Start') {
      steps {
        notifySlack() // Send 'Build Started' notification
      }
    }
    stage ('Install Packages') {
      steps {
        script {
          try {
            // Install required node packages
            nodejs(nodeJSInstallationName: '10.6.0') {
              sh 'yarn 2>commandResult'
            }
          } catch (e) { if (!errorOccured) { errorOccured = "Failed while installing node packages.\n\n${readFile('commandResult').trim()}"} }
        }
      }
    }
    stage ('Test') {
      // Skip stage if an error has occured in previous stages
      when { expression { return !errorOccured; } }
      steps {
        // Test
        script {
          try {
            nodejs(nodeJSInstallationName: '10.6.0') {
              sh 'yarn test 2>commandResult'
            }
          } catch (e) { if (!errorOccured) {errorOccured = "Failed while testing.\n\n${readFile('commandResult').trim()}"} }
        }
      }
      post {
        always {
          // Publish junit test results
          junit testResults: 'junit.xml', allowEmptyResults: true
          // Publish clover.xml and html(if generated) test coverge report
          step([
            $class: 'CloverPublisher',
            cloverReportDir: 'coverage',
            cloverReportFileName: 'clover.xml',
            failingTarget: [methodCoverage: 75, conditionalCoverage: 75, statementCoverage: 75]
          ])
          script {
            if (!errorOccured && currentBuild.resultIsWorseOrEqualTo('UNSTABLE')) {
              errorOccured = "Insufficent Test Coverage."
            }
          }
        }
      }
    }
    stage ('Build') {
      // Skip stage if an error has occured in previous stages
      when { expression { return !errorOccured; } }
      steps {
        script {
          try {
            // Build
            nodejs(nodeJSInstallationName: '10.6.0') {
              sh 'yarn build 2>commandResult'
            }
          } catch (e) { if (!errorOccured) {errorOccured = "Failed while building.\n\n${readFile('commandResult').trim()}"} }
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
      // Send final 'SUCCESS/FAILURE' notification based on errorOccured.
      notifySlack(errorOccured)
      cleanWs() // Recursively clean workspace
    }
  }
}