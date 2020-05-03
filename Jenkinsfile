pipeline {
  agent {
    label 'cicd'
  }

  environment {
    def scmVars = checkout scm
    BASE        = 'python36-az'
    IMAGE       = 'image-name'
    REGISTRY    = 'registry-to-push-to'
    PROJECT     = 'project'
  }

  options {
    // Discard old builds
    buildDiscarder(logRotator(numToKeepStr: '5'))
    timeout(time: 30, unit: 'MINUTES')
  }

  stages {
    stage('Pull latest core Python image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'creds-go-here', usernameVariable: 'creds-go-here', passwordVariable: 'creds-go-here')]) {
          sh """
            docker login ${env.REGISTRY} -u ${REGUSER} -p ${REGPASS}
            docker pull ${env.REGISTRY}/${env.BASE}
          """
        }
      }
    }
    stage('Execute unit tests') {
      agent {
        docker {
          image 'image-to-run-tests-on'
          args '-v /opt/jenkins/workspace:/var/jenkins-home/workspace'
          reuseNode true
        }
      }
      steps {
        sh """
          pip3 install -r requirements.txt
          pip3 install .
          python3 -m unittest discover ./tests/unit/
        """
      }
      post {
        failure {
          emailext (
            subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            body: """<p>FAILURE: Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]:<p>
              <p>Unit tests have failed.  Please check the job logs at <a href="${env.BUILD_URL}">.""",
            to: "${env.GIT_COMMITTER_EMAIL}"
          )
        }
      }
    }
    stage('Build image') {
      steps {
        sh """
          echo "Building commit ${env.GIT_COMMIT}"
          docker build --no-cache -t localhost/${env.PROJECT}/${env.IMAGE}:${env.GIT_COMMIT} .
        """
      }
      post {
        failure {
          emailext (
            subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            body: """<p>FAILURE: Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]:<p>
              <p>The Docker image build has failed.  Please check the job logs at <a href="${env.BUILD_URL}">.""",
            to: "${env.GIT_COMMITTER_EMAIL}"
          )
        }
      }
    }
    stage('Scan image') {
      steps {
        scan(registry: "localhost", project: "${env.PROJECT}", image: "${env.IMAGE}", tag: "${env.GIT_COMMIT}")
      }
      post {
        failure {
          emailext (
            subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            body: """<p>FAILURE: Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]:<p>
              <p>The image security scan has failed.  Please check the job logs at <a href="${env.BUILD_URL}">.""",
            to: "william.x.kokolis@gsk.com"
          )
        }
        success {
          emailext (
            subject: "SCAN SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            body: """<p>PASSING BUILD: Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]:<p>
              <p>The image based on ${env.GIT_COMMIT} has PASSED its benchmark compliance scan.  Please keep these logs as a record of the image's compliance.""",
            to: "william.x.kokolis@gsk.com"
          )
        }
      }
    }
    stage('Push tagged release to registries') {
      when { buildingTag() }
      steps {
        withDockerRegistry([credentialsId: 'registry', url: "registry-url"]) {
          sh """
            docker tag localhost/${env.PROJECT}/${env.IMAGE}:${env.GIT_COMMIT} ${env.REGISTRY}/${env.IMAGE}:${env.TAG_NAME}
            docker push ${env.REGISTRY}/${env.IMAGE}:${env.TAG_NAME}
          """
        }
      }
      post {
        failure {
          emailext (
            subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            body: """<p>FAILURE: Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]:<p>
              <p>Container image did not push to the registry correctly.  Please check the job logs at <a href="${env.BUILD_URL}">.  Ensure that your credentials are correct and that the registry is reachable.""",
            to: "william.x.kokolis@gsk.com"
          )
        }
      }
    }
    stage('Push Development image to Registry') {
      when { not { buildingTag() } }
      steps {
        withDockerRegistry([credentialsId: 'registry-id', url: "registry-url"]) {
          sh """
            docker tag localhost/${env.PROJECT}/${env.IMAGE}:${env.GIT_COMMIT} ${env.REGISTRY}/${env.IMAGE}:${env.GIT_COMMIT}
            docker push ${env.REGISTRY}/${env.IMAGE}:${env.GIT_COMMIT}
          """
        }
      }
      post {
        failure {
          emailext (
            subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            body: """<p>FAILURE: Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]:<p>
              <p>Container image did not push to the registry correctly.  Please check the job logs at <a href="${env.BUILD_URL}">.  Ensure that your credentials are correct and that the registry is reachable.""",
            to: "william.x.kokolis@gsk.com"
          )
        }
      }
    }
  }

  post {
    cleanup {
      sh "docker rmi ${env.REGISTRY}/${env.IMAGE}:${env.TAG_NAME}   || exit 0"
      sh "docker rmi ${env.REGISTRY}/${env.IMAGE}:${env.GIT_COMMIT} || exit 0"
      sh "docker rmi localhost/${env.PROJECT}/${env.IMAGE}:${env.GIT_COMMIT}       || exit 0"

      cleanWs()
    }
  }
}
