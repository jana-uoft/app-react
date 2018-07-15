#!groovy

def errorOccured = false // Used to check buildStatus during any stage

def isDeploymentBranch(current_branch, production_branch, development_branch){
  return current_branch==production_branch || current_branch==development_branch;
}

def getSuffix(current_branch, development_branch) {
  return current_branch==development_branch ? '-dev' : "";
}

pipeline {
  // construct global env variables
  environment {
    PRODUCTION_BRANCH = 'master' // Source branch used for production
    DEVELOPMENT_BRANCH = 'dev' // Source branch used for development
    CURRENT_BRANCH = env.GIT_BRANCH.getAt((env.GIT_BRANCH.indexOf('/')+1..-1)) // (eg) origin/master: get string after '/'
    // DEPLOYMENT_BRANCH = isDeploymentBranch() // Auto generated
    // SITE_NAME = 'testing' // Name for archive.
    // SUFFIX = getSuffix() // Auto generated
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
      when { expression { return !errorOccured && DEPLOYMENT_BRANCH; } }
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
    }
    stage ('Upload Archive') {
      // Skip stage if an error has occured in previous stages
      when { expression { return !errorOccured && DEPLOYMENT_BRANCH; } }
      steps {
        script {
          try {
            // Create archive
            sh 'mkdir -p ./ARCHIVE 2>commandResult'
            sh 'mv node_modules ARCHIVE/ 2>commandResult'
            sh 'mv build ARCHIVE/ 2>commandResult'
            sh "tar zcf ${SITE_NAME}${SUFFIX}.tar.gz ./ARCHIVE/* --transform \"s,^,${SITE_NAME}${SUFFIX}/,S\" --exclude=${SITE_NAME}${SUFFIX}.tar.gz --overwrite --warning=none 2>commandResult"
          } catch (e) { if (!errorOccured) {errorOccured = "Failed while creating archive.\n\n${readFile('commandResult').trim()}"} }
        }
        script {
          try {
            // Upload archive to server
            echo "scp upload to server ${SITE_NAME}${SUFFIX}.tar.gz"
          } catch (e) { if (!errorOccured) {errorOccured = "Failed while creating archive.\n\n${readFile('commandResult').trim()}"} }
        }
      }
    }
    stage ('Deploy') {
      // Skip stage if an error has occured in previous stages
      when { expression { return !errorOccured && DEPLOYMENT_BRANCH; } }
      steps {
        script {
          try {
            // Deploy app
            echo "ssh into server and deploy"
          } catch (e) { if (!errorOccured) {errorOccured = "Failed while creating archive.\n\n${readFile('commandResult').trim()}"} }
        }
      }
    }
  }
  post {
    always {
      notifySlack(errorOccured) // Send final 'Success/Failed' message based on errorOccured.
      cleanWs() // Recursively clean workspace
    }
  }
}