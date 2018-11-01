pipeline {
  agent any

  environment {
        GIT_NAME = "demo.docker.ploneconf"
    }

  stages {

    stage('Code') {
      steps {
        parallel(

          "ZPT Lint": {
            node(label: 'docker') {
              checkout scm
              sh '''docker run -i --rm -v $(pwd):/code eeacms/zptlint'''
            }
          },

          "JS Lint": {
            node(label: 'docker') {
              checkout scm
              sh '''docker run -i --rm -v $(pwd):/code eeacms/jslint4java'''
            }
          },

          "PyFlakes": {
            node(label: 'docker') {
              checkout scm
              sh '''docker run -i --rm -v $(pwd):/code eeacms/pyflakes'''
            }
          },

          "i18n": {
            node(label: 'docker') {
              checkout scm
              sh '''docker run -i --rm -v $(pwd):/code eeacms/i18ndude'''
            }
          }
        )
      }
    }

    stage('Build & Test') {
      steps {
        node(label: 'docker') {
          script {
            try {
              checkout scm
              sh '''docker build -t ${BUILD_TAG,,} .'''
              sh '''docker run -i --name ${BUILD_TAG,,} ${BUILD_TAG,,} bin/test'''
            } finally {
              sh '''docker rm -v ${BUILD_TAG,,}'''
              sh '''docker rmi ${BUILD_TAG,,}'''
            }
          }
        }
      }
    }


    stage('Prepare release') {
      when {
        not {
          environment name: 'CHANGE_ID', value: ''
        }
        environment name: 'CHANGE_TARGET', value: 'master'
      }
      steps {
        node(label: 'docker') {
          script {
            if ( env.CHANGE_BRANCH != "develop" &&  !( env.CHANGE_BRANCH.startsWith("hotfix")) ) {
                error "Pipeline aborted due to PR not made from develop or hotfix branch"
            }
           withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GITHUB_TOKEN')]) {
            sh '''docker run -i --rm -e GIT_CHANGE_BRANCH="$CHANGE_BRANCH" -e GIT_CHANGE_AUTHOR="$CHANGE_AUTHOR" -e GIT_CHANGE_TITLE="$CHANGE_TITLE" -e GIT_TOKEN="$GITHUB_TOKEN" -e GIT_BRANCH="$BRANCH_NAME" -e GIT_CHANGE_ID="$CHANGE_ID" -e GIT_ORG="avoinea" -e GIT_NAME="$GIT_NAME" -e GIT_VERSIONFILE="version.txt" eeacms/gitflow'''
           }
          }
        }
      }
    }

    stage('Release') {
      when {
        allOf {
          environment name: 'CHANGE_ID', value: ''
          branch 'master'
        }
      }
      steps {
        node(label: 'docker') {
          withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GITHUB_TOKEN')]) {
            sh '''docker run -i --rm -e GIT_BRANCH="$BRANCH_NAME" -e GIT_NAME="$GIT_NAME" -e GIT_ORG="$GIT_ORG" -e GIT_TOKEN="$GITHUB_TOKEN" eeacms/gitflow'''
          }
        }
      }
    }
  }

  post {
    changed {
      script {
        def url = "${env.BUILD_URL}/display/redirect"
        def status = currentBuild.currentResult
        def subject = "${status}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
        def summary = "${subject} (${url})"
        def details = """<h1>${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${status}</h1>
                         <p>Check console output at <a href="${url}">${env.JOB_BASE_NAME} - #${env.BUILD_NUMBER}</a></p>
                      """

        def color = '#FFFF00'
        if (status == 'SUCCESS') {
          color = '#00FF00'
        } else if (status == 'FAILURE') {
          color = '#FF0000'
        }
        emailext (subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS', body: details)
      }
    }
  }
}
