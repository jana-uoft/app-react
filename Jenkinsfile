#!groovy

def errorOccured = false // Used to check buildStatus during any stage

def isDeploymentBranch(){
  return CURRENT_BRANCH==PRODUCTION_BRANCH || CURRENT_BRANCH==DEVELOPMENT_BRANCH;
}

def getSuffix() {
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
    CURRENT_BRANCH = env.GIT_BRANCH.getAt((env.GIT_BRANCH.indexOf('/')+1..-1)) // (eg) origin/master: get string after '/'
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
          } catch (e) { if (!errorOccured) { errorOccured = "Failed while installing node packages.\n\n${readFile('commandResult').trim()}\n\n${e.message}"} }
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
          } catch (e) { if (!errorOccured) {errorOccured = "Failed while testing.\n\n${readFile('commandResult').trim()}\n\n${e.message}"} }
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
      when { expression { return !errorOccured && isDeploymentBranch(); } }
      steps {
        script {
          try {
            // Build
            nodejs(nodeJSInstallationName: '10.6.0') {
              sh 'yarn build 2>commandResult'
            }
          } catch (e) { if (!errorOccured) {errorOccured = "Failed while building.\n\n${readFile('commandResult').trim()}\n\n${e.message}"} }
        }
      }
    }
    stage ('Upload Archive') {
      // Skip stage if an error has occured in previous stages
      when { expression { return !errorOccured && isDeploymentBranch(); } }
      steps {
        script {
          try {
            // Create archive
            sh 'mkdir -p ./ARCHIVE 2>commandResult'
            sh 'mv node_modules ARCHIVE/ 2>commandResult'
            sh 'mv build ARCHIVE/ 2>commandResult'
            sh "tar zcf '${SITE_NAME}${getSuffix()}.tar.gz' ./ARCHIVE/* --transform \"s,^,'${SITE_NAME}${getSuffix()}'/,S\" --exclude=${SITE_NAME}${getSuffix()}.tar.gz --overwrite --warning=none 2>commandResult"
            // Upload archive to server
            sh "scp -v -i /var/lib/jenkins/.ssh/id_rsa ${SITE_NAME}${getSuffix()}.tar.gz root@165.227.35.62:/root/ 2>commandResult"
          } catch (e) { if (!errorOccured) {errorOccured = "Failed while uploading archive.\n\n${readFile('commandResult').trim()}\n\n${e.message}"} }
        }
      }
    }
    stage ('Deploy') {
      // Skip stage if an error has occured in previous stages
      when { expression { return !errorOccured && isDeploymentBranch(); } }
      steps {
        script {
          try {
            // Deploy app
            echo "ssh into server and deploy"
          } catch (e) { if (!errorOccured) {errorOccured = "Failed while deploying.\n\n${readFile('commandResult').trim()}\n\n${e.message}"} }
        }
      }
    }
  }
  post {
    always {
      cleanWs() // Recursively clean workspace
      notifySlack(errorOccured) // Send final 'Success/Failed' message based on errorOccured.
    }
  }
}