#!groovy

@Library('slack-notify') _

def errorMessage = "" // Used to construct error message in any stage

def isDeploymentBranch(){
  def currentBranch = env.GIT_BRANCH.getAt((env.GIT_BRANCH.indexOf('/')+1..-1))
  return currentBranch==PRODUCTION_BRANCH || currentBranch==DEVELOPMENT_BRANCH;
}

def getSuffix() {
  def currentBranch = env.GIT_BRANCH.getAt((env.GIT_BRANCH.indexOf('/')+1..-1))
  return CURRENT_BRANCH==DEVELOPMENT_BRANCH ? '-dev' : '';
}

pipeline {
  // construct global env variables
  environment {
    SITE_NAME = 'testing' // Name will be used for archive file (with suffix '-dev' if DEVELOPMENT_BRANCH)
    CHEF_RECIPE_NAME = 'app-testing' // Name of the chef recipe to trigger in Deploy stage
    PRODUCTION_BRANCH = 'master' // Source branch used for production
    DEVELOPMENT_BRANCH = 'dev' // Source branch used for development
    SLACK_CHANNEL = '#builds' // Slack channel to send build notifications
  }
  agent {
    dockerfile true
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  stages {
    stage ('Install Packages') {
      steps {
        notifySlack status: 'STARTED', channel: SLACK_CHANNEL
        script {
          try {
            // Install required node packages
            sh 'yarn 2>commandResult'
          } catch (e) {
            if (!errorMessage) {
              errorMessage = "Failed while installing node packages.\n\n${readFile('commandResult').trim()}\n\n${e.message}"
            }
            currentBuild.currentResult = 'FAILURE'
          }
        }
      }
    }
    stage ('Test') {
      // Skip stage if an error has occured in previous stages
      when { expression { return !errorMessage; } }
      steps {
        // Test
        script {
          try {
            nodejs(nodeJSInstallationName: '10.6.0') {
              sh 'yarn test 2>commandResult'
            }
          } catch (e) {
            if (!errorMessage) {
              errorMessage = "Failed while testing.\n\n${readFile('commandResult').trim()}\n\n${e.message}"
            }
            currentBuild.currentResult = 'UNSTABLE'
          }
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
            if (!errorMessage && currentBuild.resultIsWorseOrEqualTo('UNSTABLE')) {
              errorMessage = "Insufficent Test Coverage."
              currentBuild.currentResult = 'UNSTABLE'
            }
          }
        }
      }
    }
    stage ('Build') {
      // Skip stage if an error has occured in previous stages or if not isDeploymentBranch
      when { expression { return !errorMessage && isDeploymentBranch(); } }
      steps {
        script {
          try {
            // Build
            nodejs(nodeJSInstallationName: '10.6.0') {
              sh 'yarn build 2>commandResult'
            }
          } catch (e) {
            if (!errorMessage) {
              errorMessage = "Failed while building.\n\n${readFile('commandResult').trim()}\n\n${e.message}"
            }
            currentBuild.currentResult = 'FAILURE'
          }
        }
      }
    }
    stage ('Upload Archive') {
      // Skip stage if an error has occured in previous stages or if not isDeploymentBranch
      when { expression { return !errorMessage && isDeploymentBranch(); } }
      steps {
        script {
          try {
            // Create archive
            sh 'mkdir -p ./ARCHIVE 2>commandResult'
            sh 'mv node_modules/ ./ARCHIVE/ 2>commandResult'
            sh 'mv build/* ARCHIVE/ 2>commandResult'
            // sh "cd ARCHIVE && tar zcf ${SITE_NAME}${getSuffix()}.tar.gz * --transform \"s,^,${SITE_NAME}${getSuffix()}/,S\" --exclude=${SITE_NAME}${getSuffix()}.tar.gz --overwrite --warning=none && cd .. 2>commandResult"
            // Upload archive to server
            // sh "scp ARCHIVE/${SITE_NAME}${getSuffix()}.tar.gz root@jana19.org:/root/ 2>commandResult"
          } catch (e) {
            if (!errorMessage) {
              errorMessage = "Failed while uploading archive.\n\n${readFile('commandResult').trim()}\n\n${e.message}"
            }
            currentBuild.currentResult = 'FAILURE'
          }
        }
      }
    }
    stage ('Deploy') {
      // Skip stage if an error has occured in previous stages or if not isDeploymentBranch
      when { expression { return !errorMessage && isDeploymentBranch(); } }
      steps {
        script {
          try {
            // Deploy app
            // sh "rsync -azP ARCHIVE/ root@jana19.org:/var/www/jana19.org/"
          } catch (e) {
            if (!errorMessage) {
              errorMessage = "Failed while deploying.\n\n${readFile('commandResult').trim()}\n\n${e.message}"
            }
            currentBuild.currentResult = 'FAILURE'
          }
        }
      }
    }
  }
  post {
    always {
      notifySlack message: errorMessage, channel: SLACK_CHANNEL
      cleanWs() // Recursively clean workspace
    }
  }
}
